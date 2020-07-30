//
//  IMOSSClient.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import AliyunOSSiOS

var OSS_End_Point = ""
var OSS_Access_Key = ""
var OSS_Access_Secret = ""
var OSS_Buket = ""

typealias OSSFileUploadHandler = (String?, Bool) -> ()

typealias OSSFileDownloadHandler = (Data?, Bool) -> ()

typealias OSSProgressHandler = (Float) -> ()

public class IMOSSClient: NSObject {
    
    enum UploadType {
        case image
        case video
        case voice
        case file
    }
    
    let client : OSSClient
    private static let sharedInstance = IMOSSClient()
    private override init() {
        #if DEBUG
        OSSLog.enable()
        #endif
        let credential = OSSCustomSignerCredentialProvider.init { (contentToSign, error) -> String? in
            let signature : String = OSSUtil.calBase64Sha1(withData: contentToSign, withSecret: OSS_Access_Secret)
            return "OSS \(OSS_Access_Key):\(signature)"
        }
        client = OSSClient.init(endpoint: OSS_End_Point, credentialProvider: credential!)
        super.init()
    }
    class func shared() -> IMOSSClient {
        return sharedInstance
    }
    
    class func launchClient() {
        _ = self.shared()
    }
    
    func download(with fileUrl : URL , downloadProgressBlock : OSSProgressHandler? , callBack: OSSFileDownloadHandler?){
        let get = OSSGetObjectRequest.init()
        get.bucketName = OSS_Buket
        var path = fileUrl.path
        if let first = path.first,first == "/" {
            let index = path.index(path.startIndex, offsetBy: 1)
            path = String(path[index...])
        }
        get.objectKey = path
        get.downloadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            if totalBytesExpectedToSend > 0 {
                downloadProgressBlock?(Float(totalBytesSent)/Float(totalBytesExpectedToSend))
            }
        }
        let task = client.getObject(get)
        task.continue ({(backTask) -> Any? in
            var downloadData : Data?
            defer{
                DispatchQueue.main.async {
                    callBack?(downloadData, !(downloadData == nil))
                }
            }
            if backTask.error == nil {
                guard let result = backTask.result as? OSSGetObjectResult else {
                    return nil
                }
                downloadData = result.downloadedData
            }
            return nil
        })
    }
    
    func getUploadPath(uploadType: UploadType, ofType fileType: String, isEncryptFile: Bool = false) -> String {
        var typeDirectory = ""
        switch uploadType {
        case .image:
            typeDirectory = "picture"
        case .video:
            typeDirectory = "video"
        case .voice:
            typeDirectory = "voice"
        case .file:
            typeDirectory = "file"
        }
        let date = Date.init()
        let formatter = DateFormatter.init()
        formatter.dateFormat = "YYYYMMdd"
        let str1 = formatter.string(from: date)
        formatter.dateFormat = "YYYYMMddhhmmssSSS"
        let str2 = formatter.string(from: date)
        let uid = IMLoginUser.shared().userId
        let random = Int.random(in: 0...1000000)
        if isEncryptFile {
            return "chatList/\(typeDirectory)/\(str1)/$ENC$\(str2)_\(random)_\(uid).\(fileType)"
        }
        return "chatList/\(typeDirectory)/\(str1)/\(str2)_\(random)_\(uid).\(fileType)"
    }
    
    //上传图片
    func uploadImage(file: Data, toServerPath serverPath: String? = nil, uploadProgressBlock : OSSProgressHandler? , callBack: OSSFileUploadHandler?) {
        let serverPath = serverPath ?? self.getUploadPath(uploadType: .image, ofType: "jpg")
        let put = OSSPutObjectRequest.init()
        put.bucketName = OSS_Buket
        put.objectKey = serverPath
        put.uploadingData = file
        put.uploadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            if totalBytesExpectedToSend > 0 {
                uploadProgressBlock?(Float(totalBytesSent)/Float(totalBytesExpectedToSend))
            }
        }
        let task = client.putObject(put)
        task.continue ({(backTask) -> Any? in
            var coverPath : String?
            defer{
                DispatchQueue.main.async {
                    callBack?(coverPath, coverPath != nil)
                }
            }
            if backTask.error == nil {
                let useTask = self.client.presignPublicURL(withBucketName: OSS_Buket, withObjectKey: serverPath)
                coverPath = useTask.result as? String
            }
            return nil
        })
    }
    
    //上传音频，目前只支持AMR格式
    func uploadVoice(file: Data, toServerPath serverPath: String? = nil, uploadProgressBlock : OSSProgressHandler? , callBack: OSSFileUploadHandler?) {
        let serverPath = serverPath ?? self.getUploadPath(uploadType: .voice, ofType: "arm")
        let put = OSSPutObjectRequest.init()
        put.bucketName = OSS_Buket
        put.objectKey = serverPath
        put.uploadingData = file
        put.uploadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            if totalBytesExpectedToSend > 0 {
                uploadProgressBlock?(Float(totalBytesSent/totalBytesExpectedToSend))
            }
        }
        let task = client.putObject(put)
        task.continue ({(backTask) -> Any? in
            var coverPath : String?
            defer{
                DispatchQueue.main.async {
                    callBack?(coverPath, coverPath != nil)
                }
            }
            if backTask.error == nil {
                let useTask = self.client.presignPublicURL(withBucketName: OSS_Buket, withObjectKey: serverPath)
                coverPath = useTask.result as? String
            }
            return nil
        })
    }
    
    func uploadVideo(filePath: String, toServerPath serverPath: String? = nil, uploadProgressBlock : OSSProgressHandler? , callBack: OSSFileUploadHandler?) {
        let serverPath = serverPath ?? self.getUploadPath(uploadType: .video, ofType: (filePath as NSString).components(separatedBy: ".").last ?? "mp4")
        self.resumableUpload(filePath: filePath, toServerPath: serverPath, uploadProgressBlock: uploadProgressBlock, callBack: callBack)
    }
    
    func uploadFile(filePath:String, toServerPath serverPath: String? = nil, uploadProgressBlock : OSSProgressHandler? , callBack: OSSFileUploadHandler?) {
        let serverPath = serverPath ?? self.getUploadPath(uploadType: .file, ofType: (filePath as NSString).components(separatedBy: ".").last ?? "")
        self.resumableUpload(filePath: filePath, toServerPath: serverPath, uploadProgressBlock: uploadProgressBlock, callBack: callBack)
    }
    
    func resumableUpload(filePath:String, toServerPath serverPath: String,uploadProgressBlock : OSSProgressHandler? , callBack: OSSFileUploadHandler?) {
        let resumableUpload = OSSResumableUploadRequest.init()
        resumableUpload.bucketName = OSS_Buket
        resumableUpload.objectKey = serverPath
        resumableUpload.uploadingFileURL = URL.init(fileURLWithPath: filePath)
        resumableUpload.uploadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            if totalBytesExpectedToSend > 0 {
                uploadProgressBlock?(Float(totalBytesSent/totalBytesExpectedToSend))
            }
        }
        if let cachesDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            resumableUpload.recordDirectoryPath = cachesDir
        }
        let resumeTask = client.resumableUpload(resumableUpload)
        resumeTask.continue ({ (backTask) -> Any? in
            var coverPath : String?
            defer{
                DispatchQueue.main.async {
                    callBack?(coverPath, coverPath != nil)
                }
            }
            if backTask.error == nil {
                let useTask = self.client.presignPublicURL(withBucketName: OSS_Buket, withObjectKey: serverPath)
                coverPath = useTask.result as? String
            }
            return nil
        })
    }
    
}



