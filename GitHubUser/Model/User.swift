//
//  User.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation



struct User: Codable {
    var avatarUrlString: String
    var login: String
    var siteAdmin: Bool
    var avatarUrl: URL? {
        return URL(string: avatarUrlString)
    }
    
    private enum CodingKeys : String, CodingKey {
        case avatarUrlString = "avatar_url",
             login = "login",
             siteAdmin = "site_admin"
    }
}


struct UserDetail: Codable {
    var avatarUrlString: String
    var login: String
    var name: String
    var bio: String?
    var siteAdmin: Bool
    var location: String?
    var blog: String
    var avatarUrl: URL? {
        return URL(string: avatarUrlString)
    }
    
    private enum CodingKeys : String, CodingKey {
        case avatarUrlString = "avatar_url",
             login = "login",
             siteAdmin = "site_admin",
             name = "name",
             bio = "bio",
             location = "location",
             blog = "blog"
    }
}
