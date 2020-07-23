//
//  FZMFileSearchController.swift
//  IMSDK
//
//  Created by .. on 2019/3/5.
//

import UIKit

class FZMFileSearchController: FZMFileViewController {
    
    lazy var searchBlockView : UIView = {
        let view = UIView.init()
        view.layer.backgroundColor = FZM_LineColor.cgColor
        view.layer.cornerRadius = 20
        view.tintColor = FZM_GrayWordColor
        let imageV = UIImageView(image: GetBundleImage("tool_search")?.withRenderingMode(.alwaysTemplate))
        view.addSubview(imageV)
        imageV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 17, height: 18))
        })
        view.addSubview(searchInput)
        searchInput.snp.makeConstraints({ (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalTo(imageV.snp.right).offset(10)
        })
        return view
    }()
    
    lazy var searchInput : UITextField = {
        let input = UITextField.init()
        input.tintColor = FZM_TintColor
        input.textAlignment = .left
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.attributedPlaceholder = NSAttributedString(string: "文件名/上传者", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
        input.returnKeyType = .search
        input.delegate = self
        return input
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchInput.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectBtn = UIBarButtonItem.init(title: "选择", style: .done, target: self, action: #selector(selectFileOrCancel))
        self.navigationItem.rightBarButtonItems = [selectBtn]
        
    }
    
    override func createUI() {

        let titleView = IntrinsicView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 40))
        self.navigationItem.titleView = titleView
        titleView.addSubview(searchBlockView)
        searchBlockView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.centerX.equalToSuperview().offset(-10)
            m.width.equalTo(280)
            m.height.equalTo(40)
        }
        
        self.view1 = FZMFlieListView.init(with: "", conversationType: conversationType, conversationId: conversationID, owner: "")
        if let view1 = self.view1 {
            let param = FZMSegementParam()
            param.headerHeight = 0
            let pageView = FZMScrollPageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight-StatusNavigationBarHeight), dataViews: [view1], param: param)
            self.view.addSubview(pageView)
        }
    }
}

extension FZMFileSearchController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n", let text = self.searchInput.text, text.count > 0 {
            var isEmpty = true
            text.forEach { (c) in
                if c != " " && c != "\n" {
                    isEmpty = false
                }
            }
            if !isEmpty {
                self.search(self.searchInput.text!)
            }
            self.searchInput.endEditing(true)
            return false
        }
        return true
    }
    
    private func search(_ text: String) {
        self.view1?.searchText = text
    }
}



class IntrinsicView: UIView {
    override var intrinsicContentSize: CGSize {
        get {
            return CGSize.init(width: 280, height: 40)
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
