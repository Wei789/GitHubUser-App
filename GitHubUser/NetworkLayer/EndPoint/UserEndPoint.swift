//
//  UserEndPoint.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation

public enum UserAPI {
    case getUsers(since: Int, perPage: Int)
    case getUserByUserName(userName: String)
    case getFollowers(userName: String, page: Int, per_page: Int)
    case getFollowing(userName: String, page: Int, per_page: Int)
    case checkUserFollows(userName: String, targetName: String)
}

extension UserAPI: EndPointType {
    var baseURL: URL? {
        return nil
    }
    
    var path: String {
        switch self {
        case .getUsers:
            return "users"
        case .getUserByUserName(let userName):
            return "users/\(userName)"
        case .getFollowers(let userName, _, _):
            return "users/\(userName)/followers"
        case .getFollowing(let userName, _, _):
            return "users/\(userName)/following"
        case .checkUserFollows(let userName, let targetName):
            return "users/\(userName)/following/\(targetName)"
        }
    }
    
    var httpMethod: HTTPMethod {
        return .get
    }
    
    var task: HTTPTask {
        switch self {
        case .getUsers(let since, let perPage):
            return .requestParameters(bodyParameters: nil, urlParameters: ["per_page": perPage, "since": since])
        case .getUserByUserName:
            return .request
        case .getFollowers( _, let page, let perPage):
            return .requestParameters(bodyParameters: nil, urlParameters: ["page": page, "per_page": perPage])
        case .getFollowing( _, let page, let perPage):
            return .requestParameters(bodyParameters: nil, urlParameters: ["page": page, "per_page": perPage])
        case .checkUserFollows( _,  _):
            return .request
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
}
