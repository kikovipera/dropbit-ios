//
//  ConnectionManager.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Reachability
import os.log

enum ConnectionManagerStatus {
  case none
  case connected
}

protocol ConnectionManagerDelegate: class {
  func connectionManager(_ manager: ConnectionManagerType, didChangeStatusTo status: ConnectionManagerStatus)
  func connectionManagerDidRequestRetry(_ manager: ConnectionManagerType)
}

protocol ConnectionManagerType: AnyObject {
  var delegate: ConnectionManagerDelegate? { get set }
  var status: ConnectionManagerStatus { get }
  func setAPIUnreachable(_ unreachable: Bool)
  func stop()
  func start()
  func updateOverlay(
    from viewController: UIViewController,
    forStatus status: ConnectionManagerStatus,
    completion: (() -> Void)?
  )
}

class ConnectionManager: ConnectionManagerType {

  private var reachability: Reachability? = Reachability()

  weak var delegate: ConnectionManagerDelegate?
  private var noConnectionsViewController: NoConnectionViewController?

  var status: ConnectionManagerStatus {
    switch reachability?.connection {
    case .wifi?, .cellular?:
      return .connected
    default:
      return .none
    }
  }

  private var apiUnreachable: Bool = false

  func setAPIUnreachable(_ unreachable: Bool) {
    guard apiUnreachable != unreachable else { return }
    apiUnreachable = unreachable
    if unreachable {
      retryBeforeConsideringOffline()
    } else {
      reachabilityChanged()
    }
  }

  func updateOverlay(
    from viewController: UIViewController,
    forStatus status: ConnectionManagerStatus,
    completion: (() -> Void)?
    ) {
    switch status {
    case .connected:
      hideOfflineOverlay(completion: completion)
    case .none:
      presentOfflineOverlay(from: viewController, completion: completion)
    }
  }

  init() {
    initalize()
  }

  func stop() {
    reachability?.stopNotifier()
    NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
  }

  func start() {
    NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: .reachabilityChanged, object: reachability)
    do {
      try reachability?.startNotifier()
    } catch {
      let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "reachability")
      os_log("Could not start reachability notifier", log: logger, type: .error)
    }
  }

  func presentOfflineOverlay(from viewController: UIViewController, completion: (() -> Void)?) {
    guard UIApplication.shared.applicationState != .background else { return }
    guard noConnectionsViewController == nil else { return }
    noConnectionsViewController = NoConnectionViewController.makeFromStoryboard()
    configureController(with: delegate)
    noConnectionsViewController.map { viewController.present($0, animated: true, completion: completion) }
  }

  func hideOfflineOverlay(completion: (() -> Void)?) {
    noConnectionsViewController?.dismiss(animated: true, completion: completion)
    noConnectionsViewController = nil
  }

  private func initalize() {
    configureController(with: delegate)
    start()
  }

  private func configureController(with delegate: ConnectionManagerDelegate?) {
    noConnectionsViewController?.modalPresentationStyle = .overFullScreen
    noConnectionsViewController?.modalTransitionStyle = .crossDissolve
    noConnectionsViewController?.generalCoordinationDelegate = delegate
  }

  @objc private func reachabilityChanged() {
    switch status {
    case .connected:
      if apiUnreachable {
        delegate?.connectionManagerDidRequestRetry(self)
      } else {
        delegate?.connectionManager(self, didChangeStatusTo: status)
      }
    case .none:
      delegate?.connectionManager(self, didChangeStatusTo: .none)
    }
  }

  private func retryBeforeConsideringOffline() {
    delegate?.connectionManagerDidRequestRetry(self)
  }
}
