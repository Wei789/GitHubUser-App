//
//  UserViewModel.swift
//  GitHubUser
//
//  Created by 鄭惟臣 on 2020/12/10.
//

import Foundation

class UserViewModel {
    private let router = Router<UserAPI>()
    var getUsersSuccess: (() -> ())?
    var getUsersFail: ((_ error: String) -> ())?
    var getUserByUserNameSuccess: (() -> ())?
    var getUserFail: ((_ error: String) -> ())?
    var getFollowingSuccess: (() -> ())?
    var getFollowersSuccess: (() -> ())?
    var getFollowersFail: ((_ error: String) -> ())?
    var getFollowingFail: ((_ error: String) -> ())?
    var getBidirectionalFollowersSuccess: (() -> ())?
    var isLastPage: (() -> ())?
    
    let group = DispatchGroup()
    let maxPerpage = 100
    let favoriteUsersDefaultKey = "favoriteUsers"
    let userDefault: UserDefaults!
    var isLoading = false
    var isFollowingLast = false
    var isFollowersLast = false
    var isAlreadyGetAllFollow = false
    var isAlreadyGetFollowers = false
    var isAlreadyGetFollowing = false
    var followType: FollowType?
    var followers: [Follower] = [] {
        didSet {
            getFollowersSuccess?()
        }
    }
    
    var following: [Follower] = [] {
        didSet {
            getFollowingSuccess?()
        }
    }
    var bidirectionalFollowed: [Follower] = []
    var favoriteUsers: [String] = []
    private var userNextQuery: [String: Int] = [:]
    private var userLastQuery: [String: Int] = [:]
    private var followersNextQuery: [String: Int] = [:]
    private var followersLastQuery: [String: Int] = [:]
    private var followingNextQuery: [String: Int] = [:]
    private var followingLastQuery: [String: Int] = [:]
    var user: UserDetail? {
        didSet {
            getUserByUserNameSuccess?()
        }
    }
    
    var users: [User] = [] {
        didSet {
            getUsersSuccess?()
        }
    }
    
    init() {
        userDefault = UserDefaults()
        favoriteUsers = userDefault.value(forKey: favoriteUsersDefaultKey) as? [String] ?? []
    }
    
    func getUserByUserName(userName: String) {
        router.request(.getUserByUserName(userName: userName)) {[weak self] (data: UserDetail?, error, linkHeader) in
            if let error = error {
                self?.getUserFail?(error)
                return
            }
            
            if let data = data {
                self?.user = data
            }
        }
    }
    
    func getUsers(since: Int? = nil, getAll: Bool = false) {
        if userNextQuery.isEmpty && since == nil {
            getUsersFail?("Last Page")
            return
        }
        
        guard let nextSince = since != nil ? since : userNextQuery["since"] else {
            return
        }
        
        isLoading = true
        router.request(.getUsers(since: nextSince, perPage: maxPerpage)) {[weak self] (data: [User]?, error, linkHeader) in
            self?.isLoading = false
            if let error = error {
                self?.getUsersFail?(error)
                return
            }
            
            if let data = data {
                self?.users += data
                if let linkHeaderQuery = self?.processLinkHeader(linkHeader) {
                    self?.userNextQuery = linkHeaderQuery.nextPage
                    self?.userLastQuery = linkHeaderQuery.lastPage
                }
                
                if getAll {
                    self?.getUsers(getAll: getAll)
                }
            }
        }
    }
    
    func getBidirectionalFollowed() {
        // design consideration and principle:
        // 以Call最少API次數為原則
        // step1. 取得following and followers 兩者中最數量最小 minCount
        // step2. 取得totalCallAPICount = (followingCount + followersCount) / 100(max per page)
        // step3. if totalCallAPICount <= minCount then 取得所有follwing和followers做intersection得到bidirectional Follower list
        //        else call check follow API check step1 following or followers 最小數量
        self.followers = []
        self.following = []
        if let followingCount = user?.following, let followersCount = user?.followers {
            if followingCount == 0 || followersCount == 0 {
                return
            }
            
            let minCount = min(followersCount, followingCount)
            let totalCallAPICount = (followersCount + followingCount) / maxPerpage
            if totalCallAPICount <= minCount {
                // call all
                self.isAlreadyGetAllFollow = true
                self.getFollowers(page: 1, getAll: true)
                self.getFollowing(page: 1, getAll: true)
                self.isLastPage = {[unowned self] in
                    if self.isFollowingLast && self.isFollowersLast {
                        self.proccessBidirectionalFollowed()
                        self.getBidirectionalFollowersSuccess?()
                    }
                }
            } else {
                // call check follow API to get bidirectional Follower
                let serialQueue: DispatchQueue = DispatchQueue(label: "serialQueue")
                if followingCount <= followersCount {
                    self.isAlreadyGetFollowing = true
                    self.getFollowing(page: 1, getAll: true)
                    self.isLastPage = {[unowned self] in
                        serialQueue.async {
                            for f in self.following {
                                group.enter()
                                self.checkUserFollows(user: f, target: Follower(id: self.user!.id, login: self.user!.login))
                            }
                            
                            group.notify(queue: serialQueue) {
                                self.getBidirectionalFollowersSuccess?()
                            }
                        }
                    }
                } else {
                    isAlreadyGetFollowers = true
                    self.getFollowers(page: 1, getAll: true)
                    self.isLastPage = {[unowned self] in
                        for f in self.followers {
                            group.enter()
                            self.checkUserFollows(user: Follower(id: self.user!.id, login: self.user!.login), target: f)
                        }
                        
                        group.notify(queue: serialQueue) {
                            self.getBidirectionalFollowersSuccess?()
                        }
                    }
                }
            }
        }
    }
    
    func checkUserFollows(user: Follower, target: Follower) {
        router.request(.checkUserFollows(userName: user.login, targetName: target.login)) {[unowned self] (data: Empty?, error, linkHeader) in
            if error == NetworkResponse.noData.rawValue {
                if self.isAlreadyGetFollowing {
                    self.bidirectionalFollowed.append(user)
                } else {
                    self.bidirectionalFollowed.append(target)
                }
            }
            
            self.group.leave()
        }
    }
    
    func getFollowers(page: Int? = nil, getLastPage: Int? = nil, getAll: Bool = false) {
        if followersNextQuery.isEmpty && page == nil {
            isFollowersLast = true
            isLastPage?()
            getFollowersFail?("Last Page")
            return
        }
        
        let nexPage = page != nil ? page : followersNextQuery["page"]
        guard let lastPage = getLastPage != nil ? getLastPage : nexPage else {
            return
        }
        
        isLoading = true
        router.request(.getFollowers(userName: user!.login, page: lastPage, per_page: maxPerpage)) {[weak self] (data: [Follower]?, error, linkHeader) in
            self?.isLoading = false
            if let error = error {
                self?.getFollowersFail?(error)
                return
            }
            
            if let data = data {
                self?.followers += data
                if let linkHeaderQuery = self?.processLinkHeader(linkHeader) {
                    self?.followersNextQuery = linkHeaderQuery.nextPage
                    self?.followersLastQuery = linkHeaderQuery.lastPage
                }
                
                if getAll {
                    self?.getFollowers(getAll: getAll)
                }
            }
        }
    }
    
    func getFollowing(page: Int? = nil, getLastPage: Int? = nil, getAll: Bool = false) {
        if followingNextQuery.isEmpty && page == nil {
            isFollowingLast = true
            isLastPage?()
            getFollowingFail?("Last Page")
            return
        }
        
        let nexPage = page != nil ? page : followingNextQuery["page"]
        guard let lastPage = getLastPage != nil ? getLastPage : nexPage else {
            return
        }
        
        isLoading = true
        router.request(.getFollowing(userName: user!.login, page: lastPage, per_page: maxPerpage)) {[weak self] (data: [Follower]?, error, linkHeader) in
            self?.isLoading = false
            if let error = error {
                self?.getFollowingFail?(error)
                return
            }
            
            if let data = data {
                self?.following += data
                if let linkHeaderQuery = self?.processLinkHeader(linkHeader) {
                    self?.followingNextQuery = linkHeaderQuery.nextPage
                    self?.followingLastQuery = linkHeaderQuery.lastPage
                    
                    if getAll {
                        self?.getFollowing(page: nil, getLastPage: nil, getAll: getAll)
                    }
                }
                
                if getAll {
                    self?.getFollowing(getAll: getAll)
                }
            }
        }
    }
    
    func saveFavoriteUser(login: String) {
        favoriteUsers.append(login)
        userDefault.setValue(favoriteUsers, forKey: favoriteUsersDefaultKey)
    }
    
    func removeFavoriteUser(login: String) {
        if let index = favoriteUsers.firstIndex(of: login) {
            favoriteUsers.remove(at: index)
            userDefault.setValue(favoriteUsers, forKey: favoriteUsersDefaultKey)
        }
    }
    
    private func proccessBidirectionalFollowed() {
        let f1 = Set(followers.map({$0.login}))
        let f2 = Set(following.map({$0.login}))
        let intersectionslogin = Array(f1.intersection(f2))
        bidirectionalFollowed = followers.filter({ intersectionslogin.contains($0.login) })
    }
    
    private func processLinkHeader(_ linkHeader: String?) -> (nextPage: [String: Int], lastPage: [String: Int])? {
        if let links = linkHeader?.components(separatedBy: ",") {
            var dictionary: [String: String] = [:]
            links.forEach({
                let components = $0.components(separatedBy:"; ")
                let cleanPath = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
                dictionary[components[1]] = cleanPath
            })
            
            var nextPageQuery: String?
            var lastPageQuery: String?
            for (key, value) in dictionary {
                guard var start = value.firstIndex(of: "?") else { return nil }
                start = value.index(start, offsetBy: 1)
                let end = value.endIndex
                let range = start..<end
                switch linkHeaderType(rawValue: key) {
                case .next:
                    nextPageQuery = String(value[range])
                case .last:
                    lastPageQuery = String(value[range])
                case .none:
                    break
                }
            }
            
            // Query to dictionary
            var nextDict: [String: Int] = [:]
            var queryArray = nextPageQuery?.components(separatedBy: "&")
            queryArray?.forEach({
                let components = $0.components(separatedBy: "=")
                nextDict[components[0]] = Int(components[1])
            })
            
            var lastDict: [String: Int] = [:]
            queryArray = lastPageQuery?.components(separatedBy: "&")
            queryArray?.forEach({
                let components = $0.components(separatedBy: "=")
                lastDict[components[0]] = Int(components[1])
            })
            
            return (nextDict, lastDict)
        }
        
        return nil
    }
}

enum linkHeaderType: String {
    case next = "rel=\"next\""
    case last = "rel=\"last\""
}
