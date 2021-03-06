//
//  ExamplePhoneNumberLabel.swift
//  DropBit
//
//  Created by Ben Winters on 3/11/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class ExamplePhoneNumberLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.examplePhoneNumber.font
    textColor = Theme.Color.grayText.color
  }
}
