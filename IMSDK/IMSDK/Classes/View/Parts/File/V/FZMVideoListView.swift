//
//  FZMVideoListView.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit
import RxSwift
import MJRefresh

class FZMVideoListView: FZMScrollPageItemBaseView {
    private var dataSource = [[FZMVideoListVM]]()
    var isSelect = false
    var selectBlock: ((FZMVideoListVM,UIImageView)->())?
    private let conversationId: String
    private let conversationType: SocketChannelType
    private var startId = ""
    
    var videoAndImageMessageArr = [SocketMessage]()
    var videoListVMArr = [FZMVideoListVM]() {
        didSet {
            self.dataSource.removeAll()
            Array.init(Set.init(videoListVMArr.compactMap {$0.time})).sorted{$0 > $1}.forEach { (date) in
                self.dataSource.append(videoListVMArr.filter{$0.time == date})
            }
            self.refresh()
            self.noDataCover.isHidden = !self.dataSource.isEmpty
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.itemSize = CGSize.init(width: (ScreenWidth - 2 * 5) / 4 , height: (ScreenWidth - 2 * 5) / 4)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.headerReferenceSize = CGSize.init(width: 200, height: 30)
        let v = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        v.backgroundColor = FZM_BackgroundColor
        v.register(FZMVideoListCell.self, forCellWithReuseIdentifier: "FZMVideoListCell")
        v.register(FZMVideoListHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FZMVideoListHeaderView")
        if #available(iOS 11.0, *) {
            v.contentInsetAdjustmentBehavior = .never
        }
        v.delegate = self
        v.dataSource = self
        v.mj_footer = MJRefreshBackNormalFooter.init(refreshingBlock: {[weak self] in
            self?.loadData()
        })
        v.addSubview(noDataCover)
        noDataCover.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview().offset(-StatusNavigationBarHeight - 20)
            m.centerX.equalToSuperview()
        })
        return v
        
    }()
    
    lazy var noDataCover: UIImageView = {
        let v = UIImageView()
        v.image = GetBundleImage("file_novideo")
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        let lab = UILabel.getLab(font: UIFont.mediumFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "暂无图片/视频")
        v.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(v.snp.bottom).offset(20)
        })
        return v
    }()
    
    init(with pageTitle: String,conversationType: SocketChannelType,conversationId: String) {
        self.conversationType = conversationType
        self.conversationId = conversationId
        super.init(with: pageTitle)
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { (m) in
            m.top.equalToSuperview()
            m.bottom.equalToSuperview()
            m.left.equalToSuperview().offset(2)
            m.right.equalToSuperview().offset(-2)
        }
    }
    
    func loadData(more:Bool = false) {
        if !more {
            self.showProgress()
        }
        if conversationType == .group {
            FZMFileManager.shared().groupPhotosAndVideos(groupId: conversationId, startId: startId, number: 20) { (msgs, startId, response) in
                self.hideProgress()
                guard response.success == true else {
                    self.showToast(with: response.message)
                    return
                }
                self.processMsgs(msgs: msgs, startId: startId)
            }
        } else {
            FZMFileManager.shared().friendPhotosAndVideos(friendId: conversationId, startId: startId, number: 20) { (msgs, startId, response) in
                self.hideProgress()
                guard response.success == true else {
                    self.showToast(with: response.message)
                    return
                }
                self.processMsgs(msgs: msgs, startId: startId)
            }
        }
    }
    
    func processMsgs(msgs: [SocketMessage],startId: String) {
        self.startId = startId
        self.videoAndImageMessageArr += msgs
        self.videoListVMArr += msgs.sorted{$0 > $1}.compactMap{FZMVideoListVM.init(with: $0, autoDownloadFile: false, isNeedSaveMessage: false)}
        self.collectionView.mj_footer.endRefreshing()
        if msgs.count < 20 {
            self.collectionView.mj_footer.isHidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        self.collectionView.reloadData()
    }
    
    func edgeInset(_ edge: Bool) {
        self.collectionView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: edge ? 120 : 0 , right: 0)
    }
}
    
    

extension FZMVideoListView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !self.isSelect else {return}
        self.selectBlock?(self.dataSource[indexPath.section][indexPath.row],(collectionView.cellForItem(at: indexPath) as! FZMVideoListCell).contentImageView)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMVideoListCell", for: indexPath) as! FZMVideoListCell
        let vm = self.dataSource[indexPath.section][indexPath.row]
        vm.isShowSelect = self.isSelect
        cell.configure(with: vm)
        cell.selectBlock = {[weak self] (vm,imageview) in
            guard let strongSelf = self, !strongSelf.isSelect else {return }
            strongSelf.selectBlock?(vm,imageview)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FZMVideoListHeaderView", for: indexPath) as! FZMVideoListHeaderView
            header.label.text = self.dataSource[indexPath.section].first?.time
            return header
        }
        return UICollectionReusableView.init()
    }
}


class FZMVideoListHeaderView: UICollectionReusableView {
    let label = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.addSubview(label)
        label.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
