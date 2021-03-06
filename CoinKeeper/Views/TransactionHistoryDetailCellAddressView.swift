//
//  TransactionHistoryDetailCellAddressView.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionHistoryDetailAddressViewDelegate: AnyObject {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView)
}

class TransactionHistoryDetailCellAddressView: UIView {

  // MARK: outlets
  @IBOutlet var addressContainerView: UIView!
  @IBOutlet var addressTextButton: UIButton! {
    didSet {
      addressTextButton.titleLabel?.font = Theme.Font.transactionDetailAddress.font
    }
  }
  @IBOutlet var addressImageButton: UIButton!
  @IBOutlet var addressStatusLabel: TransactionDetailStatusLabel!

  // MARK: variables
  weak var selectionDelegate: TransactionHistoryDetailAddressViewDelegate?

  // MARK: initialization and setup
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    addressStatusLabel.isHidden = true
  }

  // MARK: actions
  @IBAction func addressButtonTapped(_ sender: UIButton) {
    guard let address = addressTextButton.title(for: .normal),
      address.isValidBitcoinAddress()
      else { return }
    selectionDelegate?.addressViewDidSelectAddress(self)
  }

  // MARK: loading
  func load(with viewModel: TransactionHistoryDetailCellViewModel) {

    if let invitationStatus = viewModel.invitationStatus {
      switch invitationStatus {
      case .completed, .addressSent:
        addressContainerView.isHidden = false
        addressStatusLabel.isHidden = true
      case .canceled, .expired:
        addressContainerView.isHidden = true
        addressStatusLabel.isHidden = true
      default:
        addressContainerView.isHidden = true
        addressStatusLabel.isHidden = false
      }
    } else {
      let shouldHideAddressButton = !(viewModel.addressButtonIsActive)
      addressContainerView.isHidden = shouldHideAddressButton
      addressStatusLabel.isHidden = !shouldHideAddressButton
    }

    addressStatusLabel.text = viewModel.addressStatusLabelString

    // this should be populated with the address also, just previously hidden, now visible
    addressTextButton.setTitle(viewModel.receiverAddress, for: .normal)
    addressTextButton.setTitleColor(Theme.Color.lightBlueTint.color, for: .normal)
    addressTextButton.setTitleColor(Theme.Color.grayText.color, for: .disabled)

    addressTextButton.isEnabled = !viewModel.broadcastFailed
    addressImageButton.isHidden = (viewModel.broadcastFailed || !viewModel.addressButtonIsActive)
  }

}
