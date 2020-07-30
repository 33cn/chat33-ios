//
//  FZMBlacklistVC.swift
//  IMSDK
//
//  Created by .. on 2019/10/16.
//

import UIKit

class FZMBlacklistVC: FZMBaseViewController {

    private lazy var blacklistView: FZMFriendContactListView  = {
        let v = FZMFriendContactListView.init(with: "", isBlacklist: true)
        v.selectBlock = {[weak self] (model) in
            guard let _ = self else { return }
            FZMUIMediator.shared().pushVC(.friendInfo(friendId: model.contactId, groupId: nil, source: nil))
        }
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "黑名单"
        
        self.view.addSubview(blacklistView)
        blacklistView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.blacklistView.reloadBlacklist()
    }

}
