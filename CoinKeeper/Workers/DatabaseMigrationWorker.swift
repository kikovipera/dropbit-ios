//
//  DatabaseMigrationWorker.swift
//  DropBit
//
//  Created by BJ Miller on 12/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

protocol Migratable {
  func isMigrated() -> Bool
  func migrate()
}

enum DatabaseMigrationVersion: String {
  case v1tov2
  case v4Grooming
}

class DatabaseMigrationWorker: AbstractMigrationWorker {

  let context: NSManagedObjectContext

  init(migrators: [Migratable], in context: NSManagedObjectContext) {
    self.context = context
    super.init(migrators: migrators)
  }

  override func perform() {
    context.performAndWait {
      super.perform()
    }
  }
}
