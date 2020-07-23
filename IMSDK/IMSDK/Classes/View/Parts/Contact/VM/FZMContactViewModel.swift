//
//  FZMContactModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/9.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMContactViewModel: NSObject {
    
    var type : SocketChannelType = .person
    
    var contactId : String = ""
    
    var name = "" {
        didSet{
            infoSubject.onNext((name,avatar))
        }
    }
    
    var avatar = "" {
        didSet{
            infoSubject.onNext((name,avatar))
        }
    }
    
    var isSelected = false
    
    var infoSubject = BehaviorSubject<(String,String)>(value: ("",""))
    
    var user: IMUserModel?
    
    var isEncrypt = false
    
    private var identification = false {
        didSet {
            identificationSubject.onNext(identification)
        }
    }
    var identificationSubject = BehaviorSubject<(Bool)>(value: (false))
    
    var searchString: String? = nil
    
    var isBlocked = false
    
    override init() {
        super.init()
    }
    
    init(with user: IMUserModel) {
        super.init()
        contactId = user.userId
        type = .person
        name = user.showName
        avatar = user.avatar
        self.user = user
        self.isEncrypt = IMLoginUser.shared().currentUser?.isEncryptChatWithUser(user) ?? false
        infoSubject.onNext((name,avatar))
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .contact)
        identification = user.identification
        identificationSubject.onNext((identification))
        isBlocked = user.isBlocked
    }
    
    init(with group: IMGroupModel) {
        super.init()
        contactId = group.groupId
        type = .group
        name = group.name
        avatar = group.avatar
        IMConversationManager.shared().getGroup(with: contactId) { (model) in
            self.name = model.showName
            self.avatar = model.avatar
            self.isEncrypt = model.isEncryptGroup
            self.identification = model.identification
        }
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .group)
    }
    
}

extension FZMContactViewModel: ContactInfoChangeDelegate{
    func contactUserInfoChange(with userId: String) {
        if userId == self.contactId {
            IMContactManager.shared().requestUserModel(with: userId) { (user, _, _) in
                guard let user = user else { return }
                self.avatar = user.avatar
                self.name = user.showName
            }
        }
    }
}

extension FZMContactViewModel: GroupInfoChangeDelegate {
    func groupInfoChange(with groupId: String) {
        if groupId == self.contactId {
            IMConversationManager.shared().getGroup(with: groupId) { (model) in
                self.name = model.showName
                self.avatar = model.avatar
            }
        }
    }
}
