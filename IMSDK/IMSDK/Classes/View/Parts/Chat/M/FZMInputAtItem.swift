//
//  FZMInputAtItem.swift
//  IMSDK
//
//  Created by .. on 2019/9/5.
//

import UIKit
fileprivate let AtChar = "@"
fileprivate let AtEndChar = "\u{2004}"
class FZMInputAtItem: NSObject {
    let uid: String
    let name: String
    init(uid: String, name: String) {
        self.uid = uid
        self.name = AtChar + name + AtEndChar
        super.init()
    }
}

class FZMInputAtItemCache: NSObject {
    private var atItems = Array<FZMInputAtItem>.init()
    
    func clear() {
        self.atItems.removeAll()
    }
    
    func add(_ item: FZMInputAtItem) {
        self.atItems.append(item)
    }
    
    func remove(by name: String) {
        var item: FZMInputAtItem?
        for i in 0..<self.atItems.count {
            if self.atItems[i].name == name {
                item = self.atItems[i]
                break
            }
        }
        guard let obj = item else { return }
        self.atItems.remove(at: obj)
    }
    
    func getItem(by name: String) -> FZMInputAtItem? {
        for item in self.atItems {
            if item.name == name {
                return item
            }
        }
        return nil
    }
    
    func getAllAtUids(by text: String) -> [String] {
        var uids = Array<String>.init()
        self.match(text).forEach { (name) in
            if let item = self.getItem(by: name) {
                uids.append(item.uid)
            }
        }
        return uids
    }
    
    func atItemRang(in text: String) -> NSRange? {
        let pattern = "@([^\(AtEndChar)]+)\(AtEndChar)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            if let lastResult = results.last, (lastResult.range.location + lastResult.range.length) == text.count {
                let name = (text as NSString).substring(with: lastResult.range)
                if self.getItem(by: name) != nil {
                    return lastResult.range
                }
            }
        }
        return nil
    }
    
    private func match(_ text: String) -> [String] {
        let pattern = "@([^\(AtEndChar)]+)\(AtEndChar)"
        var matchs = Array<String>.init()
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            results.forEach { (result) in
                let name = (text as NSString).substring(with: result.range)
                matchs.append(name)
            }
        }
        return matchs
    }
}




