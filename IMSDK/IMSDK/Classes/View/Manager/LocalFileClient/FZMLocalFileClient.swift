//
//  FZMLocalFileClient.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/12.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

public enum FileFormatterType {
    case amr(fileName: String)
    case wav(fileName: String)
    case jpg(fileName: String)
    case png(fileName: String)
    case video(fileName: String)
    case file(fileName: String)
    
    var path: String{
        var usePath : String
        switch self {
        case .amr(let useStr):
            usePath = useStr + ".amr"
        case .wav(let useStr):
            usePath = useStr + ".wav"
        case .jpg(let useStr):
            usePath = useStr + ".jpg"
        case .png(let useStr):
            usePath = useStr + ".png"
        case .video(let useStr):
            usePath = useStr
        case .file(let useStr):
            usePath = useStr
        }
        return usePath
    }
}

//音频文件存放
private let voicePath = DocumentPath + "Voice"
//wav音频文件
private let wavPath = voicePath + "/WavFile"
//amr音频文件
private let amrPath = voicePath + "/AmrFile"

//图片文件
private let imagePath = DocumentPath + "/Image"
//jpg图片
private let jpgPath = imagePath + "/JpgFile"
//png图片
private let pngPath = imagePath + "/PngFile"

//视频文件
private let videoPath = DocumentPath + "Video"

private let FilePath = DocumentPath + "File"


private let pathArr = [voicePath,wavPath,amrPath,imagePath,jpgPath,pngPath]

public class FZMLocalFileClient: NSObject {

    private static let sharedInstance = FZMLocalFileClient()
    
    private let fileManager = FileManager.default
    
    private override init() {
        super.init()
        pathArr.forEach { (path) in
            self.createFolder(with: path)
        }
    }
    
    func createFolder(with path : String) {
        let exist = fileManager.fileExists(atPath: path)
        if exist {
            IMLog("存在\(path)")
        }else {
            IMLog("不存在\(path)")
            //不存在则创建
            try!fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public class func shared() -> FZMLocalFileClient {
        return sharedInstance
    }
    
    class func launchClient() {
        _ = self.shared()
    }
    
    
    func getFilePath(with fileName: FileFormatterType) -> String {
        var folderPath : String
        switch fileName {
        case .amr:
            folderPath = amrPath
        case .wav:
            folderPath = wavPath
        case .jpg:
            folderPath = jpgPath
        case .png:
            folderPath = pngPath
        case .video:
            folderPath = videoPath
        case .file:
            folderPath = FilePath
        }
        let filePath = folderPath + "/" + fileName.path
        return filePath
    }
    
    func createFile(with fileName: FileFormatterType) -> String? {
        var folderPath : String
        switch fileName {
        case .amr:
            folderPath = amrPath
        case .wav:
            folderPath = wavPath
        case .jpg:
            folderPath = jpgPath
        case .png:
            folderPath = pngPath
        case .video:
            folderPath = videoPath
        case .file:
            folderPath = FilePath
        }
        let filePath = folderPath + "/" + fileName.path
        if fileManager.fileExists(atPath: filePath) {
            do{
                try fileManager.removeItem(atPath: filePath)
            }catch{
                return nil
            }
        }
        return filePath
    }
    
    func createTempPath(fileName: String) -> String {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "YYYYMMddhhmmssSSS"
        let str = formatter.string(from: Date.init())
        var filePath = TempPath + "/" + str + fileName
        while fileManager.fileExists(atPath: filePath) {
            filePath =  TempPath + "/" + str + "_\(Int.random(in: 0...100000))" + fileName
        }
        return filePath
    }
    
    func haveFile(with fileName: FileFormatterType) -> Bool {
        var folderPath : String
        switch fileName {
        case .amr:
            folderPath = amrPath
        case .wav:
            folderPath = wavPath
        case .jpg:
            folderPath = jpgPath
        case .png:
            folderPath = pngPath
        case .video:
            folderPath = videoPath
        case .file:
            folderPath = FilePath
        }
        let filePath = folderPath + "/" + fileName.path
        return fileManager.fileExists(atPath: filePath)
    }
}

//文件存储
extension FZMLocalFileClient {
    public func saveData(_ data: Data, filePath: String) -> Bool {
        
        let toFolder = (filePath as NSString).replacingOccurrences(of: (filePath as NSString).lastPathComponent, with: "")
        if !fileManager.fileExists(atPath: toFolder) {
            try? fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
        }
        do {
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
        } catch let error as Error {
            IMLog(error)
            return false
        }
        FZMLog("\(filePath)文件保存成功")
        return true
    }
}

//读取文件
extension FZMLocalFileClient {
    public func readData(fileName: FileFormatterType) -> Data? {
        var folderPath : String
        switch fileName {
        case .amr:
            folderPath = amrPath
        case .wav:
            folderPath = wavPath
        case .jpg:
            folderPath = jpgPath
        case .png:
            folderPath = pngPath
        case .video:
            folderPath = videoPath
        case .file:
            folderPath = FilePath
            
        }
        let filePath = folderPath + "/" + fileName.path
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        return data
    }
}

extension FZMLocalFileClient {
    public func move(fromFilePath: String, toFilePath: String) -> Bool {
        guard fileManager.fileExists(atPath: fromFilePath) else {
            return false
        }
        
        let toFolder = (toFilePath as NSString).replacingOccurrences(of: (toFilePath as NSString).lastPathComponent, with: "")
        if !fileManager.fileExists(atPath: toFolder) {
            try? fileManager.createDirectory(atPath: toFilePath, withIntermediateDirectories: true, attributes: nil)
        }
        
        if fileManager.fileExists(atPath: toFilePath) {
            try? fileManager.removeItem(atPath: toFilePath)
        }

        do {
            try fileManager.moveItem(atPath: fromFilePath, toPath: toFilePath)
        } catch {
            return false
        }
        return true
    }
    
    public func deleteFile(atFilePath: String) -> Bool {
        guard fileManager.fileExists(atPath: atFilePath) else {
            return true
        }
        do {
            try fileManager.removeItem(atPath: atFilePath)
        } catch  {
            return false
        }
        return true
    }
}
