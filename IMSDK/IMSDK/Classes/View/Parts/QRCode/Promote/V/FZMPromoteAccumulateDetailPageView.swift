
//
//  FZMPromoteDetailPageView.swift
//  IMSDK
//
//  Created by .. on 2019/7/9.
//

import UIKit
import MJRefresh

class FZMPromoteAccumulateDetailPageView: FZMPromoteDetailPageView {
    
    override init(with pageTitle: String) {
        super.init(with: pageTitle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadData(isMore: Bool = true) {
        HttpConnect.shared().accumulateInviteInfo(page: page, size: pageSize) { (response) in
            self.semaphore.wait()
            self.tableView.mj_header.endRefreshing()
            self.tableView.mj_footer.endRefreshing()
            if response.success, let list = response.data?["list"].arrayValue, !list.isEmpty {
                let array = list.compactMap({ (json) -> FZMPromoteDetailVM? in
                    return FZMPromoteDetailVM.init(accumulateData: FZMPromoteAccumulateDetail.init(json: json))
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
}

