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
    var isLoading = false
    var users: [User] = [] {
        didSet {
            getUsersSuccess?()
        }
    }
    
    private var linkHeaderQuery: String?
    private var isLast = false
    private var isEnd = false
    
    func getUsers() {
        if isEnd {
            return
        }
        
        isEnd = isLast
        isLoading = true
        let getUser = (linkHeaderQuery != nil) ? UserAPI.getUsersByQuery(query: linkHeaderQuery!) : UserAPI.getUsers(since: 0, perPage: 20)
        router.request(getUser) {[weak self] (data: [User]?, error, linkHeader) in
            self?.isLoading = false
            if let error = error {
                self?.getUsersFail?(error)
                return
            }
            
            if let data = data {
                self?.users += data
                self?.processLinkHeader(linkHeader)
            }
        }
    }
    
    private func processLinkHeader(_ linkHeader: String?) {
        if let links = linkHeader?.components(separatedBy: ",") {
            var dictionary: [String: String] = [:]
            links.forEach({
                let components = $0.components(separatedBy:"; ")
                let cleanPath = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
                dictionary[components[1]] = cleanPath
            })
            
            var start: String.Index?
            var nextPagePath: String?
            if dictionary["rel=\"next\""] != nil {
                nextPagePath = dictionary["rel=\"next\""]
                start = nextPagePath?.firstIndex(of: "?")
            } else if dictionary["rel=\"last\""] != nil {
                nextPagePath = dictionary["rel=\"last\""]
                start = nextPagePath?.firstIndex(of: "?")
                isLast = true
            } else {
                return
            }
            
            if let nextPagePath = nextPagePath, let start = start {
                let end = nextPagePath.endIndex
                let range = start..<end
                linkHeaderQuery = String(nextPagePath[range])
            }
        }
    }
}
