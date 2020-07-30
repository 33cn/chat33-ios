//
//  FZMFlieListView.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit
import RxSwift
import MJRefresh

class FZMFlieListView: FZMScrollPageItemBaseView {
    
    private let disposeBag = DisposeBag()
    var isSelect = false
    var selectBlock: ((FZMFileListVM)->())?
    var senderLabBlock: ((FZMFileListVM)->())?
    var searchText = "" {
        didSet {
            self.startId = ""
            self.fileMessagArr.removeAll()
            self.fileListVMArr.removeAll()
            self.loadData()
        }
    }
    private var startId = ""
    private let conversationId: String
    private let conversationType: SocketChannelType
    private let owner: String
    private lazy var tableView: UITableView = {
        let v = UITableView.init(frame: CGRect.zero, style: .plain)
        v.keyboardDismissMode = .onDrag
        v.backgroundColor = FZM_BackgroundColor
        v.rowHeight = 80
        v.register(FZMFileListCell.self, forCellReuseIdentifier: "FZMFileListCell")
        v.separatorColor = FZM_LineColor
        v.mj_footer = MJRefreshBackNormalFooter.init(refreshingBlock: {[weak self] in
            self?.loadData(more: true)
        })
        v.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: CGFloat(BottomOffset)))
        if #available(iOS 11.0, *) {
            v.contentInsetAdjustmentBehavior = .never
        }
        v.addSubview(noDataCover)
        noDataCover.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview().offset(-StatusNavigationBarHeight - 20)
            m.centerX.equalToSuperview()
        })
        return v
    }()
    lazy var noDataCover: UIImageView = {
        let v = UIImageView()
        v.image = GetBundleImage("file_nofile")
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        let lab = UILabel.getLab(font: UIFont.mediumFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "暂无文件")
        v.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(v.snp.bottom).offset(20)
        })
        return v
    }()
    var fileMessagArr = [SocketMessage]()
    private let listSubject = BehaviorSubject<[FZMFileListVM]>(value: [])
    var fileListVMArr = [FZMFileListVM]() {
        didSet {
            DispatchQueue.main.async {
                self.listSubject.onNext(self.fileListVMArr)
                self.noDataCover.isHidden = !self.fileListVMArr.isEmpty
            }
        }
    }
    init(with pageTitle: String,conversationType: SocketChannelType,conversationId: String,owner: String = "") {
        self.conversationType = conversationType
        self.conversationId = conversationId
        self.owner = owner
        super.init(with: pageTitle)
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        bindTableView()
    }
    
    func loadData(more:Bool = false) {
        if !more {
            self.showProgress()
        }
        if conversationType == .group {
            FZMFileManager.shared().groupFiles(groupId: conversationId, startId: startId, number: 20, query: searchText, owner: owner) { (msgs, startId, response) in
                self.hideProgress()
                guard response.success == true else {
                    self.showToast(with: response.message)
                    return
                }
                self.startId = startId
                self.fileMessagArr += msgs
                self.fileListVMArr += msgs.sorted{$0 > $1}.compactMap{
                    FZMFileListVM.init(with: $0, autoDownloadFile: false, isNeedSaveMessage: false)}
                self.hideProgress()
                self.tableView.mj_footer.endRefreshing()
                self.tableView.mj_footer.isHidden = msgs.count < 20
            }
        } else {
            FZMFileManager.shared().friendFiles(friendId: conversationId, startId: startId, number: 20, query: searchText, owner: owner) {  (msgs, startId, response) in
                self.hideProgress()
                guard response.success == true else {
                    self.showToast(with: response.message)
                    return
                }
                self.startId = startId
                self.fileListVMArr += msgs.sorted{$0 > $1}.compactMap{FZMFileListVM.init(with: $0, autoDownloadFile: false, isNeedSaveMessage: false)}
                self.hideProgress()
                self.tableView.mj_footer.endRefreshing()
                self.tableView.mj_footer.isHidden = msgs.count < 20
            }
        }
    }
    
    private func bindTableView() {
        listSubject.bind(to: tableView.rx.items(cellIdentifier: "FZMFileListCell", cellType:FZMFileListCell.self )) {[weak self] (row, element, cell) in
            element.isShowSelect = self?.isSelect ?? false
            cell.configure(with: element)
            cell.senderLabBlock = self?.senderLabBlock
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(FZMFileListVM.self).subscribe { [weak self] (event) in
            guard let strongSelf = self,!strongSelf.isSelect, case .next(let model) = event else { return }
            if let haveFile = FZM_UserDefaults.value(forKey: model.fileUrl) as? String, !haveFile.isEmpty {
                strongSelf.selectBlock?(model)
            } else if model.isCiphertext {
                let alert = FZMAlertView.init(onlyAlert: "无法解密的文件，可前往安全管理导入以前的助记词查看！", confirmBlock: nil)
                alert.show()
            } else {
                model.downloadFile()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        self.tableView.reloadData()
    }
    
    func edgeInset(_ edge: Bool) {
        self.tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: edge ? 120 : 0 , right: 0)
    }
    
}
