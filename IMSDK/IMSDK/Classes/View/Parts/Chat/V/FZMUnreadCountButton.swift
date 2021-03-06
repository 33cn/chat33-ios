//
//  FZMUnreadCountButton.swift
//  IMSDK
//
//  Created by .. on 2019/1/23.
//

import UIKit

class FZMUnreadCountButton: UIButton {

    init(with image:UIImage?,frame:CGRect) {
        super.init(frame: frame)
        self.setBackgroundColor(color: FZM_EA6Color, state: .normal)
        self.setBackgroundColor(color: FZM_EA6Color, state: .highlighted)
        let imageView = UIImageView.init(frame: CGRect(x: 15, y: 15, width: 10, height: 10))
        imageView.image = image
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        self.addSubview(imageView)
        self.setTitleColor(FZM_TintColor, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
