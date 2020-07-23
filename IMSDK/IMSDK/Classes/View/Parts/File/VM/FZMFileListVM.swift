//
//  FZMFileListVM.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit
import RxSwift
class FZMFileListVM: FZMFileMessageVM {
    var isShowSelect: Bool = false
    var time = ""
    var isCiphertext = false
    override init(with msg: SocketMessage, autoDownloadFile: Bool, isNeedSaveMessage: Bool) {
        super.init(with: msg, autoDownloadFile: autoDownloadFile, isNeedSaveMessage: isNeedSaveMessage)
        time = String.yyyyMMddDateString(with: msg.datetime)
        isCiphertext = !msg.body.ciphertext.isEmpty
    }
}


