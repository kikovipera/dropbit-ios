//
//  ScanQRViewController.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import os.log

//swiftlint:disable class_delegate_protocol
protocol ScanQRViewControllerDelegate: PaymentRequestResolver, ViewControllerDismissable {

  /// If the scanned qrCode.btcAmount is zero, use the fallbackViewModel (whose amount should originate from the calculator amount/converter).
  func viewControllerDidScan(_ viewController: UIViewController, qrCode: QRCode, fallbackViewModel: SendPaymentViewModel?)

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?)

}

class ScanQRViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var flashButton: UIButton!
  @IBOutlet var scanBoxImageView: UIImageView!

  var bitcoinAddressValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [StringEmptyValidator(), BitcoinAddressValidator()])
  }()

  var coordinationDelegate: ScanQRViewControllerDelegate? {
    return generalCoordinationDelegate as? ScanQRViewControllerDelegate
  }

  /**
   This view model should be set when presenting this view controller (usually reflects latest amount and fromCurrency of the calculator).
   It's btcAmount will be used if the scanned QRCode's amount is zero.
   */
  var fallbackPaymentViewModel: SendPaymentViewModel?

  var captureSession: AVCaptureSession = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  var captureMetadataOutput = AVCaptureMetadataOutput()
  var captureDevice: AVCaptureDevice?
  var isFlashlightEnabled: Bool = false
  var didCaptureQRCode = false

  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.scanqrviewcontroller", category: "scan_qr_view_controller")

  override func viewDidLoad() {
    view.backgroundColor = UIColor.black
    if let captureDevice = AVCaptureDevice.default(for: .video) {
      self.captureDevice = captureDevice
      do {
        let input = try AVCaptureDeviceInput(device: captureDevice)
        let supportedCodeTypes: [AVMetadataObject.ObjectType] = [.qr]
        captureSession.addInput(input)
        captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
        captureMetadataOutput.rectOfInterest = scanBoxImageView.bounds

        captureSession.sessionPreset = AVCaptureSession.Preset.high
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        captureSession.startRunning()
      } catch {
        os_log("Failed to capture device input: %{private}@", log: self.logger, type: .error, error.localizedDescription)
      }
    } else {
      os_log("Cannot create capture device on simulator", log: self.logger, type: .error)
    }
  }

  private func toggleFlashlight() {
    guard let device = captureDevice else {
      return
    }

    if device.hasTorch {
      do {
        try device.lockForConfiguration()

        if isFlashlightEnabled {
          device.torchMode = .off
        } else {
          device.torchMode = .on
        }

        isFlashlightEnabled = !isFlashlightEnabled
        device.unlockForConfiguration()
      } catch {
        os_log("Torch could not be used", log: self.logger, type: .error)
      }
    } else {
      os_log("Torch is not available", log: self.logger, type: .error)
    }
  }

  @IBAction func flashButtonWasTouched() {
    toggleFlashlight()
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }
}

extension ScanQRViewController: AVCaptureMetadataOutputObjectsDelegate {

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard metadataObjects.isNotEmpty else { return }

    let qrCodes = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }.compactMap { QRCode(readableObject: $0) }
    guard let qrCode = qrCodes.first else { return }

    if didCaptureQRCode { return } // prevent multiple network requests for paymentRequestURL
    didCaptureQRCode = true

    if qrCode.paymentRequestURL != nil {
      coordinationDelegate?.viewControllerDidScan(self, qrCode: qrCode, fallbackViewModel: self.fallbackPaymentViewModel)

    } else if let address = qrCode.address {
      do {
        try bitcoinAddressValidator.validate(value: address)
        coordinationDelegate?.viewControllerDidScan(self, qrCode: qrCode, fallbackViewModel: self.fallbackPaymentViewModel)
      } catch {
        coordinationDelegate?.viewControllerDidAttemptInvalidDestination(self, error: error)
      }
    }
  }

}
