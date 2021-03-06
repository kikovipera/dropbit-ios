//
//  CreateRecoveryWordsCellTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class CreateRecoveryWordsCellTests: XCTestCase {
  var sut: CreateRecoveryWordsCell!

  override func setUp() {
    super.setUp()
    self.sut = CreateRecoveryWordsCell.nib().instantiate(withOwner: self, options: nil).first as? CreateRecoveryWordsCell
    self.sut.awakeFromNib()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.wordLabel, "wordLabel should be connected")
    XCTAssertNotNil(self.sut.statusLabel, "statusLabel should be connected")
  }

  // MARK: initial state
  func testWordLabelInitialState() {
    XCTAssertEqual(self.sut.wordLabel.textColor, Theme.Color.darkBlueButton.color, "wordLabel textColor should be darkBlueButton")
  }

  func testStatusLabelInitialState() {
    XCTAssertEqual(self.sut.statusLabel.textColor, Theme.Color.grayText.color, "statusLabel textColor should be grayText")
  }

  // MARK: load method
  func testLoadMethodPopulatesLabels() {
    let initialWord = "jalapeno"
    let expectedWord = "jalapeno".uppercased()
    let expectedStatus = "word 1 of 12"
    let data = CreateRecoveryWordCellData(word: initialWord, currentIndex: 1, total: 12)

    self.sut.load(with: data)

    XCTAssertEqual(self.sut.wordLabel.text, expectedWord, "should populate wordLabel")
    XCTAssertEqual(self.sut.statusLabel.text, expectedStatus, "should populate statusLabel")
  }
}
