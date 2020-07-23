//
//  UIResponder+Tool.swift
//  IMSDK
//
//  Created by .. on 2019/12/13.
//

import Foundation

private weak var fzm_currentFirstResponder: AnyObject?

extension UIResponder {
    static func fzm_firstResponder() -> AnyObject? {
        fzm_currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(fzm_findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return fzm_currentFirstResponder
    }
}

extension UIResponder {
    @objc func fzm_findFirstResponder(_ sender: AnyObject) {
        fzm_currentFirstResponder = self
    }
}
