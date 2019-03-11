//
//  CoinNinjaUrlFactory.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct CoinNinjaUrlFactory {

  static private let tooltipBreadcrumb: String = "tooltips/"

  enum CoinNinjaURL {
    case bitcoin
    case seedWords
    case bitcoinSMS
    case whyBitcoin
    case dropBit
    case transaction(id: String)
    case address(id: String)
    case faqs
    case contactUs
    case termsOfUse
    case privacyPolicy
    case detailsTooltip
    case myAddressesTooltip
    case sharedMemosTooltip
    case regularTransactionTooltip
    case dropbitTransactionTooltip

    var domain: String {
      switch self {
      case .bitcoin, .seedWords, .whyBitcoin, .transaction, .address:
        return "https://www.coinninja.com/"
      case .dropBit,
           .faqs,
           .contactUs,
           .termsOfUse,
           .bitcoinSMS,
           .privacyPolicy,
           .detailsTooltip,
           .myAddressesTooltip,
           .sharedMemosTooltip,
           .regularTransactionTooltip,
           .dropbitTransactionTooltip:
        return "https://dropbit.app/"
      }
    }

    var path: String {
      switch self {
      case .bitcoin:
        return "learnbitcoin"
      case .seedWords:
        return "seedwords"
      case .bitcoinSMS:
        return "dropbit"
      case .whyBitcoin:
        return "whybitcoin"
      case .dropBit:
        return "dropbit"
      case .transaction(let id):
        return "tx/\(id)"
      case .address(let id):
        return "address/\(id)"
      case .faqs:
        return "faq"
      case .contactUs:
        return "faq#contact"
      case .termsOfUse:
        return "termsofuse"
      case .privacyPolicy:
        return "privacypolicy"
      case .detailsTooltip:
        return "\(CoinNinjaUrlFactory.tooltipBreadcrumb)transactiondetails"
      case .myAddressesTooltip:
        return "\(CoinNinjaUrlFactory.tooltipBreadcrumb)myaddresses"
      case .sharedMemosTooltip:
        return "\(CoinNinjaUrlFactory.tooltipBreadcrumb)sharedmemos"
      case .regularTransactionTooltip:
        return "\(CoinNinjaUrlFactory.tooltipBreadcrumb)regulartransaction"
      case .dropbitTransactionTooltip:
        return "\(CoinNinjaUrlFactory.tooltipBreadcrumb)dropbitransaction"
      }
    }
  }

  static func buildUrl(for url: CoinNinjaURL? = nil) -> URL? {
    guard let url = url else { return nil }
    return URL(string: url.domain + url.path)
  }
}