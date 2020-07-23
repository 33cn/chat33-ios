//
//  UIView+Tool.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import SnapKit

extension UIView{
    var size: CGSize {set {frame.size = newValue} get {return frame.size}}
    var width: CGFloat {set {size.width = newValue} get {return size.width}}
    var height: CGFloat {set {size.height = newValue} get {return size.height}}
    
    var safeArea : ConstraintRelatableTarget {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide
        }
        return self
    }
    
    class func getNormalLineView() -> UIView{
        let view = UIView()
        view.backgroundColor = FZM_LineColor
        return view
    }
    
    class func getView(image: UIImage?, des: String?) -> UIView {
        let view = UIView.init()
        view.backgroundColor = FZM_BackgroundColor
        let imageView = UIImageView.init(image: image)
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (m) in
            m.left.equalToSuperview()
            m.centerY.equalToSuperview()
        }
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: des)
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.left.equalTo(imageView.snp.right).offset(15)
            m.centerY.equalTo(imageView)
        }
        return view
    }
    
    func showProgress(with text : String? = nil){
        MBProgressHUD.hide(for: self, animated: true)
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
        MBProgressHUD.hide(for: self, animated: true)
        let hud = MBProgressHUD.showAdded(to: self, animated: true)
        hud.label.text = text
        hud.bezelView.backgroundColor = UIColor(hex: 0x262B31)
        hud.label.numberOfLines = 0
        hud.contentColor = UIColor.white
        hud.mode = .text
        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: 1.5)
    }
    
    func updateConstraints(with time: Double, updateBlock: NormalBlock?) {
        self.setNeedsUpdateConstraints()
        updateBlock?()
        UIView.animate(withDuration: time) {
            self.layoutIfNeeded()
        }
    }
    
    func updateConstraints(with time: Double, updateBlock: NormalBlock?, completeBlock: NormalBlock? = nil) {
        self.setNeedsUpdateConstraints()
        updateBlock?()
        UIView.animate(withDuration: time, animations: {
            self.layoutIfNeeded()
        }) { (finish) in
            if finish {
                completeBlock?()
            }
        }
    }
    
    func makeOriginalShdowShow() {
        self.layer.backgroundColor = FZM_BackgroundColor.cgColor
        self.layer.cornerRadius = 5
        self.makeNormalShadow()
    }
    
    func makeNormalShadow(with offset: CGSize = CGSize.zero) {
        self.layer.shadowColor = FZM_ShadowColor.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 1.0
        self.clipsToBounds = false
    }
    
    class func getOnlineView(title: String,rightView: UIView?, showMore: Bool = true, showBottomLine: Bool = true) -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        let titleLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: title)
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview()
        }
        if showMore {
            let imV = UIImageView(image: GetBundleImage("me_more"))
            view.addSubview(imV)
            imV.snp.makeConstraints { (m) in
                m.centerY.equalTo(titleLab)
                m.right.equalToSuperview()
                m.size.equalTo(CGSize(width: 4, height: 15))
            }
        }
        if let rightView = rightView {
            view.addSubview(rightView)
            rightView.snp.makeConstraints { (m) in
                m.centerY.equalTo(titleLab)
                m.right.equalToSuperview().offset(showMore ? -9 : 0)
            }
        }
        if showBottomLine {
            let lineV = UIView.getNormalLineView()
            view.addSubview(lineV)
            lineV.snp.makeConstraints { (m) in
                m.bottom.left.right.equalToSuperview()
                m.height.equalTo(0.5)
            }
        }
        return view
    }
    
}
