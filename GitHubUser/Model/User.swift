//
//  User.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation



struct User: Codable {
    var avatarUrl: String
    var login: String
    var siteAdmin: Bool
    
    private enum CodingKeys : String, CodingKey {
            case avatarUrl = "avatar_url",
                 login = "login",
                 siteAdmin = "site_admin"
    }
}
