//
//  UserEndPoint.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation

public enum UserAPI {
    case getUsers
}

extension UserAPI: EndPointType {
  var baseURL: URL? {
    return nil
  }
  
  var path: String {
    switch self {
    case .getUsers:
        return "users"
    }
  }
  
  var httpMethod: HTTPMethod {
    return .get
  }
  
  var task: HTTPTask {
    switch self {
    case .getUsers:
      return .request
    }
  }
  
  var headers: HTTPHeaders? {
    return nil
  }
}
