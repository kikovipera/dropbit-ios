//
//  OnboardingErrorLabel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class OnboardingErrorLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.onboardingSubtitle.font
    textColor = Theme.Color.errorRed.color
    isHidden = true
    numberOfLines = 2
    textAlignment = .center
  }
}
