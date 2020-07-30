//
//  FZMImageTitleView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
class FZMImageTitleView: UIView {

    let disposeBag = DisposeBag()
    
    var clickBlock : NormalBlock?
    
    init(headImage : UIImage? , imageSize : CGSize? , title : String? ,titleColor: UIColor = FZM_BackgroundColor, clickBlock : (()->())?) {
        super.init(frame: CGRect.zero)
        let headImV = UIImageView.init(image: headImage)
        self.addSubview(headImV)
        headImV.snp.makeConstraints { (m) in
            m.centerX.top.equalToSuperview()
            m.size.equalTo(imageSize ?? CGSize.zero)
        }
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: titleColor, textAlignment: NSTextAlignment.center, text: title)
        self.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.centerX.bottom.equalToSuperview()
            m.height.equalTo(20)
        }
        self.clickBlock = clickBlock
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            self?.clickBlock?()
        }.disposed(by: disposeBag)
        self.addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
