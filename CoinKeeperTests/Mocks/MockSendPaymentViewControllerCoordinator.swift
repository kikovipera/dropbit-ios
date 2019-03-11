//
//  MockSendPaymentViewControllerCoordinator.swift
//  DropBitTests
//
//  Created by Ben Winters on 11/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
@testable import DropBit
import enum Result.Result

class MockSendPaymentViewControllerCoordinator: SendPaymentViewControllerCoordinator {
  func deviceCountryCode() -> Int? {
    return nil
  }

  func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String) {
  }

  var networkManager: NetworkManagerType
  var balanceUpdateManager: BalanceUpdateManager

  init(balanceUpdateManager: BalanceUpdateManager = BalanceUpdateManager(),
       networkManager: NetworkManagerType) {
    self.balanceUpdateManager = balanceUpdateManager
    self.networkManager = networkManager
  }

  func balanceNetPending() -> NSDecimalNumber {
    return .zero
  }

  func spendableBalanceNetPending() -> NSDecimalNumber {
    return .zero
  }

  func latestExchangeRates(responseHandler: (ExchangeRates) -> Void) {

  }

  func latestFees(responseHandler: (Fees) -> Void) {

  }

  func latestFees() -> Promise<Fees> {
    return Promise.value([:])
  }

  var didTapScan = false
  func viewControllerDidPressScan(_ viewController: UIViewController, btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
    didTapScan = true
  }

  var didTapContacts = false
  func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate) {
    didTapContacts = true
  }

  func viewController(
    _ viewController: UIViewController,
    checkingCachedAddressesFor phoneNumberHash: String,
    completion: @escaping (Result<[WalletAddressesQueryResponse], UserProviderError>) -> Void) {

  }

  func viewControllerDidRequestVerificationCheck(_ viewController: UIViewController, completion: @escaping (() -> Void)) {

  }

  func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel) {

  }

  func viewControllerShouldInitiallyAllowMemoSharing(_ viewController: SendPaymentViewController) -> Bool {
    return true
  }

  var didTapClose = false
  func viewControllerDidSelectClose(_ viewController: UIViewController) {
    didTapClose = true
  }

  func viewControllerDidSendPayment(
    _ viewController: UIViewController,
    btcAmount: NSDecimalNumber,
    requiredFeeRate: Double?,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    rates: ExchangeRates,
    sharedPayload: SharedPayloadDTO) {

  }

  func viewControllerDidBeginAddressNegotiation(
    _ viewController: UIViewController,
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    contact: ContactType,
    memo: String?,
    rates: ExchangeRates,
    memoIsShared: Bool,
    sharedPayload: SharedPayloadDTO) {

  }

  func sendPaymentViewControllerDidLoad(_ viewController: UIViewController) {

  }

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?) {

  }

  var didSelectMemoButton = false
  func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void) {
    didSelectMemoButton = true
  }

  var didTapPaste = false
  func viewControllerDidSelectPaste(_ viewController: UIViewController) {
    didTapPaste = true
  }

  func openURL(_ url: URL, completionHandler completion: (() -> Void)?) { }

}