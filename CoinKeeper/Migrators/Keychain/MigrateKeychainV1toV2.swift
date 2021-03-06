//
//  MigrateKeychainV1toV2.swift
//  DropBit
//
//  Created by Ben Winters on 1/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MigrateKeychainV1toV2: Migratable {

  let persistenceManager: PersistenceManagerType

  func isMigrated() -> Bool {
    return persistenceManager.keychainMigrationFlag(for: .v1tov2)
  }

  func migrate() {
    let allKeys = CKKeychain.Key.allCases

    for key in allKeys {
      guard let existingValue = persistenceManager.keychainManager.retrieveValue(for: key) else { continue }

      // store nil before changing accessibility to avoid errors
      persistenceManager.keychainManager.store(anyValue: nil, key: key)

      // re-store the value, which will store it with the current accessibility level
      persistenceManager.keychainManager.store(anyValue: existingValue, key: key)
    }

    // set migrated flag
    persistenceManager.setKeychainMigrationFlag(migrated: true, for: .v1tov2)
  }

}
