//
//  FZMMoreItemBar.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/26.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class FZMMoreItemBar: UIView {
    
    let disposeBag = DisposeBag()
    
    weak var delegate : MoreItemClickDelegate?

    lazy var redBagView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_redBag"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "红包")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var redBagMsgView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_redBag_msg"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "红包消息")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var photoView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_image"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "图片/视频")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var cameraView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_camera"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "拍摄")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var burnView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_burn_icon"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "阅后即焚")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var fileView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_file"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "文件")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var receiptView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_receipt"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "收款")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    lazy var transferView : UIView = {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage("input_transfer"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 61, height: 60))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: "转账")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(17)
        })
        return view
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        self.clipsToBounds = true
        if IMSDK.shared().showRedBag {
            self.addSubview(redBagView)
            self.addSubview(photoView)
            self.addSubview(cameraView)
            self.addSubview(burnView)
            self.addSubview(fileView)
            self.addSubview(transferView)
            self.addSubview(receiptView)
            self.addSubview(redBagMsgView)
            photoView.snp.makeConstraints { (m) in
                m.right.equalTo(self.snp.centerX).offset(-10)
                m.top.equalToSuperview().offset(5)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            redBagView.snp.makeConstraints { (m) in
                m.centerY.equalTo(photoView)
                m.right.equalTo(photoView.snp.left).offset(-20)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            cameraView.snp.makeConstraints { (m) in
                m.centerY.equalTo(photoView)
                m.left.equalTo(self.snp.centerX).offset(10)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            burnView.snp.makeConstraints { (m) in
                m.centerY.equalTo(photoView)
                m.left.equalTo(cameraView.snp.right).offset(20)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            
            fileView.snp.makeConstraints { (m) in
                m.left.equalTo(redBagView)
                m.top.equalTo(redBagView.snp.bottom).offset(19)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            transferView.snp.makeConstraints { (m) in
                m.left.equalTo(photoView)
                m.top.equalTo(fileView)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            receiptView.snp.makeConstraints { (m) in
                m.left.equalTo(cameraView)
                m.top.equalTo(fileView)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            redBagMsgView.snp.makeConstraints { (m) in
                m.left.equalTo(burnView)
                m.top.equalTo(fileView)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
        }else {
            self.addSubview(photoView)
            self.addSubview(cameraView)
            self.addSubview(burnView)
            self.addSubview(fileView)
            self.addSubview(transferView)
            self.addSubview(receiptView)
            cameraView.snp.makeConstraints { (m) in
                m.right.equalTo(self.snp.centerX).offset(-10)
                m.top.equalToSuperview().offset(5)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            photoView.snp.makeConstraints { (m) in
                m.centerY.equalTo(cameraView)
                m.right.equalTo(cameraView.snp.left).offset(-20)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            burnView.snp.makeConstraints { (m) in
                m.centerY.equalTo(photoView)
                m.left.equalTo(self.snp.centerX).offset(10)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            fileView.snp.makeConstraints { (m) in
                m.centerY.equalTo(photoView)
                m.left.equalTo(burnView.snp.right).offset(20)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            transferView.snp.makeConstraints { (m) in
                m.left.equalTo(photoView)
                m.top.equalTo(photoView.snp.bottom).offset(19)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
            receiptView.snp.makeConstraints { (m) in
                m.left.equalTo(cameraView)
                m.top.equalTo(transferView)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
        }
        
        if !IMSDK.shared().showWallet {
            self.hideTransferAndReceipt()
        }
        
        self.makeActions()
    }
    
    private func makeActions() {
        let photoTap = UITapGestureRecognizer()
        photoTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.sendPhoto()
        }).disposed(by: disposeBag)
        photoView.addGestureRecognizer(photoTap)
        
        let cameraTap = UITapGestureRecognizer()
        cameraTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.goCamera()
        }).disposed(by: disposeBag)
        cameraView.addGestureRecognizer(cameraTap)
        
        let redbagTap = UITapGestureRecognizer()
        redbagTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.sendRedBag()
        }).disposed(by: disposeBag)
        redBagView.addGestureRecognizer(redbagTap)
        
        let redbagMsgTap = UITapGestureRecognizer()
        redbagMsgTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.sendRedBagMsg()
        }).disposed(by: disposeBag)
        redBagMsgView.addGestureRecognizer(redbagMsgTap)
        
        let burnTap = UITapGestureRecognizer()
        burnTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.burnCtrl()
        }).disposed(by: disposeBag)
        burnView.addGestureRecognizer(burnTap)
        
        let fileTap = UITapGestureRecognizer()
        fileTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.sendFile()
        }).disposed(by: disposeBag)
        fileView.addGestureRecognizer(fileTap)
        
        let transferTap = UITapGestureRecognizer()
        transferTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.transfer()
        }).disposed(by: disposeBag)
        transferView.addGestureRecognizer(transferTap)
        
        let receiptTap = UITapGestureRecognizer()
        receiptTap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.delegate?.receipt()
        }).disposed(by: disposeBag)
        receiptView.addGestureRecognizer(receiptTap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideTransferAndReceipt() {
        self.receiptView.isHidden = true
        self.transferView.isHidden = true
        if IMSDK.shared().showRedBag {
            redBagMsgView.snp.remakeConstraints { (m) in
                m.left.equalTo(photoView)
                m.top.equalTo(fileView)
                m.size.equalTo(CGSize(width: 61, height: 82))
            }
        }
    }
}

protocol MoreItemClickDelegate: class {
    func sendPhoto()
    func goCamera()
    func sendRedBag()
    func burnCtrl()
    func sendFile()
    func transfer()
    func receipt()
    func sendRedBagMsg()
}
