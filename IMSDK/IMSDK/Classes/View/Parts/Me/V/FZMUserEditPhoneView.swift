//
//  FZMUserEditPhoneView.swift
//  IMSDK
//
//  Created by .. on 2019/2/27.
//

import UIKit
import RxSwift
class FZMUserEditPhoneView: UIView {
    let disposeBag = DisposeBag()
    let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "电话")
    let addView = UIView.getView(image: GetBundleImage("user_phone_add"), des: "添加电话号码")
    var phoneRowArr = [FZMUserEditPhoneRowView]()
    var rowArrUseOutside = [FZMUserEditPhoneRowView]() {
        didSet {
            for row in rowArrUseOutside {
                self.addPhoneLine(row)
            }
        }
    }
    private var toolBarTitle: String?
    private var toolBarTarget: Any?
    private var toolBarSelector: Selector?
    
    init() {
        super.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        self.makeOriginalShdowShow()
        
        self.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview()
            m.height.equalTo(30)
            m.left.equalToSuperview().offset(15)
        }
        
        self.addSubview(addView)
        addView.snp.makeConstraints { (m) in
            m.top.equalTo(titleLab.snp.bottom)
            m.height.equalTo(50)
            m.width.equalToSuperview().offset(-30)
            m.left.equalToSuperview().offset(15)
            m.bottom.equalToSuperview()
        }
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe {[weak self](_) in
            self?.addPhoneLine()
            }.disposed(by: disposeBag)
        addView.addGestureRecognizer(tap)
    }
    
    func addToolBar(with title: String, target: Any, sel: Selector) {
        self.toolBarTitle = title
        self.toolBarTarget = target
        self.toolBarSelector = sel
    }
    
    func addPhoneLine(_ row:FZMUserEditPhoneRowView? = nil) {
        guard phoneRowArr.count < 5 else {return}
        var phoneRow: FZMUserEditPhoneRowView
        if let row = row {
            phoneRow = row
        } else {
            phoneRow = FZMUserEditPhoneRowView.init()
        }
        if let toolBarTitle = self.toolBarTitle, let toolBarTarget = self.toolBarTarget, let toolBarSelector = self.toolBarSelector {
            phoneRow.addToolBar(with: toolBarTitle, target: toolBarTarget, sel: toolBarSelector)
        }
        self.addSubview(phoneRow)
        phoneRowArr.append(phoneRow)
        phoneRow.deleteBlcok = {[weak self, weak phoneRow] in
            guard let strongSelf = self ,let strongPhoneRow = phoneRow else {return}
            strongPhoneRow.removeFromSuperview()
            strongSelf.phoneRowArr.remove(at: strongPhoneRow)
            strongSelf.refreshLayout()
        }
        self.refreshLayout()
    }
    
    func refreshLayout() {
        for i in 0..<phoneRowArr.count {
            let phoneRow = phoneRowArr[i]
            phoneRow.snp.remakeConstraints { (m) in
                m.centerX.equalToSuperview()
                if i == 0 {
                    m.top.equalTo(titleLab.snp.bottom).offset(5)
                } else {
                    m.top.equalTo(phoneRowArr[i - 1].snp.bottom)
                }
                m.width.equalToSuperview().offset(-30)
                m.height.equalTo(50)
            }
        }
        addView.snp.remakeConstraints { (m) in
            if let lastPhoneRow = phoneRowArr.last {
                m.top.equalTo(lastPhoneRow.snp.bottom)
            } else {
                m.top.equalTo(titleLab.snp.bottom)
            }
            m.height.equalTo(50)
            m.width.equalToSuperview().offset(-30)
            m.left.equalToSuperview().offset(15)
            m.bottom.equalToSuperview()
        }
        
        self.superview?.layoutIfNeeded()
    }
    
    func deleteLine(with imageView:UIImageView) {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
