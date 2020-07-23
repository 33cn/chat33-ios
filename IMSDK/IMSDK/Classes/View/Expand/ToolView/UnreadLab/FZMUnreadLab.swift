//
//  FZMUnreadLab.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/29.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMUnreadLab: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.font = UIFont.regularFont(12)
        self.textAlignment = .center
        self.textColor = UIColor.white
        self.layer.cornerRadius = 8
        self.layer.backgroundColor = FZM_RedColor.cgColor
    }
    
    func setUnreadCount(_ count: Int) {
        if count < 100 {
            self.text = "\(count)"
            if count < 10 {
                if count <= 0 {
                    self.text = nil
                    self.snp.updateConstraints { (m) in
                        m.size.equalTo(CGSize(width: 0, height: 0))
                    }
                }else {
                    self.snp.updateConstraints { (m) in
                        m.size.equalTo(CGSize(width: 16, height: 16))
                    }
                }
            }else {
                self.snp.updateConstraints { (m) in
                    m.size.equalTo(CGSize(width: 22, height: 16))
                }
            }
        }else if count < 1000{
            self.text = "\(count)"
            self.snp.updateConstraints { (m) in
                m.size.equalTo(CGSize(width: 28, height: 16))
            }
        }else {
            self.text = "…"
            self.snp.updateConstraints { (m) in
                m.size.equalTo(CGSize(width: 22, height: 16))
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class FZMCountdownLab: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.font = UIFont.regularFont(12)
        self.textAlignment = .center
        self.textColor = UIColor.white
        self.layer.cornerRadius = 8
        self.layer.backgroundColor = FZM_OrangeColor.cgColor
    }
    
    func setTime(_ count: Int) {
        self.text = "\(count)"
        if count < 100 {
            if count < 10 {
                if count <= 0 {
                    self.snp.updateConstraints { (m) in
                        m.size.equalTo(CGSize(width: 0, height: 0))
                    }
                }else {
                    self.snp.updateConstraints { (m) in
                        m.size.equalTo(CGSize(width: 16, height: 16))
                    }
                }
            }else {
                self.snp.updateConstraints { (m) in
                    m.size.equalTo(CGSize(width: 22, height: 16))
                }
            }
        }else if count < 1000{
            self.snp.updateConstraints { (m) in
                m.size.equalTo(CGSize(width: 28, height: 16))
            }
        }else{
            self.snp.updateConstraints { (m) in
                m.size.equalTo(CGSize(width: 36, height: 16))
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
