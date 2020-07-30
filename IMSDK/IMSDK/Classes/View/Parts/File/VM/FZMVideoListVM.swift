//
//  FZMVideoListVM.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit

class FZMVideoListVM: FZMVideoMessageVM {
    var isShowSelect: Bool = false
    var imageUrl = ""
    var imgData = Data()
    var time = ""
    var isCiphertext = false
    override init(with msg: SocketMessage, autoDownloadFile: Bool, isNeedSaveMessage: Bool) {
        super.init(with: msg, autoDownloadFile: autoDownloadFile, isNeedSaveMessage: isNeedSaveMessage)
        imageUrl = msg.body.imageUrl
        imgData = msg.body.imgData
        height = CGFloat(msg.body.height)
        width = CGFloat(msg.body.width)
        time = String.yyyyMMddDateString(with: msg.datetime)
        isCiphertext = !msg.body.ciphertext.isEmpty
    }
}
