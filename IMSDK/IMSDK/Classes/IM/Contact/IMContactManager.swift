//
//  IMContactManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/17.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

typealias UserModelBlock = (IMUserModel?,Bool,String)->()

typealias UserNormalInfoBlock = (String,String,String)->()

//上一次获取好友列表的时间
let IM_Last_FetchFriendList = "IM_Last_FetchFriendList"

let IM_Block_List = "IM_Block_List"

class IMContactManager: NSObject {

    private static let sharedInstance = IMContactManager()
    
    var applyNumber = 0{
        didSet{
            applyNumSubject.onNext(applyNumber)
        }
    }
    
    let applyNumSubject = BehaviorSubject<Int>(value: 0)
    
    var blockList = [String]() {
        didSet {
            FZM_UserDefaults.setUserValue(blockList, forKey: IM_Block_List)
        }
    }
    
    class func shared() -> IMContactManager {
        return sharedInstance
    }
    
    class func launchClient() {
        _ = IMContactManager.shared()
    }
    
    override init() {
        super.init()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .appState)
        if IMLoginUser.shared().isLogin {
            self.refreshFriendList()
            self.refreshApplyNumber()
        }
    }
    
    private func refreshFriendList() {
        self.friendMap.removeAll()
        let userList = IMUserModel.getAll()
        self.saveUserInMap(with: userList)
        self.blockList = FZM_UserDefaults.getUserObject(forKey: IM_Block_List) as? [String] ?? []
        self.loadBlockList()
        self.fetchFriendList()
    }
    
    func fetchFriendList() {
        HttpConnect.shared().getFriends(count: 100000, index: "") { (response) in
            guard response.success else { return }
            //合约上有好友 就使用合约上的好友
            if let friendsAddress =  response.data?["result"]["friends"].array?.compactMap({ $0["friendAddress"].string
            }), !friendsAddress.isEmpty {
                HttpConnect.shared().getUsersInfo(uids: friendsAddress) { (users, response) in
                    if response.success, !users.isEmpty {
                        users.forEach { $0.isFriend = true }
                        users.forEach { (user) in
                            user.isFriend = true
                            user.isBlocked = self.blockList.contains(user.showId)
                        }
                        self.saveUserInMap(with: users)
                    }
                }
                
            } else {
                //合约上没有好友, 拉取服务器的好友, 并且上链
                HttpConnect.shared().getFriendList(type: 3, time: Date()) { (list, response) in
                    guard response.success, list.count > 0 else { return }
                    list.forEach { $0.isFriend = true }
                    self.saveUserInMap(with: list)
                    //上链
                    let friendsAddress = list.compactMap { $0.showId }
                    HttpConnect.shared().addFriends(address: friendsAddress, completionBlock: nil)
                }
            }
        }
    }
    
    //添加好友
    func addFriend(user: IMUserModel) {
        user.isFriend = true
        self.saveUserInMap(with: [user])
        
        //向合约添加好友
        guard !user.showId.isEmpty else { return }
        HttpConnect.shared().addFriends(address: [user.showId]) { (response) in
            if response.success {
                IMLog("联系人上链成功,hash:\(response.data?["result"].stringValue)")
            }
        }
    }
    
    
    //删除好友
    func deleteFriend(with friendId: String, completeBlock: NormalHandler?) {
        guard let user = self.contactMap[friendId] else { return }
         //向合约删除好友
        guard !user.showId.isEmpty else { return }
        HttpConnect.shared().deleteFriends(address: [user.showId]) { (response) in
            if response.success {
                IMLog("联系人上链成功,hash:\(response.data?["result"].stringValue)")
                user.isDelete = true
                user.isFriend = false
                user.save()
                self.removeFriend(with: friendId)
                IMConversationManager.shared().deleteConversation(with: friendId, type: .person)
                
                completeBlock?(response)
            }
        }
    }
    
    //清空本地好有缓存 用户换了私钥之后
    
    func clearAllFriendsCache() {
        self.getAllFriend().forEach { (friend) in
            friend.isDelete = true
            friend.isFriend = false
            friend.save()
        }
        self.refreshFriendList()
    }
    
    private func loadBlockList() {
        HttpConnect.shared().getBlockList(count: 1000, index: "") { (response) in
            if let blockAddress =  response.data?["result"]["list"].array?.compactMap({ $0["targetAddress"].string
            }), !blockAddress.isEmpty {
                self.blockList = blockAddress
                HttpConnect.shared().getUsersInfo(uids: blockAddress) { (blockUsers, response) in
                    if response.success, !blockUsers.isEmpty {
                        blockUsers.forEach { (user) in
                            user.isFriend = self.contactMap[user.userId]?.isFriend ?? false
                            user.isBlocked = true
                        }
                        self.saveUserInMap(with: blockUsers)
                    }
                }
            }
        }
    }
    
    func getAllBlockUsers() -> [IMUserModel] {
        let blockUsers = Array(self.contactMap.values).filter {self.blockList.contains($0.showId)}
        return blockUsers
    }
    
    func addBlockList(address: [String], completionBlock: NormalHandler?) {
        HttpConnect.shared().addBlockList(address: address) { (response) in
            if response.success  {
                let blockUsers = Array(self.contactMap.values).filter {address.contains($0.showId)}
                blockUsers.forEach { $0.isBlocked = true }
                self.saveUserInMap(with: blockUsers)
                self.blockList = self.blockList + address
            }
            completionBlock?(response)
        }
    }
    func deleteBlockList(address: [String], completionBlock: NormalHandler?) {
        HttpConnect.shared().deleteBlockList(address: address) { (response) in
            if response.success  {
                let contacts = Array(self.contactMap.values).filter {address.contains($0.showId)}
                contacts.forEach { $0.isBlocked = false }
                self.saveUserInMap(with: contacts)
                self.blockList = self.blockList.filter({ !address.contains($0)
                })
            }
            completionBlock?(response)
        }
    }
    
    //从好友数组中剔除好友
    func removeFriend(with friendId: String) {
        var friendSection : FriendSection?
        var removeIndex : Int?
        self.friendMap.forEach({ (section) in
            for (index, item) in section.friendArr.enumerated() {
                if item.userId == friendId {
                    removeIndex = index
                    friendSection = section
                }
            }
        })
        if let friendSection = friendSection {
            if let removeIndex = removeIndex {
                friendSection.friendArr.remove(at: removeIndex)
            }
            if friendSection.friendArr.count == 0 {
                self.friendMap = self.friendMap.filter { return $0 != friendSection }
            }
            IMNotifyCenter.shared().postMessage(event: .contactInfoChange(userId: friendId))
        }
    }
    
    
    
    //修改好友备注
    func editFriendRemark(with friendId: String, remark: String, completeBlock: NormalHandler?) {
        HttpConnect.shared().editFriendRemark(userId: friendId, remark: remark) { (response) in
            completeBlock?(response)
            guard response.success else { return }
            if let user = self.contactMap[friendId] {
                user.remark = remark
                self.removeFriend(with: friendId)
                self.saveUserInMap(with: [user])
                IMNotifyCenter.shared().postMessage(event: .contactInfoChange(userId: user.userId))
            }
        }
    }
    
    func editFriendExtRemark(with friendId: String, remark: String,tels: [[String:String]],des: String,pics:[String],completionBlock: NormalHandler?) {
        HttpConnect.shared().editFriendExtRemark(userId: friendId, remark: remark, tels: tels, des: des, pics: pics) { (response) in
            completionBlock?(response)
            guard response.success else { return }
            if let user = self.contactMap[friendId] {
                user.remark = remark
                self.removeFriend(with: friendId)
                self.saveUserInMap(with: [user])
                IMNotifyCenter.shared().postMessage(event: .contactInfoChange(userId: user.userId))
            }
        }
    }
    
    func editFriendEncryptExtRemark(with friendId: String, encryptRemark: String, encryptExt: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().editFriendEncryptExtRemark(userId: friendId, encryptRemark: encryptRemark, encryptExt: encryptExt) { (response) in
            completionBlock?(response)
            guard response.success else { return }
            if let user = self.contactMap[friendId] {
                self.removeFriend(with: friendId)
                self.saveUserInMap(with: [user])
                IMNotifyCenter.shared().postMessage(event: .contactInfoChange(userId: user.userId))
            }
        }
    }
    
    
    
    private var contactMap = [String: IMUserModel]()
    
    private(set) var friendMap = [FriendSection](){
        didSet{
            friendMapSubject.onNext(friendMap)
        }
    }
    
    let friendMapSubject = BehaviorSubject<[FriendSection]?>(value: nil)
    
    func getContact(userId: String) -> IMUserModel? {
        return self.contactMap[userId]
    }
    func getAllFriend() -> [IMUserModel] {
        var arr = [IMUserModel]() // 排序保持和friendMap一致
        friendMap.forEach { arr = arr + $0.friendArr }
        return arr
    }
    
    //平时获取用户信息，如果上次请求不是今天会更新
    private let userInfoQueue = DispatchQueue(label: "com.requestUserInfo",attributes: .concurrent)
    func requestUserModel(with userId: String, completeBlock: UserModelBlock?) {
        guard userId.count > 0 else { return }
        userInfoQueue.async {
            if let model = self.contactMap[userId],
                model.requestDate.isToday {
                DispatchQueue.main.async {
                    completeBlock?(model, true, "")
                }
            } else {
                self.requestUserDetailInfo(with: userId, completeBlock: { (user, success, message) in
                    DispatchQueue.main.async {
                        completeBlock?(user, success, message)
                    }
                })
            }
        }
    }
    
    //请求详情更新本地用户信息
    func requestUserDetailInfo(with userId: String, completeBlock: UserModelBlock?) {
        HttpConnect.shared().getUserDetailInfo(userId: userId) { (user, response) in
            guard let user = user else {
                if let model = self.contactMap[userId] {
                    completeBlock?(model, false, response.message)
                }else {
                    completeBlock?(nil, false, response.message)
                }
                return
            }
            
            if let oldUser = self.contactMap[userId] {
                user.isFriend = oldUser.isFriend
                user.isBlocked = oldUser.isBlocked
            }
            completeBlock?(user,response.success,response.message)
            self.saveUserInMap(with: [user])
            IMNotifyCenter.shared().postMessage(event: .contactInfoChange(userId: userId))
        }
    }
    
    func updateUserPublicKey(userId: String, publicKey:String) {
        if let model = self.contactMap[userId] {
            model.publicKey = publicKey
            model.save()
        } else {
            self.requestUserDetailInfo(with: userId, completeBlock: nil)
        }
    }
    
    private func saveUserInMap(with list: [IMUserModel]) {
        list.forEach { (user) in
            self.contactMap.removeValue(forKey: user.userId)
            self.saveUser(with: user)
        }
        self.friendMap.sort { (section1, section2) -> Bool in
            return section1 < section2
        }
    }
    
    private func saveUser(with user: IMUserModel) {
        user.save()
        self.contactMap[user.userId] = user
        if user.isFriend {
            let titleKey = user.showName.findFirstLetterFromString()
            var friendSection : FriendSection?
            self.friendMap.forEach({ (section) in
                if section.titleKey == titleKey {
                    friendSection = section
                }
                section.friendArr = section.friendArr.filter({ $0.userId != user.userId })
            })
            if user.isDelete || user.isBlocked {
                if let friendSection = friendSection {
                    var removeIndex : Int?
                    for (index, item) in friendSection.friendArr.enumerated() {
                        if item.userId == user.userId {
                            removeIndex = index
                        }
                    }
                    if let removeIndex = removeIndex {
                        friendSection.friendArr.remove(at: removeIndex)
                    }
                    if friendSection.friendArr.count == 0 {
                        self.friendMap = self.friendMap.filter { return $0 != friendSection }
                    }
                }
            }else {
                if let friendSection = friendSection {
                    var haveIndex : Int?
                    for (index, item) in friendSection.friendArr.enumerated() {
                        if item.userId == user.userId {
                            haveIndex = index
                        }
                    }
                    if let haveIndex = haveIndex {
                        friendSection.friendArr[haveIndex] = user
                    }else{
                        friendSection.friendArr.append(user)
                    }
                    friendSection.friendArr.sort(by: <)
                }else {
                    let section = FriendSection(titleKey: titleKey, user: user)
                    self.friendMap.append(section)
                }
            }
        }
    }
    
    //好友设置免打扰
    func friendSetNoDisturbing(userId: String, on: Bool, completionBlock: NormalHandler?) {
        HttpConnect.shared().friendSetNoDisturbing(userId: userId, on: on) { (response) in
            completionBlock?(response)
            if let user = self.contactMap[userId] {
                user.noDisturbing = on ? .open : .close
                user.save()
                IMConversationManager.shared().friendSetNoDisturbing(friendId: userId, on: on)
            }
        }
    }
    //好友设置置顶
    func friendSetOnTop(userId: String, on: Bool, completionBlock: NormalHandler?) {
        HttpConnect.shared().friendSetOnTop(userId: userId, on: on) { (response) in
            completionBlock?(response)
            if let user = self.contactMap[userId] {
                user.onTop = on
                user.save()
                IMConversationManager.shared().friendSetOnTop(friendId: userId, on: on)
            }
        }
    }
    
    //入群申请处理
    func dealGroupApply(groupId: String, userId: String, agree: Bool, completionBlock: NormalHandler?) {
        HttpConnect.shared().dealGroupApply(groupId: groupId, userId: userId, agree: agree) { (response) in
            completionBlock?(response)
            self.refreshApplyNumber()
        }
    }
    
    //好友申请处理
    func dealFriendApply(userId: String, agree: Bool, completionBlock: NormalHandler?) {
        HttpConnect.shared().dealFriendApply(userId: userId, agree: agree) { (response) in
            completionBlock?(response)
            self.refreshApplyNumber()
        }
    }
    
    
    func refreshApplyNumber() {
        HttpConnect.shared().getUndealApplyNumber { (number, _) in
            guard let num = number else { return }
            self.applyNumber = num
        }
    }
    
    //获取用户组内信息
    private(set) var myGroupInfoMap = [String: IMGroupUserInfoModel]()
    private let userGroupInfoQueue = DispatchQueue(label: "com.requestUserGroupInfo", attributes:.concurrent)
    func requestUserGroupInfo(userId: String, groupId: String, completionBlock: UserGroupInfoModelBlock?) {
        guard let loginUser = IMLoginUser.shared().currentUser else { return }
        if loginUser.userId == userId {
            if let model = myGroupInfoMap[groupId], model.lastTime.isToday {
                completionBlock?(model, true, "")
            }else {
                self.getUserGroupInfo(userId: userId, groupId: groupId, completionBlock: completionBlock)
            }
        }else {
            self.requestUserModel(with: userId) { (user, _, message) in
                guard let user = user else {
                    completionBlock?(nil,false,message)
                    return
                }
                self.userGroupInfoQueue.async {
                    if let userGroupInfo = user.groupInfoList[groupId],
                        userGroupInfo.lastTime.isToday  {
                        DispatchQueue.main.async {
                            completionBlock?(userGroupInfo, true, "")
                        }
                    } else {
                        self.getUserGroupInfo(userId: userId, groupId: groupId, completionBlock: { (userGroupInfo, success, message) in
                            DispatchQueue.main.async {
                                completionBlock?(userGroupInfo, success, message)
                            }
                        })
                    }
                }
            }
        }
    }
    func getUserGroupInfo(userId: String, groupId: String, completionBlock: UserGroupInfoModelBlock?) {
        HttpConnect.shared().getGroupUserInfo(groupId: groupId, userId: userId) { (user, response) in
            completionBlock?(user,response.success,response.message)
            guard let user = user else { return }
            self.saveGroupMember(member: user, groupId: groupId)
        }
    }
    func saveGroupMember(member: IMGroupUserInfoModel, groupId: String) {
        guard let loginUser = IMLoginUser.shared().currentUser else { return }
        if loginUser.userId == member.userId {
            myGroupInfoMap[groupId] = member
        }else {
            self.requestUserModel(with: member.userId, completeBlock: { (contact, _, _) in
                guard let contact = contact else { return }
                if contact.name != member.nickname {
                    contact.name = member.nickname
                    IMNotifyCenter.shared().postMessage(event: .contactInfoChange(userId: member.userId))
                }
                contact.groupInfoList[groupId] = member
            })
        }
        IMNotifyCenter.shared().postMessage(event: .userGroupInfoChange(groupId: groupId, userId: member.userId))
    }
    
    //获取用户名和头像
    func getUsernameAndAvatar(with userId: String, groupId: String? = nil, completeBlock: UserNormalInfoBlock?) {
        guard let loginUser = IMLoginUser.shared().currentUser else { return }
        if loginUser.userId == userId {
            let avatar = loginUser.avatar
            var name = loginUser.userName
            if let groupId = groupId, groupId.count > 0 {
                self.requestUserGroupInfo(userId: userId, groupId: groupId, completionBlock: { (userGroupInfo, _, _) in
                    defer{
                        completeBlock?(userId,name,avatar)
                    }
                    guard let userGroupInfo = userGroupInfo else { return }
                    if userGroupInfo.groupNickname.count > 0 {
                        name = userGroupInfo.groupNickname
                    }
                })
            }else {
                completeBlock?(userId,name,avatar)
            }
        }else {
            self.requestUserModel(with: userId) { (user, _, _) in
                guard let user = user else { return }
                let avatar = user.avatar
                var name = user.showName
                if let groupId = groupId, groupId.count > 0, user.remark.count == 0 || !user.isFriend {
                    self.requestUserGroupInfo(userId: userId, groupId: groupId, completionBlock: { (userGroupInfo, _, _) in
                        defer{
                            completeBlock?(userId,name,avatar)
                        }
                        guard let userGroupInfo = userGroupInfo else { return }
                        if userGroupInfo.groupNickname.count > 0 {
                            name = userGroupInfo.groupNickname
                        }
                    })
                }else {
                    completeBlock?(userId,name,avatar)
                }
            }
        }
    }
}

class FriendSection: NSObject, Comparable {
    static func < (lhs: FriendSection, rhs: FriendSection) -> Bool {
        if lhs.titleKey == "#" {
            return false
        }
        if rhs.titleKey == "#" {
            return true
        }
        return lhs.titleKey < rhs.titleKey
    }
    
    static func == (lhs: FriendSection, rhs: FriendSection) -> Bool {
        return lhs.titleKey == rhs.titleKey
    }
    
    var titleKey = ""
    var friendArr = [IMUserModel]()
    
    override init() {
        super.init()
    }
    
    init(titleKey: String, user: IMUserModel) {
        self.titleKey = titleKey
        self.friendArr.append(user)
    }
    
    init(titleKey: String, users: [IMUserModel]) {
        self.titleKey = titleKey
        self.friendArr = users
    }
    
}


extension IMContactManager: UserInfoChangeDelegate {
    func userLogin() {
        self.refreshFriendList()
        self.refreshApplyNumber()
    }
    func userLogout() {
        self.contactMap.removeAll()
        self.friendMap.removeAll()
        self.myGroupInfoMap.removeAll()
        self.applyNumber = 0
    }
    func userInfoChange() {
        
    }
}

extension IMContactManager: AppActiveDelegate {
    func appEnterBackground() {
        
    }
    
    func appWillEnterForeground() {
        if IMLoginUser.shared().isLogin {
            self.refreshApplyNumber()
            self.refreshFriendList()
        }
    }
    
}
