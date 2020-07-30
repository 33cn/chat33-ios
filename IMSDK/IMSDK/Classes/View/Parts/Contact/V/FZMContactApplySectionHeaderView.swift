//
//  FZMContactApplySectionHeaderView.swift
//  IMSDK
//
//  Created by .. on 2019/1/21.
//

import UIKit

class FZMContactApplySectionHeaderView: UIView {

    init(with sectionTitle:String?) {
        
        super.init(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 24.5))
    
        let timeLab = UILabel.getLab(font: .systemFont(ofSize: 12), textColor:FZM_GrayWordColor , textAlignment: .center, text: sectionTitle)
        self.addSubview(timeLab);
        timeLab.snp.makeConstraints { (m) in
            m.bottom.equalToSuperview();
            m.right.equalToSuperview().offset(-15);
        }
        
        let lineView = UIView.getNormalLineView()
        self.addSubview(lineView)
        lineView.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(32)
            m.top.bottom.equalToSuperview()
            m.width.equalTo(1)
        }

    }
    
   
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
