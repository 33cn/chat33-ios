//
//  FZMSenderFileController.swift
//  IMSDK
//
//  Created by .. on 2019/2/26.
//

import UIKit

class FZMSenderFileController: FZMFileViewController {
    
    let owner: String
    let ownerName: String
    
    init(conversationType:SocketChannelType, conversationID:String,owner: String,ownerName: String) {
        self.ownerName = ownerName
        self.owner = owner
        super.init(conversationType: conversationType, conversationID: conversationID)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        self.title = ownerName + "发送的文件"
        super.viewDidLoad()
        let selectBtn = UIBarButtonItem.init(title: "选择", style: .done, target: self, action: #selector(selectFileOrCancel))
        self.navigationItem.rightBarButtonItems = [selectBtn]
    }
    
   
    
    override func createUI() {
        self.view1 = FZMFlieListView.init(with: "", conversationType: conversationType, conversationId: conversationID, owner: owner)
        self.view1?.loadData()
        if let view1 = self.view1 {
            let param = FZMSegementParam()
            param.headerHeight = 0
            let pageView = FZMScrollPageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight-StatusNavigationBarHeight), dataViews: [view1], param: param)
            self.view.addSubview(pageView)
        }
    }
    
}
