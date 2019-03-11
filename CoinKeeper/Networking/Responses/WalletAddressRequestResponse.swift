//
//  WalletAddressRequestResponse.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// Includes 8 places after the decimal, in groups of 4
let MAX_SATOSHI: Int = 21_000_000_0000_0000

public enum WalletAddressRequestSide: String {
  case sent
  case received

  var urlComponent: String {
    return self.rawValue
  }

}

public enum WalletAddressRequestStatus: String {
  case new
  case canceled
  case completed
  case expired
}

public struct MetadataAmount: Decodable, CustomStringConvertible {

  let btc: Int?
  let usd: Int?

  public var description: String {
    var responseDesc = ""
    let propertyKeyValues: [String] = [
      "btc: \(btc.flatMap { String($0) } ?? "-")",
      "usd: \(usd.flatMap { String($0) } ?? "-")"
    ]
    propertyKeyValues.forEach { desc in
      responseDesc.append("\n\t\(desc)")
    }

    return responseDesc
  }
}

public struct MetadataParticipant: Decodable, CustomStringConvertible {
  let countryCode: Int?
  let phoneNumber: String?

  public var description: String {
    var responseDesc = ""
    let propertyKeyValues: [String] = [
      "countryCode: \(countryCode.flatMap { String($0) } ?? "-")",
      "phoneNumber: \(phoneNumber ?? "-")"
    ]
    propertyKeyValues.forEach { desc in
      responseDesc.append("\n\t\(desc)")
    }

    return responseDesc
  }

  func asGlobalPhoneNumber() -> GlobalPhoneNumber? {
    guard let countryCode = self.countryCode,
      let number = self.phoneNumber else { return nil }
    return GlobalPhoneNumber(countryCode: countryCode, nationalNumber: number)
  }

}

public struct WalletAddressRequestMetadata: ResponseDecodable, CustomStringConvertible {

  let amount: MetadataAmount?
  let sender: MetadataParticipant?
  let receiver: MetadataParticipant?
  var requestId: String?

  public var description: String {
    var responseDesc = ""
    let propertyKeyValues: [String] = [
      "amount: \(amount?.description ?? "-")",
      "sender: \(sender?.description ?? "-")",
      "receiver: \(receiver?.description ?? "-")",
      "request_id: \(requestId ?? "-")"
    ]
    propertyKeyValues.forEach { desc in
      responseDesc.append("\n\t\(desc)")
    }

    return responseDesc
  }

  static var sampleJSON: String {
    return """
    "amount": {
    "btc": 120000000,
    "usd": 8292280
    },
    "sender": {
    "country_code": 1,
    "phone_number": "5554441234"
    },
    "receiver": {
    "country_code": 1,
    "phone_number": "5554441234"
    },
    "request_id": "3fbdc415-8789-490a-ad32-0c6fa3590182"
    """
  }

  static var requiredStringKeys: [KeyPath<WalletAddressRequestMetadata, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<WalletAddressRequestMetadata, String?>] {
    return [\.requestId]
  }
}

/// Note that the string representation of these keyPaths may skip a couple layers.
enum WalletAddressRequestResponseKey: String, KeyPathDescribable {
  typealias ObjectType = WalletAddressRequestResponse
  case btcAmount, usdAmount, metadata
}

/// This struct should be used for both requests sent and received
public struct WalletAddressRequestResponse: ResponseDecodable, CustomStringConvertible {

  // Shared properties
  let id: String
  let createdAt: Date
  let updatedAt: Date
  var address: String?
  var addressPubkey: String?
  var txid: String?

  let metadata: WalletAddressRequestMetadata?

  /// Hash of the phone number for the contact associated with this request
  var phoneNumberHash: String?
  var status: String?

  // Sent-only property
  var walletId: String?

  public var description: String {
    var responseDesc = "\nWalletAddressRequestResponse:"
    let propertyKeyValues: [String] = [
      "id: \(id)",
      "createdAt: \(createdAt.description)",
      "updatedAt: \(updatedAt.description)",
      "address: \(address ?? "-")",
      "addressPubkey: \(addressPubkey ?? "-")",
      "status: \(status ?? "-")",
      "metadata: \(metadata?.description ?? "-")",
      "walletId: \(walletId ?? "-")",
      "phoneNumberHash: \(phoneNumberHash ?? "-")",
      "txid: \(txid ?? "-")"
    ]
    propertyKeyValues.forEach { desc in
      responseDesc.append("\n\t\(desc)")
    }

    return responseDesc
  }

  static var requiredStringKeys: [KeyPath<WalletAddressRequestResponse, String>] {
    return [\.id]
  }

  static var optionalStringKeys: [WritableKeyPath<WalletAddressRequestResponse, String?>] {
    return [\.address, \.addressPubkey, \.txid, \.phoneNumberHash, \.status, \.walletId]
  }

}

extension WalletAddressRequestResponse {

  var statusCase: WalletAddressRequestStatus? {
    return status.flatMap { WalletAddressRequestStatus(rawValue: $0) }
  }

  func copy(withAddress address: String) -> WalletAddressRequestResponse {
    return WalletAddressRequestResponse(id: self.id,
                                        createdAt: self.createdAt,
                                        updatedAt: self.updatedAt,
                                        address: address,
                                        addressPubkey: self.addressPubkey,
                                        txid: self.txid,
                                        metadata: self.metadata,
                                        phoneNumberHash: self.phoneNumberHash,
                                        status: self.status,
                                        walletId: self.walletId)
  }

  /// For legacy reasons, this does not require the presence of an addressPubkey for the transaction to be sendable
  var isSatisfiedForSending: Bool {
    guard let statusCase = statusCase, let address = address else { return false }
    return statusCase == .new && address.isNotEmpty
  }

  static var sampleJSON: String {
    return """
    {
    "id": "a1bb1d88-bfc8-4085-8966-e0062278237c",
    "created_at": 1525882145,
    "updated_at": 1525882265,
    "address": "1JbJbAkCXtxpko39nby44hpPenpC1xKGYw",
    "address_pubkey": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8xOUetsCa8EfOlDEBAfREhJqspDoyEh6Szz2in47Tv5n52m9dLYyPCbqZkOB5nTSqtscpkQD/HpykCggvx09iQ==",
    "sender": "498803d5964adce8037d2c53da0c7c7a96ce0e0f99ab99e9905f0dda59fb2e49",
    "txid": "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03",
    "status": "new"
    }
    """
  }

  static func sampleSentData() -> Data {
    let sampleString =
    """
      [
        {
          "id": "a1bb1d88-bfc8-4085-8966-e0062278237c",
          "created_at": 1525882145,
          "updated_at": 1525882265,
          "address": "1JbJbAkCXtxpko39nby44hpPenpC1xKGYw",
          "address_pubkey":
            "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8xOUetsCa8EfOlDEBAfREhJqspDoyEh6Szz2in47Tv5n52m9dLYyPCbqZkOB5nTSqtscpkQD/HpykCggvx09iQ==",
          "metadata": {},
          "phone_number_hash": "498803d5964adce8037d2c53da0c7c7a96ce0e0f99ab99e9905f0dda59fb2e49",
          "txid": "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03",
          "status": "new",
          "user_id": "ad983e63-526d-4679-a682-c4ab052b20e1",
          "wallet_id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d"
        }
      ]
    """
    return sampleString.data(using: .utf8) ?? Data()
  }

  static func validateResponse(_ response: WalletAddressRequestResponse) throws -> WalletAddressRequestResponse {
    let btcKeyPath = WalletAddressRequestResponseKey.btcAmount.path
    let usdKeyPath = WalletAddressRequestResponseKey.usdAmount.path

    guard let responseMetadata = response.metadata else {
      throw CKNetworkError.responseMissingValue(keyPath: WalletAddressRequestResponseKey.metadata.path)
    }

    let metadata = try WalletAddressRequestMetadata.validateResponse(responseMetadata)

    guard  let btcAmount = metadata.amount?.btc else {
      throw CKNetworkError.responseMissingValue(keyPath: btcKeyPath)
    }

    guard let usdAmount = metadata.amount?.usd else {
      throw CKNetworkError.responseMissingValue(keyPath: usdKeyPath)
    }

    guard btcAmount > 0, btcAmount < MAX_SATOSHI else {
      throw CKNetworkError.invalidValue(keyPath: btcKeyPath, value: String(btcAmount), response: response)
    }

    guard usdAmount > 0 else {
      throw CKNetworkError.invalidValue(keyPath: usdKeyPath, value: String(usdAmount), response: response)
    }

    let stringValidatedResponse = try response.validateStringValues()
    return stringValidatedResponse
  }

}