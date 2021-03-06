//
//  ViewController.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/9.
//

import UIKit
import SDWebImage

class UsersViewController: UIViewController {
    @IBOutlet weak var userTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let userViewModel = UserViewModel()
    var reloadIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        userViewModel.getUsersSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.userTableView.reloadData()
                self?.activityIndicator.stopAnimating()
            }
        }
        
        userViewModel.getUsersFail = {[weak self](error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        userViewModel.getUsers(since: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let reloadIndex = reloadIndex {
            DispatchQueue.main.async {
                self.userTableView.reloadRows(at: [reloadIndex], with: .automatic)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == UserDetailViewController.segueID {
            if let detailVC = segue.destination as? UserDetailViewController {
                detailVC.userViewModel = userViewModel
                detailVC.userName = sender as? String
            }
        }
    }
}

extension UsersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userViewModel.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.identifier) as? UserTableViewCell else {
            fatalError("Could not dequeue tableCell")
        }
        
        cell.loginLabel.text = userViewModel.users[indexPath.row].login
        cell.siteAdminLabel.text = "\(userViewModel.users[indexPath.row].siteAdmin)"
        cell.userImageView.sd_setImage(with: userViewModel.users[indexPath.row].avatarUrl, placeholderImage: nil)
        cell.isFavoriteUser.isOn = userViewModel.favoriteUsers.contains(userViewModel.users[indexPath.row].login)
        cell.favoriteChange = { [unowned self] in
            if cell.isFavoriteUser.isOn {
                self.userViewModel.saveFavoriteUser(login: self.userViewModel.users[indexPath.row].login)
            } else {
                self.userViewModel.removeFavoriteUser(login: self.userViewModel.users[indexPath.row].login)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = userViewModel.users.count - 1
        if indexPath.row == lastElement && !userViewModel.isLoading {
            self.activityIndicator.startAnimating()
            userViewModel.getUsers()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: UserDetailViewController.segueID, sender: userViewModel.users[indexPath.row].login)
        reloadIndex = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
