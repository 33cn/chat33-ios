//
//  FZMPromoteDetailPageView.swift
//  IMSDK
//
//  Created by .. on 2019/7/9.
//

import UIKit
import MJRefresh

class FZMPromoteDetailPageView: FZMScrollPageItemBaseView {

    lazy var noDataCover: UIImageView = {
        let v = UIImageView()
        v.image = GetBundleImage("promote_no_data")
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        let lab = UILabel.getLab(font: UIFont.mediumFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "暂无记录")
        v.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(v.snp.bottom).offset(20)
        })
        return v
    }()
    
    
    lazy var tableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.separatorStyle = .none
        view.rowHeight = 90
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: DeviceIsFaceID ? 34 : 0))
        view.delegate = self
        view.dataSource = self
        view.register(FZMPromoteDetailCell.self, forCellReuseIdentifier: "FZMPromoteDetailCell")
        view.tableFooterView = UIView.init()
        view.addSubview(noDataCover)
        view.mj_footer = MJRefreshBackNormalFooter.init(refreshingBlock: {[weak self] in
            self?.loadMoreData()
        })
        view.mj_header = MJRefreshNormalHeader.init(refreshingBlock: {[weak self] in
            self?.reloadData()
        })
        noDataCover.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview().offset(-StatusNavigationBarHeight - 20)
            m.centerX.equalToSuperview()
        })
        return view
    }()
    
    override init(with pageTitle: String) {
        super.init(with: pageTitle)
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        self.loadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let semaphore = DispatchSemaphore.init(value: 1)
    
    var dataArray = Array<FZMPromoteDetailVM>.init()
    var page = 1
    let pageSize = 20
    
    func loadData(isMore: Bool = true) {
        HttpConnect.shared().singleInviteInfo(page: page, size: pageSize) { (response) in
            self.semaphore.wait()
            self.tableView.mj_header.endRefreshing()
            self.tableView.mj_footer.endRefreshing()
            if response.success, let list = response.data?["list"].arrayValue, !list.isEmpty {
                let array = list.compactMap({ (json) -> FZMPromoteDetailVM? in
                    return FZMPromoteDetailVM.init(data: FZMPromoteDetail.init(json: json))
                })
                self.tableView.mj_footer.isHidden = array.count < self.pageSize
                self.dataArray = isMore ? self.dataArray + array : array
                self.tableView.reloadData()
            } else {
                self.tableView.mj_footer.isHidden = true
            }
            self.semaphore.signal()
        }
    }
    
    func loadMoreData() {
        self.semaphore.wait()
        page = page + 1
        self.semaphore.signal()
        self.loadData()
    }
    
    func reloadData() {
        self.semaphore.wait()
        page = 1
        self.semaphore.signal()
        self.loadData(isMore: false)
    }
}

extension FZMPromoteDetailPageView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.noDataCover.isHidden = !dataArray.isEmpty
        return dataArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMPromoteDetailCell", for: indexPath) as! FZMPromoteDetailCell
        cell.configure(with: dataArray[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
