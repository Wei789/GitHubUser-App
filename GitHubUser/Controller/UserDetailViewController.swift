//
//  UserDetailViewController.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import UIKit

class UserDetailViewController: UIViewController {
    static let segueID = "toDetailSegue"
    let userViewModel = UserViewModel()
    var userName: String!
    var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var avatorImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var blogTextView: UITextView!
    @IBOutlet weak var followerButon: UIButton!
    @IBOutlet weak var followingButon: UIButton!
    @IBOutlet weak var bidirectionalFollowedButon: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        activityIndicator.color = .blue
        self.view.addSubview(activityIndicator)
        blogTextView.textContainer.maximumNumberOfLines = 1
        blogTextView.textContainer.lineBreakMode = .byTruncatingTail
        activityIndicator.startAnimating()
        userViewModel.getUserByUserNameSuccess = {[weak self] in
            DispatchQueue.main.async {
                self?.avatorImageView.sd_setImage(with: self?.userViewModel.user?.avatarUrl, placeholderImage: nil)
                self?.nameLabel.text = self?.userViewModel.user?.name
                self?.loginLabel.text = self?.userViewModel.user?.login
                self?.locationLabel.text = self?.userViewModel.user?.location
                self?.blogTextView.text = self?.userViewModel.user?.blog
                self?.activityIndicator.stopAnimating()
                self?.followerButon.setTitle("\(self?.userViewModel.user?.followers ?? 0) followers", for: .normal)
                self?.followingButon.setTitle("\(self?.userViewModel.user?.following ?? 0) following", for: .normal)
                
                self?.userViewModel.getBidirectionalFollowed()
            }
        }
        
        userViewModel.getUserByUserName(userName: userName)
        userViewModel.getBidirectionalFollowersSuccess = {[weak self] in
            DispatchQueue.main.async {
                self?.bidirectionalFollowedButon.setTitle("\(self?.userViewModel.bidirectionalFollowed.count ?? 0) bidirectional followed", for: .normal)
            }
        }
        
        userViewModel.getUserFail = errorHandler()
    }
    
    @IBAction func toFollowList(_ sender: UIButton) {
        userViewModel.followType = FollowType(rawValue: sender.tag)
        if let followController = storyboard?.instantiateViewController(identifier: "FollowViewController") as? FollowViewController {
            followController.userViewModel = userViewModel
            followController.userName = userName
            self.navigationController?.pushViewController(followController, animated: true)
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


extension UserDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
