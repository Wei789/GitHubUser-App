//
//  UserTableViewCell.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    static let identifier = "UserTableViewCell"
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var siteAdminLabel: UILabel!
}
