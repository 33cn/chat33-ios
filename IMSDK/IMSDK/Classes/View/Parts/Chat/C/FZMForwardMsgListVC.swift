//
//  FZMForwardMsgListVC.swift
//  AFNetworking
//
//  Created by 吴文拼 on 2019/1/10.
//

import UIKit


class FZMForwardMsgListVC: FZMBaseViewController {

    private let forwardMsg : SocketMessage
    private let forwardVM : FZMForwardMessageVM
    
    init(with forwardMsg: SocketMessage) {
        var showTimeMsg : SocketMessage?
        forwardMsg.body.forwardMsgs.forEach {[weak forwardMsg] (msg) in
            if let timeMsg = showTimeMsg {
                if timeMsg.datetime - msg.datetime > 600000 {
                    msg.showTime = true
                    showTimeMsg = msg
                } else {
                    msg.showTime = false
                }
            }else {
                msg.showTime = true
                showTimeMsg = msg
            }
            if let forwardMsg = forwardMsg {
                msg.fromKey = forwardMsg.fromKey
                msg.toKey = forwardMsg.toKey
                msg.keyId = forwardMsg.keyId
                msg.channelType = forwardMsg.channelType
                msg.isEncryptMsg = forwardMsg.isEncryptMsg
                msg.targetId = forwardMsg.targetId
                msg.fromId = forwardMsg.fromId
            }
        }
        self.forwardMsg = forwardMsg
        self.forwardVM = FZMForwardMessageVM(with: forwardMsg)
        super.init()
    }
    
    lazy var messageListView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.tableHeaderView = self.headerView
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.separatorStyle = .none
        view.rowHeight = UITableView.automaticDimension
        view.keyboardDismissMode = .onDrag
        view.delegate = self
        view.dataSource = self
        view.register(FZMTextMessageCell.self, forCellReuseIdentifier: "FZMTextMessageCell")
        view.register(FZMMineTextMessageCell.self, forCellReuseIdentifier: "FZMMineTextMessageCell")
        view.register(FZMVoiceMessageCell.self, forCellReuseIdentifier: "FZMVoiceMessageCell")
        view.register(FZMMineVoiceMessageCell.self, forCellReuseIdentifier: "FZMMineVoiceMessageCell")
        view.register(FZMImageMessageCell.self, forCellReuseIdentifier: "FZMImageMessageCell")
        view.register(FZMMineImageMessageCell.self, forCellReuseIdentifier: "FZMMineImageMessageCell")
        view.register(FZMRedbagMessageCell.self, forCellReuseIdentifier: "FZMRedbagMessageCell")
        view.register(FZMMineRedbagMessageCell.self, forCellReuseIdentifier: "FZMMineRedbagMessageCell")
        view.register(FZMTextRedbagMessageCell.self, forCellReuseIdentifier: "FZMTextRedbagMessageCell")
        view.register(FZMMineTextRedbagMessageCell.self, forCellReuseIdentifier: "FZMMineTextRedbagMessageCell")
        view.register(FZMImageMessageCell.self, forCellReuseIdentifier: "FZMImageMessageCell")
        view.register(FZMMineImageMessageCell.self, forCellReuseIdentifier: "FZMMineImageMessageCell")
        view.register(FZMSystemMessageCell.self, forCellReuseIdentifier: "FZMSystemMessageCell")
        view.register(FZMNotifyMessageCell.self, forCellReuseIdentifier: "FZMNotifyMessageCell")
        view.register(FZMForwardMessageCell.self, forCellReuseIdentifier: "FZMForwardMessageCell")
        view.register(FZMMineForwardMessageCell.self, forCellReuseIdentifier: "FZMMineForwardMessageCell")
        view.register(FZMVideoMessageCell.self, forCellReuseIdentifier: "FZMVideoMessageCell")
        view.register(FZMMineVideoMessageCell.self, forCellReuseIdentifier: "FZMMineVideoMessageCell")
        view.register(FZMFileMessageCell.self, forCellReuseIdentifier: "FZMFileMessageCell")
        view.register(FZMMineFileMessageCell.self, forCellReuseIdentifier: "FZMMineFileMessageCell")
        view.register(FZMDecryptFailedCell.self, forCellReuseIdentifier: "FZMDecryptFailedCell")
        view.register(FZMMineDecryptFailedCell.self, forCellReuseIdentifier: "FZMMineDecryptFailedCell")
        return view
    }()
    
    lazy var headerView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 50))
        view.addSubview(timeLab)
        timeLab.snp.makeConstraints({ (m) in
            m.center.equalToSuperview()
            m.height.equalTo(30)
        })
        let line1 = UIView.getNormalLineView()
        view.addSubview(line1)
        line1.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.right.equalTo(timeLab.snp.left).offset(-15)
            m.height.equalTo(1)
        })
        let line2 = UIView.getNormalLineView()
        view.addSubview(line2)
        line2.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.left.equalTo(timeLab.snp.right).offset(15)
            m.height.equalTo(1)
        })
        return view
    }()
    
    lazy var timeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = forwardVM.title
        self.view.addSubview(messageListView)
        messageListView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        
        guard let first = forwardVM.forwardMsgs.first, let last = forwardVM.forwardMsgs.last else { return }
        var showTimeMsg = first
        forwardVM.forwardMsgs.forEach { (msg) in
            if fabs(showTimeMsg.datetime - msg.datetime) > 600000 {
                msg.showTime = true
                showTimeMsg = msg
            } else {
                msg.showTime = false
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let firstTimeStr = dateFormatter.string(from: Date(timeIntervalSince1970: first.datetime / 1000))
        let lastTimeStr = dateFormatter.string(from: Date(timeIntervalSince1970: last.datetime / 1000))
        if firstTimeStr == lastTimeStr {
            timeLab.text = firstTimeStr
        }else {
            timeLab.text = "\(firstTimeStr) ~ \(lastTimeStr)"
        }
        self.messageListView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.forwardMsg.save()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FZMForwardMsgListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forwardVM.forwardMsgs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = forwardVM.forwardMsgs[indexPath.row]
        let vm = FZMMessageBaseVM.constructForwardVM(with: message)
        vm.msgId = "\(indexPath.row)"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: vm.identify, for: indexPath) as? FZMBaseMessageCell else {
            return UITableViewCell()
        }
        cell.configure(with: vm)
        cell.actionDelegate = self
        return cell
    }
}

extension FZMForwardMsgListVC: CellActionProtocol {
    
    func openFile(msgId: String, filePath: String, fileName: String) {
        let filePath = FZMLocalFileClient.shared().getFilePath(with: .file(fileName: filePath.lastPathComponent()))
        self.previewDocument(url:URL.init(fileURLWithPath: filePath),name:fileName)
    }
    
    func playVideo(msgId: String, videlPath: String) {
        let playerVC = FZMVideoPlayerController.init(videoPath: FZMLocalFileClient.shared().getFilePath(with: .video(fileName: (videlPath as NSString).lastPathComponent)))
        self.present(playerVC, animated: true, completion: nil)
    }
    
    
    func showMenu(in targetView: UIView, msgId: String) {
        guard let index = Int(msgId) else { return }
        let selectMsg = forwardVM.forwardMsgs[index]
        guard selectMsg.msgType != .image else { return }
        UIPasteboard.general.string = selectMsg.body.content
        self.showToast(with: "复制成功")
    }
    
    func browserImage(from imageView: UIImageView, msgId: String) {
        guard let selectIndex = Int(msgId) else { return }
        let msgList = forwardVM.forwardMsgs.filter { (msg) -> Bool in
            return msg.msgType == .image
        }
        let newMsgList = msgList.filter { (msg) -> Bool in
            return msg.snap == .none || (msg.snap == .burn && msg.direction == .send)
        }
        guard !newMsgList.isEmpty else {return}
        var selectMsg = newMsgList.first!
        if selectIndex > 0 && selectIndex < forwardVM.forwardMsgs.count {
            selectMsg = forwardVM.forwardMsgs[selectIndex]
        }
        self.present(FZMPhotoBrowser.init(msg: selectMsg, msgList: newMsgList, from: imageView), animated: true, completion: nil)
    }
    
    func clickLuckyPacket(msgId: String) {
        
    }
    
    func reSendMessage(msgId: String) {
        
    }
    
    func clickUserHeadImage(userId: String) {
        
    }
    
    func playVoice(msgId: String) {
        
    }
    
    func burnAfterMessage(msgId: String) {
        
    }
    
    func shouldBurnData(msgId: String) {
        
    }
    
    func forwardMessageDetail(msgId: String) {
        
    }
    
    func forwardSelectMessage(msgId: String) -> Bool {
        return false
    }
    
    func decryptFailedCellClick(msgId: String) {
//        FZMUIMediator.shared().pushVC(.goImportSeed)
    }
    
    func inviteGroupCellClick(msgId: String, inviterId: String, inviteGroupId: String, inviteMarkId: String) {
        
    }
    
    func longTapOnHeaderImageView(msgId: String) {
        
    }
    
    
}
