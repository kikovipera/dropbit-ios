//
//  WalletAddressRequestsTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum WalletAddressRequestsTarget: CoinNinjaTargetType {
  typealias ResponseType = WalletAddressRequestResponse

  case create(RequestAddressBody)
  case get(WalletAddressRequestSide)

  /// updateWalletAddressRequest params - id: String, request: WalletAddressRequest
  case update(String, WalletAddressRequest)

}

extension WalletAddressRequestsTarget {

  var basePath: String {
    return "wallet/address_requests"
  }

  var subPath: String? {
    switch self {
    case .create:             return nil
    case .get(let side):      return side.urlComponent
    case .update(let id, _):  return id
    }
  }

  public var method: Method {
    switch self {
    case .create:   return .post
    case .get:      return .get
    case .update:   return .patch
    }
  }

  public var task: Task {
    switch self {
    case .create(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .get:
      return .requestPlain
    case .update(_, let request):
      return .requestJSONEncodable(request)
    }
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    let defaultError = defaultNetworkError(for: moyaError)

    // 501: Successfully created address request, but Twilio failed to send SMS
    if let statusCode = moyaError.unacceptableStatusCode,
      let response = moyaError.response,
      statusCode == 501, case .create = self {
      return CKNetworkError.twilioError(response)
    } else {
      return defaultError
    }
  }

}
