//
//  ViewController.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/9.
//

import UIKit

class ViewController: UIViewController {
    let userViewModel = UserViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userViewModel.getUsers()
        userViewModel.getUsersSuccess = { [weak self] in
            print(self?.userViewModel.users.first?.avatarUrl ?? "")
        }
        
        userViewModel.getUsersFail = {(error) in
            print(error)
        }
    }
}

