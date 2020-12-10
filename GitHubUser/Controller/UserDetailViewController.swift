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
    var userName: String?
    var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var avatorImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var blogTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        blogTextView.textContainer.maximumNumberOfLines = 1
        blogTextView.textContainer.lineBreakMode = .byTruncatingTail

        activityIndicator.startAnimating()
        userViewModel.getUserByUserName(userName: userName ?? "")
        userViewModel.getUserSuccess = {[weak self] in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.avatorImageView.sd_setImage(with: self?.userViewModel.user?.avatarUrl, placeholderImage: nil)
                self?.nameLabel.text = self?.userViewModel.user?.name
                self?.loginLabel.text = self?.userViewModel.user?.login
                self?.locationLabel.text = self?.userViewModel.user?.location
                self?.blogTextView.text = self?.userViewModel.user?.blog
            }
        }
        
        userViewModel.getUserFail = {[weak self] (error) in
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
