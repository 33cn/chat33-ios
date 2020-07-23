//
//  FZMWorkUser.swift
//  IMSDK
//
//  Created by .. on 2019/11/7.
//

import UIKit
import SwiftyJSON

enum FZMWorkUserStatus: String {
    case none = ""
    case notSignIn = "未签到"
    case notSignOut = "未签退"
    case signOut = "已签退"
}

enum FZMWorkUserTimeStatus: String {
    case none = ""
    case normal = "今日考勤正常"
    case abnormal = "今日考勤异常"
    case leaveEarly = "今日考勤早退"
}

class FZMWorkUser: NSObject {

    let name: String
    let company: String
    let code: String
    
    var workStatus: FZMWorkUserStatus {
        get {
            var didSignIn = false
            var didSignOut = false
            self.todayWorkRecords?.forEach({ (record) in
                if record.type == 1 {
                    didSignIn = true
                }
                if record.type == 2 {
                    didSignOut = true
                }
            })
            if !didSignIn, !didSignOut {
                return .notSignIn
            }
            if didSignIn, !didSignOut {
                return .notSignOut
            }
            if didSignIn, didSignOut {
                return .signOut
            }
            return .none
        }
    }
    
    var todayWorkRecords: [FZMWorkRecord]? = nil
    var todayWorkTimeStatus = FZMWorkUserTimeStatus.none
    
    init(name: String, company: String, code: String) {
        self.name = name
        self.company = company
        self.code = code
        super.init()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .appState)
        DispatchQueue.global().async {
            self.refreshTodayWorkRecord(completionBlock: nil)
        }
    }
    
    convenience init?(dic: [String: JSON]) {
        if let name = dic["name"]?.string,
            let company = dic["company"]?.string,
            let code = dic["code"]?.string {
            self.init(name: name, company: company, code: code)
        } else {
            return nil
        }
    }
    
    func mapToDic() -> [String: Any] {
        return ["name": name, "company": company, "code": code]
    }
    
    func getTodayWorkInfo(completionBlock: WorkRecordHandler?) {
        if let workRecords = self.todayWorkRecords {
            let response = HttpResponse.init()
            response.success = true
            completionBlock?(workRecords, response)
            self.refreshTodayWorkRecord(completionBlock: nil)
        } else {
            self.refreshTodayWorkRecord(completionBlock: completionBlock)
        }
    }
    
    
    func refreshTodayWorkRecord(completionBlock: WorkRecordHandler?) {
        HttpConnect.shared().refreshTodayWorkRecord { (response) in
            if response.success, let timeResult = response.data?["timeResult"].string, let records = response.data?["records"].array {
                if timeResult == "normal" {
                    self.todayWorkTimeStatus = .normal
                } else if timeResult == "abnormal" {
                    self.todayWorkTimeStatus = .abnormal
                } else if timeResult == "leave_early" {
                    self.todayWorkTimeStatus = .leaveEarly
                }
                var workRecords = [FZMWorkRecord]()
                records.forEach { (record) in
                    let record = FZMWorkRecord.init(json: record)
                    workRecords.append(record)
                }
                self.todayWorkRecords = workRecords
                completionBlock?(workRecords, response)
            }
            completionBlock?(nil,response)
        }
    }
}


extension FZMWorkUser: AppActiveDelegate {
    func appEnterBackground() {
        
    }
    
    func appWillEnterForeground() {
        self.refreshTodayWorkRecord(completionBlock: nil)
    }
    
}


class FZMWorkRecord: NSObject {
    let id: String
    var reason: String //外勤打卡原因，正常打卡为空
    let locationResult: String //Normal：范围内 Outside：范围外，外勤打卡时为这个值
    let datetime: Double //打卡时间
    let address: String
    let longitude: Double
    let latitude: Double
    let type: Int //1 签到 2 签退
    let state: String //为空字符串则审批通过，不为空则处于待审核等状态
    
    var isOnDuty: Bool {
        return self.type == 1
    }
    var isOffDuty: Bool {
        return self.type == 2
    }
    var isOffsite: Bool {
        return locationResult == "outside"
    }
    var isChecking: Bool {
        return !self.state.isEmpty
    }
    
    init(json: JSON) {
        let id = json["id"].stringValue
        let reason = json["reason"].stringValue
        let locationResult = json["locationResult"].stringValue
        let datetime = json["datetime"].doubleValue
        let address = json["location"]["address"].stringValue
        let longitude = json["location"]["longitude"].doubleValue
        let latitude = json["location"]["latitude"].doubleValue
        let type = json["type"].intValue
        let state = json["state"].stringValue
        
        self.id = id
        self.reason = reason
        self.locationResult = locationResult
        self.datetime = datetime
        self.address = address
        self.longitude = longitude
        self.latitude = latitude
        self.type = type
        self.state = state
        
        super.init()
    }
    
    
}
