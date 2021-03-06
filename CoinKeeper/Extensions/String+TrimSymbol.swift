//
//  String+TrimSymbol.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension String {

  func removing(groupingSeparator: String, currencySymbol: String) -> String {
    let withoutSeparator = self.components(separatedBy: groupingSeparator).joined(separator: "")
    let withoutSymbol = withoutSeparator.replacingOccurrences(of: currencySymbol, with: "")
    return withoutSymbol
  }

  /// Replaces any random whitespace with a single space
  func stringByStandardizingWhitespaces() -> String {
    let components = self.components(separatedBy: .whitespacesAndNewlines)
    return components.filter { $0.isNotEmpty }.joined(separator: " ")
  }

  func removingNonDecimalCharacters(keepingCharactersIn customString: String = "") -> String {
    let customSet = CharacterSet(charactersIn: customString)
    let charactersToKeep = CharacterSet.decimalDigits.union(customSet)
    let charactersToRemove = charactersToKeep.inverted
    return self.components(separatedBy: charactersToRemove).joined()
  }

  func asNilIfEmpty() -> String? {
    return self.isEmpty ? nil : self
  }

  /// Drops first character from string if it matches the parameter
  func dropFirstCharacter(ifEquals char: Character) -> String {
    if self.first == char {
      return String(self.dropFirst())
    } else {
      return self
    }
  }

}
