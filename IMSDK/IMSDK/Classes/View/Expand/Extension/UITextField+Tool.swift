//
//  UITextField+Tool.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import UIKit

extension UITextField{
    func limitText(with limit:Int){
        guard let text = self.text else { return }
        let lang = self.textInputMode?.primaryLanguage
        if lang == "zh-Hans" {
            guard let selectedRange = self.markedTextRange,let _ = self.position(from: selectedRange.start, offset: 0) else {
                if text.count > limit{
                    self.text = text.substring(to: limit - 1)
                }
                return
            }
        }else {
            if text.count > limit {
                self.text = text.substring(to: limit - 1)
            }
        }
    }
    
    @discardableResult func addToolBar(with title: String, target: Any, sel: Selector) -> UIButton {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 70))
        view.backgroundColor = FZM_BackgroundColor
        let btn = UIButton.getNormalBtn(with: title)
        btn.frame = CGRect(x: 15, y: 15, width: ScreenWidth - 30, height: 40)
        btn.addTarget(target, action: sel, for: .touchUpInside)
        btn.layer.cornerRadius = 20
        view.addSubview(btn)
        self.inputAccessoryView = view
        return btn
    }
    
}
