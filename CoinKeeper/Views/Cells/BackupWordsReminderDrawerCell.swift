//
//  BackupWordsReminderDrawerCell.swift
//  DropBit
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BackupWordsReminderDrawerCell: UITableViewCell {

  @IBOutlet var backingView: UIView! {
    didSet {
      backingView.backgroundColor = Theme.Color.errorRed.color
      backingView.layer.cornerRadius = CGFloat(8)
      layer.masksToBounds = true
    }
  }

  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = Theme.Font.alertTitle.font
      titleLabel.textColor = Theme.Color.whiteText.color
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = .clear
  }

  func load(with viewModel: DrawerData) {
    titleLabel.text = viewModel.title
  }

}
