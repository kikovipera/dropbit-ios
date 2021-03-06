//
//  ConfirmPaymentButton.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ConfirmPaymentButtonDelegate: class {
  func didConfirm()
}

class ConfirmPaymentButton: UIButton {

  private var backgroundBezierPath: UIBezierPath = UIBezierPath()
  private var backgroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var foregroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var circleAnimation: CABasicAnimation = CABasicAnimation()
  private var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

  var secondsToConfirm: Double = 3.0

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  private func initalize() {
    setupLines()
    setupDefaults()
    setupCircleAnimation()
  }

  func animate() {
    startAnimation()
  }

  func reset() {
    foregroundShapeLayer.removeAllAnimations()
    foregroundShapeLayer.strokeEnd = 0.0
    backgroundShapeLayer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
    foregroundShapeLayer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
  }

  private func setupDefaults() {
    backgroundColor = UIColor.clear
  }

  private func setupCircleAnimation() {
    circleAnimation = CABasicAnimation(keyPath: "strokeEnd")
    circleAnimation.duration = secondsToConfirm
    circleAnimation.repeatCount = 1.0
    circleAnimation.fromValue = 0.0
    circleAnimation.toValue = 1.0
    circleAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
  }

  private func startAnimation() {
    foregroundShapeLayer.add(circleAnimation, forKey: "draw")
    backgroundShapeLayer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
    foregroundShapeLayer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
  }

  private func setupLines() {
    backgroundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0,
                                                            width: frame.size.width,
                                                            height: frame.size.height),
                                        byRoundingCorners: .allCorners,
                                        cornerRadii: CGSize(width: frame.size.width / 2.0, height: frame.size.height / 2.0))

    let lineWidthDivisor: CGFloat = 12.0

    backgroundShapeLayer.path = backgroundBezierPath.cgPath
    backgroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    backgroundShapeLayer.lineWidth = frame.size.height / lineWidthDivisor
    backgroundShapeLayer.strokeColor = Theme.Color.grayText.color.cgColor
    backgroundShapeLayer.fillColor = UIColor.clear.cgColor
    backgroundShapeLayer.strokeEnd = 1.0
    backgroundShapeLayer.zPosition = -1
    backgroundShapeLayer.bounds = bounds
    backgroundShapeLayer.frame = bounds

    foregroundShapeLayer.path = backgroundBezierPath.cgPath
    foregroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    foregroundShapeLayer.fillColor = UIColor.clear.cgColor
    foregroundShapeLayer.lineWidth = frame.size.height / lineWidthDivisor
    foregroundShapeLayer.strokeColor = Theme.Color.lightBlueTint.color.cgColor
    foregroundShapeLayer.speed = 1.0
    foregroundShapeLayer.timeOffset = 0.0
    foregroundShapeLayer.beginTime = 0.0
    foregroundShapeLayer.strokeEnd = 0.0
    foregroundShapeLayer.bounds = bounds
    foregroundShapeLayer.frame = bounds

    layer.addSublayer(backgroundShapeLayer)
    layer.addSublayer(foregroundShapeLayer)
  }
}
