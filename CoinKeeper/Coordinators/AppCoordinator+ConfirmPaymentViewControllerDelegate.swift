//
//  AppCoordinator+ConfirmPaymentViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit
import Result
import CoreData
import PromiseKit
import os.log

extension AppCoordinator: ConfirmPaymentViewControllerDelegate {
  func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController) {
    analyticsManager.track(event: .confirmScreenLoaded, with: nil)
  }

  func viewControllerDidConfirmInvite(_ viewController: UIViewController, outgoingInvitationDTO: OutgoingInvitationDTO) {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "confirm_invite")
    biometricsAuthenticationManager.resetPolicy()
    let pinEntryViewController = PinEntryViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: pinEntryViewController)
    pinEntryViewController.mode = .inviteVerification(completion: { [weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success:
        guard outgoingInvitationDTO.fee > 0 else {
          os_log("DropBit invitation fee is zero", log: logger, type: .error)
          strongSelf.handleFailure(error: TransactionDataError.insufficientFee)
          return
        }

        let receiverNumber = outgoingInvitationDTO.contact.globalPhoneNumber

        guard let senderNumber = strongSelf.persistenceManager.verifiedPhoneNumber() else {
          os_log("Missing sender phone number", log: logger, type: .debug)
          strongSelf.handleFailure(error: CKPersistenceError.missingValue(key: "phoneNumber"))
          return
        }

        let inviteBody = RequestAddressBody(amount: outgoingInvitationDTO.btcPair,
                                            receiverNumber: receiverNumber,
                                            senderNumber: senderNumber,
                                            requestId: UUID().uuidString.lowercased())
        strongSelf.handleSuccessfulInviteVerification(with: inviteBody, outgoingInvitationDTO: outgoingInvitationDTO)
      case .failure(let error):
        strongSelf.handleFailure(error: error)
      }
    })
    pinEntryViewController.modalPresentationStyle = .overFullScreen
    navigationController.topViewController()?.present(pinEntryViewController, animated: true, completion: nil)
  }

  func viewControllerDidConfirmPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
    ) {
    biometricsAuthenticationManager.resetPolicy()
    let pinEntryViewController = PinEntryViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: pinEntryViewController)
    let converter = CurrencyConverter(rates: rates,
                                      fromAmount: NSDecimalNumber(integerAmount: outgoingTransactionData.amount, currency: .BTC),
                                      fromCurrency: .BTC,
                                      toCurrency: .USD)
    let amountInfo = SharedPayloadAmountInfo(converter: converter)
    var outgoingTxDataWithAmount = outgoingTransactionData
    outgoingTxDataWithAmount.sharedPayloadDTO?.amountInfo = amountInfo

    let usdThreshold = 100_00
    let shouldDisableBiometrics = amountInfo.fiatAmount > usdThreshold

    pinEntryViewController.mode = .paymentVerification(amountDisablesBiometrics: shouldDisableBiometrics, completion: { [weak self] result in
      guard let strongSelf = self else { return }
      self?.analyticsManager.track(event: .preBroadcast, with: nil)
      switch result {
      case .success:
        strongSelf.handleSuccessfulPaymentVerification(
          with: transactionData,
          outgoingTransactionData: outgoingTxDataWithAmount)

      case .failure(let error):
        strongSelf.handleFailure(error: error)
      }
    })
    pinEntryViewController.modalPresentationStyle = .overFullScreen
    navigationController.topViewController()?.present(pinEntryViewController, animated: true, completion: nil)
  }

  func viewControllerDidRetryPayment() {
    analyticsManager.track(event: .retryFailedPayment, with: nil)
  }

  private func handleSuccessfulInviteVerification(with inviteBody: RequestAddressBody, outgoingInvitationDTO: OutgoingInvitationDTO) {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "invite_success")

    // guard against fee at 0 again, to really ensure that it is not zero before creating the network request
    guard outgoingInvitationDTO.fee > 0 else {
      os_log("DropBit invitation fee is zero", log: logger, type: .error)
      handleFailure(error: TransactionDataError.insufficientFee)
      return
    }
    let bgContext = persistenceManager.createBackgroundContext()
    let successFailViewController = SuccessFailViewController.makeFromStoryboard()
    successFailViewController.modalPresentationStyle = .overFullScreen
    assignCoordinationDelegate(to: successFailViewController)
    persistenceManager.persistUnacknowledgedInvitation(in: bgContext,
                                                       with: outgoingInvitationDTO.btcPair,
                                                       contact: outgoingInvitationDTO.contact,
                                                       fee: outgoingInvitationDTO.fee,
                                                       acknowledgementId: inviteBody.requestId)

    bgContext.performAndWait {
      do {
        try bgContext.save()
      } catch {
        os_log("failed to save context in %@.\n%@", log: logger, type: .error, #function, error.localizedDescription)
      }
    }
    successFailViewController.retryCompletion = { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.networkManager.createAddressRequest(body: inviteBody)
        .done(in: bgContext) { response in

          bgContext.performAndWait {
            strongSelf.handleSuccessfulInvite(outgoingInvitationDTO: outgoingInvitationDTO, response: response, in: bgContext)
            do {
              try bgContext.save()
              strongSelf.set(mode: .success, for: successFailViewController)
            } catch {
              os_log("failed to save context in %@.\n%@", log: logger, type: .error, #function, error.localizedDescription)
              strongSelf.set(mode: .failure, for: successFailViewController)
              strongSelf.handleFailureInvite(error: TransactionDataError.insufficientFee)
            }
          }
        }.catch(on: .main) { error in
          // In the edge case where we don't receive a server response due to a network failure, expected behavior
          // is that the SharedPayloadDTO is never persisted or sent, because we don't create CKMTransaction dependency
          // until we have acknowledgement from the server that the address request was successfully posted.
          strongSelf.handleFailureInvite(error: error)
          strongSelf.set(mode: .failure, for: successFailViewController)
      }
    }

    self.navigationController.topViewController()?.present(successFailViewController, animated: false) {
      successFailViewController.retryCompletion?()
    }
  }

  private func set(mode: SuccessFailViewController.Mode, for viewController: SuccessFailViewController) {
    DispatchQueue.main.async {
      viewController.mode = mode
    }
  }

  private func handleFailureInvite(error: Error) {
    analyticsManager.track(event: .dropbitInitiationFailed, with: nil)

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "invite_failure")
    os_log("DropBit invite failed: %@", log: logger, type: .error, error.localizedDescription)

    var errorMessage = ""

    if let networkError = error as? CKNetworkError, case .rateLimitExceeded = networkError {
      errorMessage = "For security reasons we must limit the number of DropBits sent too rapidly.  Please briefly wait and try sending again."

    } else if let txDataError = error as? TransactionDataError, case .insufficientFee = txDataError {
      errorMessage = (error as? TransactionDataError)?.messageDescription ?? ""

    } else {
      errorMessage = "Oops something went wrong, try again later"
    }

    let alert = alertManager.defaultAlert(withTitle: "Error", description: errorMessage)
    self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
  }

  private func handleSuccessfulInvite(outgoingInvitationDTO: OutgoingInvitationDTO,
                                      response: WalletAddressRequestResponse,
                                      in context: NSManagedObjectContext) {
    analyticsManager.track(event: .dropbitInitiated, with: nil)
    context.performAndWait {
      let outgoingTransactionData = OutgoingTransactionData(
        txid: CKMTransaction.invitationTxidPrefix + response.id,
        contactName: outgoingInvitationDTO.contact.displayName ?? "",
        contactPhoneNumber: outgoingInvitationDTO.contact.globalPhoneNumber,
        contactPhoneNumberHash: outgoingInvitationDTO.contact.phoneNumberHash,
        destinationAddress: "",
        amount: outgoingInvitationDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC),
        feeAmount: outgoingInvitationDTO.fee,
        sentToSelf: false,
        requiredFeeRate: nil,
        sharedPayloadDTO: outgoingInvitationDTO.sharedPayloadDTO
      )
      self.persistenceManager.acknowledgeInvitation(with: outgoingTransactionData, response: response, in: context)
    }
  }

  private func handleSuccessfulPaymentVerification(
    with transactionData: CNBTransactionData,
    outgoingTransactionData: OutgoingTransactionData
    ) {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "successful_payment_verification")
    let successFailViewController = SuccessFailViewController.makeFromStoryboard()
    successFailViewController.modalPresentationStyle = .overFullScreen
    assignCoordinationDelegate(to: successFailViewController)
    successFailViewController.retryCompletion = { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.networkManager.updateCachedMetadata()
        .then { _ in strongSelf.networkManager.broadcastTx(with: transactionData) }
        .then { txid -> Promise<String> in
          guard let wmgr = strongSelf.walletManager else {
            return Promise(error: CKPersistenceError.missingValue(key: "wallet"))
          }
          let dataCopyWithTxid = outgoingTransactionData.copy(withTxid: txid)
          return strongSelf.networkManager.postSharedPayloadIfAppropriate(withOutgoingTxData: dataCopyWithTxid,
                                                                          walletManager: wmgr)
        }
        .then { (txid: String) -> Promise<Void> in
          let context = strongSelf.persistenceManager.createBackgroundContext()

          context.performAndWait {
            let vouts = transactionData.unspentTransactionOutputs.map { CKMVout.find(from: $0, in: context) }.compactMap { $0 }
            let voutDebugDesc = vouts.map { $0.debugDescription }.joined(separator: "\n")
            os_log("broadcast succeeded: vouts: %@", log: logger, type: .debug, voutDebugDesc)

            strongSelf.persistenceManager.persistTemporaryTransaction(
              from: transactionData,
              with: outgoingTransactionData,
              txid: txid,
              invitation: nil,
              in: context
            )

            if let walletCopy = strongSelf.walletManager?.createWalletCopy() {
              let transactionBuilder = CNBTransactionBuilder()
              let metadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: walletCopy)
              do {
                _ = try CKMVout.findOrCreateTemporaryVout(in: context, with: transactionData, metadata: metadata)
              } catch {
                os_log("error creating temp vout: %@, in %@", log: logger, type: .error, error.localizedDescription, #function)
              }
            }

            do {
              try context.save()
            } catch {
              os_log("error saving context in %@.\n%@", log: logger, type: .error, #function, error.localizedDescription)
            }
          }
          return Promise.value(())
        }
        .done(on: .main) {
          successFailViewController.mode = .success
          self?.analyticsManager.track(property: MixpanelProperty(key: .hasSent, value: true))
          self?.trackIfUserHasABalance()
        }.catch { error in
          let nsError = error as NSError
          let broadcastError = TransactionBroadcastError(errorCode: nsError.code)
          if let context = self?.persistenceManager.createBackgroundContext() {
            context.performAndWait {
              let vouts = transactionData.unspentTransactionOutputs.map { CKMVout.find(from: $0, in: context) }.compactMap { $0 }
              let voutDebugDesc = vouts.map { $0.debugDescription }.joined(separator: "\n")
              let encodedTx = nsError.userInfo["encoded_tx"] as? String ?? ""
              let txid = nsError.userInfo["txid"] as? String ?? ""
              let analyticsError = "error code: \(broadcastError.rawValue) :: txid: \(txid) :: encoded_tx: \(encodedTx) :: vouts: \(voutDebugDesc)"
              os_log("broadcast failed: %@", log: logger, type: .error, analyticsError)
              let eventValue = AnalyticsEventValue(key: .broadcastFailed, value: analyticsError)
              strongSelf.analyticsManager.track(event: .paymentSentFailed, with: eventValue)
            }
          }

          if let networkError = error as? CKNetworkError,
            case let .reachabilityFailed(moyaError) = networkError {
            self?.handleReachabilityError(moyaError)

          } else {
            strongSelf.handleFailure(error: error, action: {
              DispatchQueue.main.async { successFailViewController.mode = .failure }
            })
          }
      }
    }

    self.navigationController.topViewController()?.present(successFailViewController, animated: false) {
      successFailViewController.retryCompletion?()
    }
  }

  private func handleFailure(error: Error?, action: (() -> Void)? = nil) {
    var localizedDescription = ""
    if let txError = error as? TransactionDataError {
      localizedDescription = txError.messageDescription
    } else {
      localizedDescription = error?.localizedDescription ?? "Unknown error"
    }
    analyticsManager.track(error: .submitTransactionError, with: localizedDescription)
    let config = AlertActionConfiguration(title: "OK", style: .default, action: action)
    let configs = [config]
    let alert = alertManager.alert(
      withTitle: "",
      description: localizedDescription,
      image: nil,
      style: .alert,
      actionConfigs: configs)
    DispatchQueue.main.async { self.navigationController.topViewController()?.present(alert, animated: true) }
  }

}