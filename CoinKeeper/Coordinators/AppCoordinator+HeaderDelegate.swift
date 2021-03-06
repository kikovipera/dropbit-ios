//
//  AppCoordinator+HeaderDelegate.swift
//  CoinKeeper
//
//  Created by Ben Winters on 9/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: HeaderDelegate {

  func createHeaders(for bodyData: Data?) -> DefaultHeaders? {
    let timeStamp = CKDateFormatter.rfc3339.string(from: Date())
    let platform = "ios"
    let version = Global.version.value

    let dataToSign = bodyData ?? timeStamp.data(using: .utf8)
    let sig = dataToSign.flatMap { self.walletManager?.signatureSigning(data: $0) }

    let deviceId = self.persistenceManager.findOrCreateDeviceId()
    let buildEnvironment = ApplicationBuildEnvironment.current()
    var headers = DefaultHeaders(timeStamp: timeStamp,
                                 devicePlatform: platform,
                                 appVersion: version,
                                 signature: sig,
                                 walletId: nil,
                                 userId: nil,
                                 deviceId: deviceId,
                                 buildEnvironment: buildEnvironment)

    let context = self.persistenceManager.databaseManager.createBackgroundContext()
    context.performAndWait {
      headers.walletId = self.persistenceManager.walletId(in: context)
      headers.userId = self.persistenceManager.userId(in: context)
    }

    return headers
  }

}
