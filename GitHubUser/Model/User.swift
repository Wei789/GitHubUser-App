//
//  User.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation



struct User: Codable {
    var avatarUrlString: String
    var avatarUrl: URL? {
        return URL(string: avatarUrlString)
    }
    var login: String
    var siteAdmin: Bool
    var nextPage: URL?
    
    private enum CodingKeys : String, CodingKey {
            case avatarUrlString = "avatar_url",
                 login = "login",
                 siteAdmin = "site_admin"
    }
}
