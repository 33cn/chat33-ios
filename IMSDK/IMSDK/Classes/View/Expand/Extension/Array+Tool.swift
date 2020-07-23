//
//  Array+Tool.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/11.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation

extension Array{
    public func index(of element: Element) -> Int? {
        let arr = self as NSArray
        if arr.contains(element) {
            return arr.index(of: element)
        }else{
            return nil
        }
    }
    
    public mutating func remove(at element: Element) {
        if let index = self.index(of: element) {
            self.remove(at: index)
        }
    }
    
    public subscript (safe index: Index) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
}
