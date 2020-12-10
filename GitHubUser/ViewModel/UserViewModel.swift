//
//  UserViewModel.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation

class UserViewModel {
    let router = Router<UserAPI>()
    var getUsersSuccess: (() -> ())?
    var getUsersFail: ((_ error: String) -> ())?
    
    var users: [User] = [] {
        didSet {
            getUsersSuccess?()
        }
    }
    
    func getUsers() {
        router.request(.getUsers) {[weak self] (data: [User]?, error) in
            if let error = error {
                self?.getUsersFail?(error)
                return
            }
            
            if let data = data {
                self?.users = data
            }
        }
    }
}
