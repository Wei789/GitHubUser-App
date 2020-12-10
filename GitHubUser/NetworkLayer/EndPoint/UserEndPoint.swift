//
//  UserEndPoint.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation

public enum UserAPI {
    case getUsers(since: Int, perPage: Int)
    case getUsersByQuery(query: String)
}

extension UserAPI: EndPointType {
    var baseURL: URL? {
        return nil
    }
    
    var path: String {
        switch self {
        case .getUsers, .getUsersByQuery:
            return "users"
        }
    }
    
    var httpMethod: HTTPMethod {
        return .get
    }
    
    var task: HTTPTask {
        switch self {
        case .getUsers(let since, let perPage):
            return .requestParameters(bodyParameters: nil, urlParameters: ["per_page": perPage,
                                                                           "since": since])
        case .getUsersByQuery(let query):
            return .requestQuery(queryString: query)
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
}
