//
//  Tool.swift
//  Chat33
//
//  Created by .. on 2019/6/14.
//  Copyright © 2019 吴文拼. All rights reserved.
//

import Foundation
import MBProgressHUD

extension UIView {
    func showProgress(with text : String? = nil){
        let hud = MBProgressHUD.showAdded(to: self, animated: true)
        guard let text = text else {
            return
        }
        hud.label.text = text
        hud.mode = .indeterminate
        hud.show(animated: true)
    }
    
    func hideProgress(){
        MBProgressHUD.hide(for: self, animated: true)
    }
    
    func showToast(with text: String){
        let hud = MBProgressHUD.showAdded(to: self, animated: true)
        hud.label.text = text
        hud.bezelView.backgroundColor = UIColor(hex: 0x262B31)
        hud.label.numberOfLines = 0
        hud.contentColor = UIColor.white
        hud.mode = .text
        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: 1.5)
    }
}


extension UIColor{
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex & 0xFF0000) >> 16)/255, green: CGFloat((hex & 0x00FF00) >> 8)/255, blue: CGFloat(hex & 0x0000FF)/255, alpha: alpha)
    }
}
