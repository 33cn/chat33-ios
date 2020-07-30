//
//  FZMForwardSelectContactVC.swift
//  IMSDK
//
//  Created by 吴文拼 on 2019/1/8.
//

import UIKit
import Photos

typealias SelectContactBlock = ([FZMContactViewModel])->()

class FZMForwardSelectContactVC: FZMBaseViewController {
    var autoSendMsgType: ForwardSendType?
    var forwordMsg: SocketMessage?
    var completeBlock : SelectContactBlock?
    

    lazy var selectView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.itemSize = CGSize(width: 35, height: 35)
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.clear
        view.showsHorizontalScrollIndicator = false
        view.register(FZMGroupUserCell.self, forCellWithReuseIdentifier: "FZMGroupUserCell")
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    private var selectArr = [FZMContactViewModel]()
    
    private lazy var numberLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_TintColor, textAlignment: .center, text: nil)
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "发送")
        btn.addTarget(self, action: #selector(commitInfo), for: .touchUpInside)
        return btn
    }()
    
    lazy var leftBtn: UIButton = {
        let btn = UIButton.init()
        btn.addTarget(self, action: #selector(dismissPage), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(self.navTintColor, for: .normal)
        btn.setTitleColor(self.navTintColor, for: .highlighted)
        return btn
    }()
    
    private let friendArrayForSearch = IMContactManager.shared().getAllFriend()
    private let groupArrayForSearch = IMConversationManager.shared().groupList
        
    private var dataSource = [[FZMForwardContactSearchModel]]()
    private var searchString: String?
    
    private lazy var searchTableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 50
        view.register(FZMForwardContactSearchCell.self, forCellReuseIdentifier: "FZMForwardContactSearchCell")
        view.separatorColor = FZM_LineColor
        view.keyboardDismissMode = .onDrag
        view.isHidden = true
        return view
    }()
    
    lazy var searchBlockView : UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: -100, width: ScreenWidth, height: StatusNavigationBarHeight))
        view.backgroundColor = FZM_BackgroundColor
        
        let circleView = UIView.init()
        circleView.layer.backgroundColor = FZM_LineColor.cgColor
        circleView.layer.cornerRadius = 20
        circleView.tintColor = FZM_GrayWordColor
        view.addSubview(circleView)
        circleView.snp.makeConstraints({ (m) in
            m.height.equalTo(40)
            m.left.equalToSuperview().offset(15)
            m.bottom.equalToSuperview()
            m.right.equalToSuperview().offset(-65)
        })
        
        let cancelBtn = UIButton.init(type: .custom)
        cancelBtn.enlargeClickEdge(10, 10, 10, 15)
        cancelBtn.setTitle("完成", for: .normal)
        cancelBtn.setTitleColor(FZM_TintColor, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.boldFont(16)
        cancelBtn.addTarget(self, action: #selector(hideSearchView), for: .touchUpInside)
        view.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints({ (m) in
            m.centerY.equalTo(circleView)
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 40, height: 25))
        })
        
        let imageV = UIImageView(image: GetBundleImage("tool_search")?.withRenderingMode(.alwaysTemplate))
        circleView.addSubview(imageV)
        imageV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(5)
            m.size.equalTo(CGSize(width: 17, height: 18))
        })
        circleView.addSubview(searchInput)
        searchInput.snp.makeConstraints({ (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalTo(imageV.snp.right).offset(10)
        })
        return view
    }()
    
    lazy var searchInput : UITextField = {
        let input = UITextField.init()
        input.tintColor = FZM_TintColor
        input.textAlignment = .left
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.attributedPlaceholder = NSAttributedString(string: "搜索好友或群聊", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
        input.returnKeyType = .search
        input.addTarget(self, action: #selector(textFiledEditChanged(_:)), for: .editingChanged)
        return input
    }()
    
     private lazy var noDataView: UIView = {
           let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight))
           v.isHidden = true
           v.backgroundColor = FZM_BackgroundColor
           var imgView = FZMNoDataView(image: GetBundleImage("nodata_search"), imageSize: CGSize(width: 250, height: 200), desText: "没有匹配的对象", btnTitle: nil, clickBlock: nil)
           v.addSubview(imgView)
           imgView.snp.makeConstraints({ (m) in
               m.top.equalToSuperview().offset(65)
               m.left.right.equalToSuperview()
               m.bottom.equalToSuperview()
           })
           return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.title ?? "转发"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftBtn)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: GetBundleImage("tool_search"), style: .plain, target: self, action: #selector(showSearchView))
        self.createUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           self.hideSearchView()
    }
    
    @objc func hideSearchView() {
        self.searchInput.text = nil
        self.searchString = nil
        self.searchInput.resignFirstResponder()
        self.searchTableView.isHidden = true
        
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBlockView.frame = CGRect.init(x: 0, y: -100, width: ScreenWidth, height: StatusNavigationBarHeight)
        }) { (_) in
            self.searchBlockView.removeFromSuperview()
        }
    }
    
    @objc func showSearchView() {
        UIApplication.shared.keyWindow?.addSubview(self.searchBlockView)
        self.searchInput.becomeFirstResponder()
        self.searchString = nil
        self.dataSource.removeAll()
        self.noDataView.removeFromSuperview()
        self.searchTableView.reloadData()
        self.searchTableView.isHidden = false
               
        UIView.animate(withDuration: 0.3) {
            self.searchBlockView.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: StatusNavigationBarHeight)
        }
    }
    
    @objc private func dismissPage() {
        self.navigationController?.dismiss(animated: true, completion: {
            
        })
    }
    
    
    let view1 = FZMFriendContactListView(with: "好友", .all)
    let view2 = FZMGroupContactListView(with: "群聊", true)
    let view3 = FZMPrivateAndGroupChatListView(with: "最近聊天", showSelect: true)
    
    private func createUI() {
        self.view.addSubview(selectView)
        selectView.snp.makeConstraints { (m) in
            m.left.equalToSuperview()
            m.top.equalToSuperview().offset(8)
            m.height.equalTo(35)
            m.right.equalToSuperview().offset(-60)
        }
        self.view.addSubview(numberLab)
        numberLab.snp.makeConstraints { (m) in
            m.right.equalToSuperview()
            m.left.equalTo(selectView.snp.right)
            m.top.bottom.equalTo(selectView)
        }
      
        view1.selectBlock = {[weak self, weak view3] (model) in
            view3?.selectOrDeselect(model: model)
            self?.deal(contact: model)
        }
        view2.selectBlock = {[weak self,weak view3] (model) in
            view3?.selectOrDeselect(model: model)
            self?.deal(contact: model)
        }
        view3.selectBlock = {[weak self] (socketConversationModel) in
            var model: FZMContactViewModel
            model = FZMContactViewModel.init()
            model.name = socketConversationModel.name
            model.contactId = socketConversationModel.conversationId
            model.avatar = socketConversationModel.avatar
            model.isSelected = socketConversationModel.isSelected
            model.isEncrypt = socketConversationModel.isEncrypt
            switch socketConversationModel.type {
            case .person:
                model.type = .person
            case .group:
                model.type = .group
            default:
                break
            }
            self?.view1.selectOrDeselect(model: model)
            self?.view2.selectOrDeselect(model: model)
            self?.deal(contact: model)
        }
        let view = FZMScrollPageView(frame: CGRect(x: 0, y: 53, width: ScreenWidth, height: ScreenHeight-StatusNavigationBarHeight - CGFloat(BottomOffset) - 53 - 70), dataViews: [view3,view1,view2])
        self.view.addSubview(view)
        
        let bottomBar = UIView()
        bottomBar.makeOriginalShdowShow()
        self.view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (m) in
            m.bottom.left.right.equalTo(self.safeArea)
            m.height.equalTo(70)
        }
        bottomBar.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth - 30 , height: 40))
        }
        
        self.view.addSubview(searchTableView)
        searchTableView.snp.makeConstraints { (m) in
            m.top.equalTo(selectView.snp.bottom).offset(10)
            m.left.right.bottom.equalToSuperview()
        }
    }
    
    private func deal(contact: FZMContactViewModel) {
        defer {
            self.numberLab.text = selectArr.count > 0 ? "\(selectArr.count)" : ""
        }
        if contact.isSelected {
            selectArr.append(contact)
            selectView.insertItems(at: [IndexPath(item: selectArr.count - 1, section: 0)])
        }else {
            for i in 0..<selectArr.count {
                if contact.contactId == selectArr[i].contactId {
                    selectArr.remove(at: i)
                    selectView.deleteItems(at: [IndexPath(item: i, section: 0)])
                    break
                }
            }
        }
    }
    
    @objc private func commitInfo() {
        guard selectArr.count > 0 else {
            return
        }
        if let type = self.autoSendMsgType {
            self.sendMsg(with: type)
        } else if let forwordMsg = self.forwordMsg {
            self.forward(msg: forwordMsg)
        } else {
            completeBlock?(selectArr)
        }
        self.dismissPage()
    }
    
    func forward(msg:SocketMessage) {
        var sendMsg: SocketMessage
        for contactModel in selectArr {
            sendMsg = msg.forwardMsg()
            sendMsg.targetId = contactModel.contactId
            sendMsg.fromId = IMLoginUser.shared().userId
            sendMsg.channelType = contactModel.type
            sendMsg.isEncryptMsg = contactModel.isEncrypt
            SocketChatManager.shared().sendMessage(with: sendMsg)
        }
        UIApplication.shared.keyWindow?.showToast(with: "发送成功")
    }
    
    func sendMsg(with type: ForwardSendType) {
        for contactModel in selectArr {
            switch type {
            case .image(let msgImage):
                guard let savePath = FZMLocalFileClient.shared().createFile(with: .jpg(fileName: String.getTimeStampStr())) else { return }
                let result = FZMLocalFileClient.shared().saveData(msgImage.jpegData(compressionQuality: 0.6)!, filePath: savePath)
                if result {
                    let msg = SocketMessage(image: msgImage, filePath: savePath.formatFileName(), from: IMLoginUser.shared().userId, to: contactModel.contactId, channelType: contactModel.type, isBurn: false,isEncryptMsg: contactModel.isEncrypt)
                    SocketChatManager.shared().sendMessage(with: msg)
                    UIApplication.shared.keyWindow?.showToast(with: "发送成功")
                }
            case .video(let videoPath):
                UIImage.getFirstFrame(URL.init(fileURLWithPath: videoPath)) { (image) in
                    DispatchQueue.main.async {
                        if let firstFrameImage = image {
                            let msg = SocketMessage.init(firstFrameImg: firstFrameImage, asset: PHAsset.init(), filePath: (videoPath as NSString).lastPathComponent, from: IMLoginUser.shared().userId, to: contactModel.contactId, channelType: contactModel.type, isBurn: false,isEncryptMsg: contactModel.isEncrypt)
                            SocketChatManager.shared().sendMessage(with: msg)
                            UIApplication.shared.keyWindow?.showToast(with: "发送成功")
                        }
                    }
                }
                
            default:
                break
            }
        }
    }

}

extension FZMForwardSelectContactVC {
    
    @objc func textFiledEditChanged(_ textField: UITextField) {
        if textField.markedTextRange == nil ||
            textField.markedTextRange?.isEmpty ?? false {
            if let text = textField.text {
                self.search(text)
            }
        }
    }
    
    private func search(_ text: String) {
        self.searchString = nil
        self.dataSource.removeAll()
        
        if text.isEmpty {
            self.noDataView.removeFromSuperview()
            self.searchTableView.reloadData()
            return
        }
        
        let selsetedFriendIds = self.selectArr.filter({ $0.type == .person}).compactMap { $0.contactId }
        let selsetedGroupIds = self.selectArr.filter({ $0.type == .group}).compactMap { $0.contactId }

        
        if noDataView.superview == nil {
            self.searchTableView.addSubview(noDataView)
        }
        let friendSearchModelList = self.friendArrayForSearch.filter { $0.name.lowercased().contains(text.lowercased()) || $0.remark.lowercased().contains(text.lowercased()) }.sorted(by: <).compactMap { return FZMForwardContactSearchModel.init(friend: $0, isSelected: selsetedFriendIds.contains($0.userId)) }.sorted(by: <)
        if !friendSearchModelList.isEmpty {
            self.dataSource.append(friendSearchModelList)
        }
        
        let groupSearchModelList = self.groupArrayForSearch.filter { $0.name.lowercased().contains(text.lowercased()) }.sorted(by: <).compactMap { return FZMForwardContactSearchModel.init(group: $0,isSelected:selsetedGroupIds.contains($0.groupId)) }.sorted(by: <)
        if !groupSearchModelList.isEmpty {
            self.dataSource.append(groupSearchModelList)
        }
                
        self.searchString = text
        self.searchTableView.reloadData()
        
    }
}

extension FZMForwardSelectContactVC: UITableViewDelegate, UITableViewDataSource {
    func getSecitonHeaderView(section: Int, title: String) -> UIView {
        let view = UIView()
        view.backgroundColor = FZM_BackgroundColor
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: title)
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(15)
            m.centerY.equalToSuperview()
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < self.dataSource.count, !self.dataSource[section].isEmpty else { return nil}
        let title = self.dataSource[section][0].isFriend ? "联系人" : "群聊"
        let v = self.getSecitonHeaderView(section: section, title: title)
        return v
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.noDataView.isHidden = !self.dataSource.isEmpty
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < self.dataSource.count else { return 0 }
        return self.dataSource[section].count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMForwardContactSearchCell", for: indexPath) as! FZMForwardContactSearchCell
        if indexPath.section < self.dataSource.count,
            indexPath.row < self.dataSource[indexPath.section].count {
            let model = self.dataSource[indexPath.section][indexPath.row]
            cell.searchString = self.searchString
            cell.configure(with: model)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < self.dataSource.count, indexPath.row < self.dataSource[indexPath.section].count else { return }
        let model = self.dataSource[indexPath.section][indexPath.row]
        model.isSelected = !model.isSelected
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        let contactModel = FZMContactViewModel.init()
        contactModel.name = model.name
        contactModel.contactId = model.typeId
        contactModel.avatar = model.avatar
        contactModel.type = model.isFriend ? .person : .group
        contactModel.isSelected = model.isSelected
        self.deal(contact: contactModel)
        self.view1.selectOrDeselect(model: contactModel)
        self.view2.selectOrDeselect(model: contactModel)
        self.view3.selectOrDeselect(model: contactModel)
    }
}

extension FZMForwardSelectContactVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMGroupUserCell", for: indexPath) as! FZMGroupUserCell
        cell.nameLab.isHidden = true
        cell.identificationImageView.snp.remakeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 10, height: 10))
            m.bottom.right.equalToSuperview()
        })
        let model = selectArr[indexPath.item]
        if model.type == .person {
            IMContactManager.shared().requestUserModel(with: model.contactId) { (user, _, _) in
                guard let user = user else { return }
                cell.headImageView.loadNetworkImage(with: user.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
                cell.identificationImageView.image = GetBundleImage("user_identification")
                cell.identificationImageView.isHidden = !user.identification
            }
        }else {
            IMConversationManager.shared().getGroup(with: model.contactId) { (group) in
                cell.headImageView.loadNetworkImage(with: group.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_group_head"))
                cell.identificationImageView.image = GetBundleImage("group_identification")
                cell.identificationImageView.isHidden = !group.identification
            }
        }
        
        return cell
    }
}
