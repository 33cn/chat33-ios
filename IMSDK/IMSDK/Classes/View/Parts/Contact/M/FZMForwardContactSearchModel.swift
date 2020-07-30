//
//  FZMForwardContactSearchModel.swift
//  IMSDK
//
//  Created by .. on 2019/9/25.
//

import UIKit

class FZMForwardContactSearchModel: NSObject {
    let isFriend: Bool
    let typeId: String
    let avatar: String
    let name: String
    let remark: String
    var isSelected = false
    var showName: String {
        return isFriend ? (remark.isEmpty ? name : remark) : name
    }
        
    init(isFriend: Bool, typeId: String , avatar: String, name: String, remark: String, msgs:[SocketMessage] = [SocketMessage]() ) {
        self.isFriend = isFriend
        self.typeId = typeId
        self.avatar = avatar
        self.name = name
        self.remark = remark
    }
    
    convenience init(friend: IMUserModel, isSelected: Bool) {
        self.init(isFriend: true, typeId: friend.userId ,avatar: friend.avatar, name: friend.name , remark: friend.remark)
        self.isSelected = isSelected
    }
    
    convenience init(group: IMGroupModel,isSelected: Bool) {
        self.init(isFriend: false, typeId: group.groupId, avatar: group.avatar, name: group.name , remark: "")
        self.isSelected = isSelected
    }
    
    static func < (lhs: FZMForwardContactSearchModel, rhs: FZMForwardContactSearchModel) -> Bool {
        return lhs.name < rhs.name
    }
}
