//
//  KeypadDigitView.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

@IBDesignable
class KeypadDigitView: UIView {

  var isSecure = false {
    didSet {
      updateUI()
    }
  }

  var digit: String = "" {
    didSet {
      updateUI()
    }
  }

  var hasDigit: Bool {
    get {
      return !digit.isEmpty
    }
    set { // A setter (in fact, the getter, too) doesn't make sense if isSecure is false
      digit = newValue ? "•" : ""
    }
  }

  @IBOutlet var letterView: UILabel! {
    didSet {
      updateUI()
    }
  }
  @IBOutlet var circleView: UIView! {
    didSet {
      circleView.layer.masksToBounds = true
      circleView.layer.cornerRadius = self.frame.width / 6.0
      updateUI()
    }
  }
  @IBOutlet var bottomBarView: UIView! {
    didSet {
      updateUI()
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  @IBInspectable var letterColor: UIColor? = Theme.Color.lightBlueTint.color {
    didSet {
      updateUI()
    }
  }
  @IBInspectable var bottomBarColor: UIColor? = Theme.Color.lightBlueTint.color {
    didSet {
      updateUI()
    }
  }
  @IBInspectable var circleColor: UIColor? = Theme.Color.lightBlueTint.color {
    didSet {
      updateUI()
    }
  }

  private func updateUI() {
    let showLetter = !isSecure && hasDigit
    let showCircle = isSecure && hasDigit

    bottomBarView?.backgroundColor = bottomBarColor
    circleView?.backgroundColor = circleColor

    circleView?.isHidden = !showCircle

    letterView?.text = digit
    letterView?.textColor = letterColor
    letterView?.isHidden = !showLetter
  }

}
