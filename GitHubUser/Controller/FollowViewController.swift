//
//  FollowViewController.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import UIKit

class FollowViewController: UIViewController {
    @IBOutlet weak var followTableView: UITableView!
    var activityIndicator: UIActivityIndicatorView!
    var userViewModel: UserViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        followTableView.tableFooterView = UIView()
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        activityIndicator.color = .blue
        self.view.addSubview(activityIndicator)
        if userViewModel.isAlreadyGetAllFollow {
            followTableView.reloadData()
        } else if userViewModel.isAlreadyGetFollowing {
            userViewModel.getFollowersSuccess = successHandler()
            userViewModel.getFollowersFail = errorHandler()
            userViewModel.getFollowers(page: 1, getLastPage: nil, getAll: false)
        } else {
            userViewModel.getFollowingSuccess = successHandler()
            userViewModel.getFollowingFail = errorHandler()
            userViewModel.getFollowing(page: 1, getLastPage: nil, getAll: false)
        }
    }
    
    fileprivate func successHandler() -> () -> () {
        return {[weak self] in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.followTableView.reloadData()
            }
        }
    }
    
    fileprivate func errorHandler() -> (String) -> () {
        return {[weak self] (error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
}


extension FollowViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch userViewModel.followType {
        case .bidirectionalFollowed:
            return userViewModel.bidirectionalFollowed.count
        case .follower:
            return userViewModel.followers.count
        case .following:
            return userViewModel.following.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FollowTableViewCell") else {
            fatalError("Could not dequeue tableCell")
        }
        
        var result: [Follower] = []
        switch userViewModel.followType {
        case .bidirectionalFollowed:
            result = userViewModel.bidirectionalFollowed
        case .follower:
            result = userViewModel.followers
        case .following:
            result = userViewModel.following
        default:
            break
        }
        
        cell.textLabel?.text = "\(indexPath.row). " + result[indexPath.row].login
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = userViewModel.followers.count - 1
        if indexPath.row == lastElement && !userViewModel.isLoading {
            self.activityIndicator.startAnimating()
            if userViewModel.isAlreadyGetAllFollow {
                self.activityIndicator.stopAnimating()
                return
            } else if userViewModel.isAlreadyGetFollowing {
                userViewModel.getFollowers()
            } else {
                userViewModel.getFollowing()
            }
        }
    }
}
