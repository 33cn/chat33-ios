//
//  FZMFileManager.swift
//  IMSDK
//
//  Created by .. on 2019/3/1.
//

import UIKit

class FZMFileManager: NSObject {
    
    private static let sharedInstance = FZMFileManager.init()
    
    class func shared() -> FZMFileManager {
        return sharedInstance
    }
    
    
    func groupFiles(groupId: String,startId: String,number: Int, query: String, owner: String,completionBlock: MessageListHandler?) {
        HttpConnect.shared().groupFiles(groupId: groupId, startId: startId, number: number, query: query, owner: owner) { (response) in
            var list = [SocketMessage]()
            var nextId = ""
            defer{
                completionBlock?(list,nextId,response)
            }
            guard let data = response.data , let jsonList = data["logs"].array else { return }
            jsonList.forEach({ (json) in
                if let msg = SocketMessage(with: json) {
                    list.append(msg)
                }
            })
            nextId = data["nextLog"].stringValue
        }
    }
    func groupPhotosAndVideos(groupId: String, startId: String, number: Int ,completionBlock: MessageListHandler?) {
        HttpConnect.shared().groupPhotosAndVideos(groupId: groupId, startId: startId, number: number) { (response) in
            var list = [SocketMessage]()
            var nextId = ""
            defer{
                completionBlock?(list,nextId,response)
            }
            guard let data = response.data , let jsonList = data["logs"].array else { return }
            jsonList.forEach({ (json) in
                if let msg = SocketMessage(with: json) {
                    list.append(msg)
                }
            })
            nextId = data["nextLog"].stringValue
        }
    }
    func friendFiles(friendId: String,startId: String,number: Int, query: String, owner: String ,completionBlock: MessageListHandler?) {
        HttpConnect.shared().friendFiles(friendId: friendId, startId: startId, number: number, query: query, owner: owner) { (response) in
            var list = [SocketMessage]()
            var nextId = ""
            defer{
                completionBlock?(list,nextId,response)
            }
            guard let data = response.data , let jsonList = data["logs"].array else { return }
            jsonList.forEach({ (json) in
                if let msg = SocketMessage(with: json) {
                    list.append(msg)
                }
            })
            nextId = data["nextLog"].stringValue
        }
    }
    func friendPhotosAndVideos(friendId: String, startId: String, number: Int ,completionBlock: MessageListHandler?) {
        HttpConnect.shared().friendPhotosAndVideos(friendId: friendId, startId: startId, number: number) { (response) in
            var list = [SocketMessage]()
            var nextId = ""
            defer{
                completionBlock?(list,nextId,response)
            }
            guard let data = response.data , let jsonList = data["logs"].array else { return }
            jsonList.forEach({ (json) in
                if let msg = SocketMessage(with: json) {
                    list.append(msg)
                }
            })
            nextId = data["nextLog"].stringValue
        }
    }
    func revokeFiles(fileIds:[String], type: Int, completionBlock: NormalHandler?) {
        HttpConnect.shared().revokeFiles(fileIds: fileIds, type: type) { (response) in
            completionBlock?(response)
        }
    }
}
