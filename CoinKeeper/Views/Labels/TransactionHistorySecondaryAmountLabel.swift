//
//  TransactionHistorySecondaryAmountLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistorySecondaryAmountLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.transactionHistorySecondaryAmount.font
    textColor = Theme.Color.grayText.color
    isHidden = false
    numberOfLines = 1
    textAlignment = .right
  }
}
