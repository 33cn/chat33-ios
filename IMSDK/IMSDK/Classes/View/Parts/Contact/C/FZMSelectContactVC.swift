//
//  FZMSelectContactVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/9.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import Photos

class FZMSelectContactVC: FZMBaseViewController {

//    let msgImage : UIImage
    let type:ForwardSendType
    init(with type: ForwardSendType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var contactArr = [FZMContactSection]()
    lazy var tableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 50
        view.register(FZMContactCell.self, forCellReuseIdentifier: "FZMContactCell")
        view.separatorColor = FZM_LineColor
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "发送给"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(dismissClick))
        self.createUI()
        
    }
    
    @objc func dismissClick() {
        self.navigationController?.dismiss(animated: true, completion: {
            
        })
    }
    
    private func createUI() {
        self.view.addSubview(self.tableView)
        tableView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        var arr = [FZMContactSection]()
        var map = [String:FZMContactSection]()
        IMContactManager.shared().friendMap.forEach { (friendSection) in
            friendSection.friendArr.forEach({ (user) in
                let title = user.showName.findFirstLetterFromString()
                if let section = map[title] {
                    section.contactArr.append(FZMContactViewModel(with: user))
                }else {
                    let contactSection = FZMContactSection(titleKey: title, contact: FZMContactViewModel(with: user))
                    arr.append(contactSection)
                    map[title] = contactSection
                }
            })
        }
        IMConversationManager.shared().groupList.forEach { (group) in
            let title = group.name.findFirstLetterFromString()
            if let section = map[title] {
                section.contactArr.append(FZMContactViewModel(with: group))
            }else {
                let contactSection = FZMContactSection(titleKey: title, contact: FZMContactViewModel(with: group))
                arr.append(contactSection)
                map[title] = contactSection
            }
        }
        self.contactArr = arr.sorted(by: <)
        
        self.tableView.reloadData()
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

extension FZMSelectContactVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 20))
        view.backgroundColor = FZM_BackgroundColor
        let contactSection = self.contactArr[section]
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: contactSection.titleKey)
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.top.bottom.equalToSuperview()
            m.left.equalToSuperview().offset(20)
        }
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.contactArr.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let contactSection = self.contactArr[section]
        return contactSection.contactArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMContactCell", for: indexPath) as! FZMContactCell
        let contactSection = self.contactArr[indexPath.section]
        let vm = contactSection.contactArr[indexPath.row]
        cell.configure(with: vm)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contactSection = self.contactArr[indexPath.section]
        let vm = contactSection.contactArr[indexPath.row]
        switch type {
        case .image(let msgImage):
            guard let savePath = FZMLocalFileClient.shared().createFile(with: .jpg(fileName: String.getTimeStampStr())) else { return }
            let result = FZMLocalFileClient.shared().saveData(msgImage.jpegData(compressionQuality: 0.6)!, filePath: savePath)
            if result {
                let msg = SocketMessage(image: msgImage, filePath: savePath.formatFileName(), from: IMLoginUser.shared().userId, to: vm.contactId, channelType: vm.type, isBurn: false)
                SocketChatManager.shared().sendMessage(with: msg)
                UIApplication.shared.keyWindow?.showToast(with: "发送成功")
                self.dismissClick()
            }
        case .video(let videoPath):
            UIImage.getFirstFrame(URL.init(fileURLWithPath: videoPath)) { (image) in
                DispatchQueue.main.async {
                    if let firstFrameImage = image {
                        let msg = SocketMessage.init(firstFrameImg: firstFrameImage, asset: PHAsset.init(), filePath: (videoPath as NSString).lastPathComponent, from: IMLoginUser.shared().userId, to: vm.contactId, channelType: vm.type, isBurn: false)
                        SocketChatManager.shared().sendMessage(with: msg)
                        UIApplication.shared.keyWindow?.showToast(with: "发送成功")
                        self.dismissClick()
                    }
                }
            }
            
        default:
            break
        }
        
    }
}


class FZMContactSection: NSObject, Comparable {
    static func < (lhs: FZMContactSection, rhs: FZMContactSection) -> Bool {
        if lhs.titleKey == "#" {
            return false
        }
        if rhs.titleKey == "#" {
            return true
        }
        return lhs.titleKey < rhs.titleKey
    }
    
    static func == (lhs: FZMContactSection, rhs: FZMContactSection) -> Bool {
        return lhs.titleKey == rhs.titleKey
    }
    
    var titleKey = ""
    var contactArr = [FZMContactViewModel]()
    init(titleKey: String, contact: FZMContactViewModel) {
        self.titleKey = titleKey
        self.contactArr.append(contact)
    }
}
