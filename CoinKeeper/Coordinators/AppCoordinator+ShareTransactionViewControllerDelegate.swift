//
//  AppCoordinator+ShareTransactionViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 4/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import os.log
import UIKit

extension AppCoordinator: ShareTransactionViewControllerDelegate {

  func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController) {
    viewController.dismiss(animated: true) {
      var defaultTweetText = ""
      let bgContext = self.persistenceManager.createBackgroundContext()
      bgContext.performAndWait {
        let latestTx = self.persistenceManager.databaseManager.latestTransaction(in: bgContext)
        defaultTweetText = self.tweetText(withMemo: latestTx?.memo)
      }

      var comps = URLComponents()
      comps.scheme = "twitter"
      comps.host = "post"
      comps.queryItems = [URLQueryItem(name: "message", value: defaultTweetText)]
      if let url = comps.url {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else {
        let logger = OSLog(subsystem: "com.coinninja.appCoordinator", category: "ShareTransaction")
        os_log("%@: Failed to create Twitter URL from components", log: logger, type: .error, #function)
      }
    }
  }

  private func tweetText(withMemo memo: String?) -> String {
    let randomInt = Int.random(in: 0...1)
    if let memoText = memo?.lowercasingFirstLetter() {
      if randomInt == 0 {
        return "I just used #Bitcoin for \(memoText) via @dropbitapp"
      } else {
        return "Today I used #Bitcoin for \(memoText) via @dropbitapp"
      }
    } else {
      if randomInt == 0 {
        return "I just used #Bitcoin instead of fiat via @dropbitapp"
      } else {
        return "I just sent #Bitcoin using @dropbitapp and wow was that easy!"
      }
    }
  }

}
