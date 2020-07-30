//
//  FZMPhotoViewCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/26.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import Photos

class FZMPhotoViewCell: UICollectionViewCell {
    
    var asset : PHAsset?
    private let manager =  FZMPhotoManager()
    private let disposeBag = DisposeBag()
    
    var selectBlock : NormalBlock?
    
    var showSelect : Bool = true {
        didSet{
            selectView.isHidden = !showSelect
        }
    }
    
    let contentImageView : UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let selectView : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(GetBundleImage("photo_select_normal"), for: .normal)
        view.layer.cornerRadius = 12.5
        view.clipsToBounds = true
        view.setTitleColor(UIColor.white, for: .normal)
        view.titleLabel?.font = UIFont.regularFont(14)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(hex: 0xCCCCCC)
        self.contentView.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        self.contentView.addSubview(selectView)
        selectView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(8)
            m.right.equalToSuperview().offset(-8)
            m.size.equalTo(CGSize(width: 25, height: 25))
        }
        selectView.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.selectBlock?()
        }.disposed(by: disposeBag)
    }
    
    func configure(index: Int?) {
        if let index = index {
            selectView.setImage(nil, for: .normal)
            selectView.backgroundColor = FZM_TintColor
            selectView.setTitle(String(index + 1), for: .normal)
        }else {
            selectView.setImage(GetBundleImage("photo_select_normal"), for: .normal)
            selectView.backgroundColor = UIColor.clear
            selectView.setTitle(nil, for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
