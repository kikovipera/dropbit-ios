//
//  ContactCacheDataWorker.swift
//  DropBit
//
//  Created by Ben Winters on 2/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import os.log
import Contacts
import PhoneNumberKit
import PromiseKit

protocol ContactCacheDataWorkerType: AnyObject {
  func refreshStatuses() -> Promise<Void>
  func reloadSystemContactsIfNeeded(force: Bool, completion: ((Error?) -> Void)?)
}

struct CachedPhoneNumberDependencies {
  let kit: PhoneNumberKit
  let hasher: HashingManager
  let salt: Data
  let formatter: CNContactFormatter
  let deviceCountryCode: Int
}

class ContactCacheDataWorker: ContactCacheDataWorkerType {

  let contactCacheManager: ContactCacheManagerType
  let permissionManager: PermissionManagerType
  let userRequester: UserRequestable
  let contactStore: CNContactStore

  /// A delegate that provides the current verified country code of the device
  weak var countryCodeProvider: DeviceCountryCodeProvider?

  let logger = OSLog(subsystem: "com.coinninja.coinkeeper.contactcache", category: "data_worker")

  let phoneNumberKit = PhoneNumberKit()
  let hashingManager = HashingManager()

  init(contactCacheManager: ContactCacheManagerType,
       permissionManager: PermissionManagerType,
       userRequester: UserRequestable,
       contactStore: CNContactStore,
       countryCodeProvider: DeviceCountryCodeProvider) {
    self.contactCacheManager = contactCacheManager
    self.permissionManager = permissionManager
    self.userRequester = userRequester
    self.contactStore = contactStore
    self.countryCodeProvider = countryCodeProvider
  }

  func refreshStatuses() -> Promise<Void> {
    let bgContext = contactCacheManager.createChildBackgroundContext()

    return self.getMetadata(in: bgContext)
      .then(in: bgContext) { self.fetchAndPersistStatuses(fromMetadata: $0, in: bgContext) }
      .done(in: bgContext) {
        try bgContext.save()
        try bgContext.parent?.performThrowingAndWait {
          try bgContext.parent?.save()
        }
    }
  }

  enum CacheAction {
    case none, fullReload, selectiveUpdate
  }

  func reloadSystemContactsIfNeeded(force: Bool, completion: ((Error?) -> Void)?) {
    let bgContext = contactCacheManager.createChildBackgroundContext()
    bgContext.perform {
      self.neededCacheAction(force: force, in: bgContext)
        .then(in: bgContext) { self.updateCache(withAction: $0, in: bgContext) }
        .done(in: bgContext) {
          let changeDesc = bgContext.changesDescription()
          os_log("Contact cache changes: %@", log: self.logger, type: .debug, changeDesc)

          try bgContext.saveRecursively()

          DispatchQueue.main.async {
            completion?(nil)
          }
        }
        .catch { error in
          completion?(error)
      }
    }
  }

  private func updateCache(withAction action: CacheAction, in context: NSManagedObjectContext) -> Promise<Void> {
    switch action {
    case .fullReload:
      return self.reloadSystemContacts(in: context)

    case .selectiveUpdate:
      return self.getCNContacts()
        .get { contacts in
          try self.selectivelyUpdateCache(with: contacts, in: context)
        }.asVoid()

    case .none:
      return Promise.value(())
    }
  }

  /// Compare contents of system contacts with local cache to see if the cache should be reloaded
  private func neededCacheAction(force: Bool, in context: NSManagedObjectContext) -> Promise<CacheAction> {
    guard self.permissionManager.permissionStatus(for: .contacts) == .authorized else {
        return Promise.value(.none)
    }

    if force {
      os_log("Contact cache will force full reload", log: self.logger, type: .debug)
      return Promise.value(.fullReload)
    }

    do {
      let phoneNumberCount = try self.contactCacheManager.phoneNumberCount(in: context)
      os_log("Contact cache has %d phone numbers", log: self.logger, type: .debug, phoneNumberCount)
      if phoneNumberCount == 0 {
        return Promise.value(.fullReload)
      } else {
        return Promise.value(.selectiveUpdate)
      }
    } catch {
      return Promise(error: error)
    }
  }

  private func selectivelyUpdateCache(with contacts: [CNContact], in context: NSManagedObjectContext) throws {
    try context.performThrowingAndWait {
      let formatter = CNContactFormatter()
      let managedContacts = try self.contactCacheManager.allCachedContacts(in: context)
      let hashableManagedContacts = Set(managedContacts.map { HashableContact(ccmContact: $0) })
      let hashableSystemContacts = Set(contacts.map { HashableContact(cnContact: $0, formatter: formatter)})

      let hashableContactsToDelete: Set<HashableContact> = hashableManagedContacts.subtracting(hashableSystemContacts)
      let hashableContactsToCreate: Set<HashableContact> = hashableSystemContacts.subtracting(hashableManagedContacts)

      let idsToDelete = hashableContactsToDelete.map { $0.identifier }
      let managedContactsToDelete: [CCMContact] = managedContacts.filter { idsToDelete.contains($0.cnContactIdentifier) }
      managedContactsToDelete.forEach { context.delete($0) } // cascades to phone numbers

      let idsToCreate = hashableContactsToCreate.map { $0.identifier }
      let systemContactsToCreate = contacts.filter { idsToCreate.contains($0.identifier) }
      try self.persistContacts(systemContactsToCreate, in: context)
    }
  }

  private func reloadSystemContacts(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.getCNContacts()
      .get { contacts in
        try context.performThrowingAndWait {
          try self.contactCacheManager.deleteSystemContactData(in: context)
          try self.persistContacts(contacts, in: context)
        }
      }.asVoid()
  }

  /// Fetches all contacts using enumerateContacts.
  /// Not using store.unifiedContacts() because it can return different identifiers each time due to the unification process.
  private func getCNContacts() -> Promise<[CNContact]> {
    return Promise { seal in
      let fullNameKeyDescriptor = CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
      guard let keysToFetch = [fullNameKeyDescriptor, CNContactPhoneNumbersKey] as? [CNKeyDescriptor] else {
        seal.reject(CKPersistenceError.failedToFetch("Could not cast as [CNKeyDescriptor]"))
        return
      }

      do {
        var results: [CNContact] = []
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
          results.append(contact)
        }
        let filteredResults = results.filter { $0.phoneNumbers.isNotEmpty }
        seal.fulfill(filteredResults)
      } catch {
        seal.reject(error)
      }
    }
  }

  private func fetchAndPersistStatuses(fromMetadata metadataList: [CCMValidatedMetadata],
                                       in context: NSManagedObjectContext) -> Promise<Void> {

    let phoneNumberHashes = metadataList.map { $0.hashedGlobalNumber }

    return self.batchedPhoneNumbers(from: phoneNumberHashes)
      .then { self.reduceResults(from: $0) }
      .done(in: context) { responseDict in

        for metadata in metadataList {
          if let responseStatus = responseDict[metadata.hashedGlobalNumber],
            let status = PhoneNumberVerificationStatus.case(forString: responseStatus) {
            metadata.cachedPhoneNumbers.forEach { $0.setStatusIfDifferent(status) }
          } else {
            metadata.cachedPhoneNumbers.forEach { $0.setStatusIfDifferent(.notVerified) }
          }
        }
    }
  }

  private func getMetadata(in context: NSManagedObjectContext) -> Promise<[CCMValidatedMetadata]> {
    return Promise { seal in
      var results: [CCMValidatedMetadata] = []
      try context.performThrowingAndWait {
        results = try contactCacheManager.allValidatedMetadata(in: context)
      }

      seal.fulfill(results)
    }
  }

  private func batchedPhoneNumbers(from phoneNumberHashes: [String],
                                   batchLimit: Int = 100) -> Promise<[StringDictResponse]> {
    let batched = phoneNumberHashes.chunked(by: batchLimit)
    let batchedPhoneNumberPromises = batched.map { self.userRequester.queryUsers(phoneNumberHashes: $0) }
    return when(fulfilled: batchedPhoneNumberPromises)
  }

  private func reduceResults(from responses: [StringDictResponse]) -> Promise<StringDictResponse> {
    return Promise { seal in
      var aggregatePhoneHashDict: [String: String] = [:]
      responses.forEach { aggregatePhoneHashDict.merge($0, uniquingKeysWith: { (_, new) -> String in new }) }
      seal.fulfill(aggregatePhoneHashDict)
    }
  }

  private func persistContacts(_ contacts: [CNContact], in context: NSManagedObjectContext) throws {
    let salt = try hashingManager.salt()
    let countryCode = self.countryCodeProvider?.deviceCountryCode() ?? 1

    let dependencies = CachedPhoneNumberDependencies(
      kit: self.phoneNumberKit,
      hasher: self.hashingManager,
      salt: salt,
      formatter: CNContactFormatter(),
      deviceCountryCode: countryCode
    )

    try self.contactCacheManager.persistContacts(contacts, inputs: dependencies, in: context)
  }

}
