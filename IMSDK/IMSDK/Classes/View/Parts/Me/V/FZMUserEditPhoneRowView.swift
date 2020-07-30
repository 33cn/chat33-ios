//
//  FZMUserEditPhoneRowView.swift
//  IMSDK
//
//  Created by .. on 2019/2/27.
//

import UIKit
import RxSwift
class FZMUserEditPhoneRowView: UIView {
    private let disposeBag = DisposeBag()
    var deleteBlcok:NormalBlock?
    var leftValue: String {
        get {
            return leftTextField.text ?? ""
        }
        set {
            if !newValue.isEmpty {
                leftTextField.text = newValue
            }
        }
    }
    var rigthValue: String {
        get {
            return rightTextField.text ?? ""
        }
        set {
            if !newValue.isEmpty {
                rightTextField.text = newValue
            }
        }
    }
    private let leftTextField = UITextField.init()
    private let rightTextField = UITextField.init()
    
    
    init() {
        super.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        let imageView = UIImageView.init(image: GetBundleImage("user_phone_del"))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.enlargeClickEdge(5, 5, 5, 0)
        let tap = UITapGestureRecognizer.init()
        imageView.addGestureRecognizer(tap)
        tap.rx.event.subscribe { [weak self] (_) in
            self?.deleteBlcok?()
            }.disposed(by: disposeBag)
        
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (m) in
            m.width.height.equalTo(25)
            m.left.equalToSuperview()
            m.centerY.equalToSuperview()
        }
        
        leftTextField.text = "手机"
        leftTextField.textColor = FZM_BlackWordColor
        leftTextField.font = UIFont.regularFont(16)
        leftTextField.rx.controlEvent(.editingChanged).asObservable().subscribe { [weak self](_) in
            let text = self?.leftTextField.text ?? ""
            if text.count > 6 {
                self?.leftTextField.text = text.substring(to: 5)
            }
            }.disposed(by: disposeBag)
        self.addSubview(leftTextField)
        leftTextField.snp.makeConstraints { (m) in
            m.left.equalTo(imageView.snp.right).offset(15)
            m.centerY.equalTo(imageView)
            m.height.equalTo(23)
            m.width.equalTo(98)
        }
        
        let line = UIView.getNormalLineView()
        self.addSubview(line)
        line.snp.makeConstraints { (m) in
            m.width.equalTo(1)
            m.height.equalToSuperview()
            m.centerX.equalToSuperview().offset(-10)
            m.top.equalToSuperview()
        }
        
        rightTextField.placeholder = "添加电话号码"
        rightTextField.keyboardType = .phonePad
        rightTextField.textColor = FZM_BlackWordColor
        rightTextField.font = UIFont.regularFont(16)
        rightTextField.rx.controlEvent(.editingChanged).asObservable().subscribe { [weak self] (_) in
            let text = self?.rightTextField.text ?? ""
            if text.count > 20 {
                self?.rightTextField.text = text.substring(to: 19)
            }
            }.disposed(by: disposeBag)
        self.addSubview(rightTextField)
        rightTextField.snp.makeConstraints { (m) in
            m.left.equalTo(line.snp.right).offset(15)
            m.centerY.equalTo(leftTextField)
            m.height.equalTo(leftTextField)
            m.right.equalToSuperview()
        }
    }
    
    func addToolBar(with title: String, target: Any, sel: Selector) {
        leftTextField.addToolBar(with: title, target: target, sel: sel)
        rightTextField.addToolBar(with: title, target: target, sel: sel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
