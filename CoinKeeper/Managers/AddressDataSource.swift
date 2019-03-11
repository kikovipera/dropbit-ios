//
//  AddressDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PromiseKit

protocol AddressDataSourceType: AnyObject {

  func receiveAddress(at index: Int) -> CNBMetaAddress
  func changeAddress(at index: Int) -> CNBMetaAddress

  func nextChangeAddress(in context: NSManagedObjectContext) -> CNBMetaAddress

  func checkAddressExists(for address: String, in context: NSManagedObjectContext) -> CNBAddressResult?

  /**
   Returns an array of addresses that are neither used nor currently on the server, matching the count parameter.
   - param forServerPool: Should be true when getting new addresses to add to the server pool.
   */
  func nextAvailableReceiveAddresses(number: Int,
                                     forServerPool: Bool,
                                     indicesToSkip: Set<Int>,
                                     in context: NSManagedObjectContext) -> [CNBMetaAddress]
  func nextAvailableReceiveAddress(forServerPool: Bool,
                                   indicesToSkip: Set<Int>,
                                   in context: NSManagedObjectContext) -> CNBMetaAddress?

}

/**
 Responsible for providing addresses and indexes according to various constraints for the given wallet.
 */
class AddressDataSource: AddressDataSourceType {

  private let wallet: CNBHDWallet
  private let persistenceManager: PersistenceManagerType

  init(wallet: CNBHDWallet, persistenceManager: PersistenceManagerType) {
    self.wallet = wallet
    self.persistenceManager = persistenceManager
  }

  func receiveAddress(at index: Int) -> CNBMetaAddress {
    return wallet.receiveAddress(for: UInt(index))
  }

  func changeAddress(at index: Int) -> CNBMetaAddress {
    return wallet.changeAddress(for: UInt(index))
  }

  func nextChangeAddress(in context: NSManagedObjectContext) -> CNBMetaAddress {
    let lastIndex = persistenceManager.lastChangeAddressIndex(in: context) ?? -1
    let nextChangeIndex = lastIndex + 1
    return changeAddress(at: nextChangeIndex)
  }

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
    return persistenceManager.lastReceiveAddressIndex(in: context)
  }

  func lastChangeAddress(in context: NSManagedObjectContext) -> Int? {
    return persistenceManager.lastChangeAddressIndex(in: context)
  }

  func checkAddressExists(for address: String, in context: NSManagedObjectContext) -> CNBAddressResult? {
    let lastRecIdx = lastReceiveIndex(in: context) ?? -1
    let lastChgIdx = lastChangeAddress(in: context) ?? -1
    let lastIndex = max(lastRecIdx, lastChgIdx)
    let offset = 20
    return wallet.check(forAddress: address, upTo: lastIndex + offset)
  }

  func nextAvailableReceiveAddress(forServerPool: Bool, indicesToSkip: Set<Int> = [], in context: NSManagedObjectContext) -> CNBMetaAddress? {
    return nextAvailableReceiveAddresses(number: 1, forServerPool: forServerPool, indicesToSkip: indicesToSkip, in: context).first
  }

  func nextAvailableReceiveAddresses(number: Int,
                                     forServerPool: Bool,
                                     indicesToSkip: Set<Int> = [],
                                     in context: NSManagedObjectContext) -> [CNBMetaAddress] {
    guard number > 0 else { return [] }

    // A set of indices that have been deemed unusable by internal functions.
    var localIndicesToSkip = indicesToSkip

    if forServerPool {
      localIndicesToSkip = persistenceManager.serverPoolAddresses(in: context).compactMap { $0.derivativePath?.index }.asSet()
    }

    let pendingDropBitAddresses: [String] = persistenceManager.addressesProvidedForReceivedPendingDropBits(in: context)

    let startIndex = (lastReceiveIndex(in: context) ?? -1) + 1
    let endIndex = startIndex + 20
    let futureAddressIndices = (startIndex..<endIndex).map { Int($0) }
    let remainingGapIndices = persistenceManager.userDefaultsManager.receiveAddressIndexGaps
      .subtracting(localIndicesToSkip).asArray()
      .filter { $0 < startIndex }
      .sorted()

    let usableIndices = remainingGapIndices + futureAddressIndices

    let usableMetaAddresses = usableIndices
      .filter { !localIndicesToSkip.contains($0) }
      .map { self.receiveAddress(at: $0) }
      .filter { !pendingDropBitAddresses.contains($0.address) }

    let targetIndex = number - 1
    let returnableMetaAddresses = usableMetaAddresses.prefix(through: targetIndex).map { $0 }

    return returnableMetaAddresses
  }

  func nextAvailableReceiveIndex(indicesToSkip: Set<Int>, in context: NSManagedObjectContext) -> Int {
    let next = nextAvailableReceiveAddress(forServerPool: false, indicesToSkip: indicesToSkip, in: context)?.derivationPath.index ?? UInt(0)
    return Int(next)
  }

}