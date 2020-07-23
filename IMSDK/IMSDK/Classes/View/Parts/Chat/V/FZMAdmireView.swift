//
//  FZMAdmireView.swift
//  IMSDK
//
//  Created by .. on 2019/11/19.
//

import UIKit
import Lottie

class FZMAdmireView: UIView {
    
    private let admireImageView = UIImageView.init()
    private let lab = UILabel.getLab(font: UIFont.systemFont(ofSize: 12), textColor: .clear, textAlignment: .left, text: nil)
    var tapBlock: (()->())?
    
    private lazy var animationView: AnimationView = {
        let v = AnimationView.init(filePath: IMSDKPath(forResource: "like", ofType: ".json") ?? "")
        v.isHidden = true
        return v
    }()
    
    init() {
        super.init(frame: .zero)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
        
        admireImageView.isUserInteractionEnabled = true
        lab.isUserInteractionEnabled = true
        self.addSubview(lab)
        self.addSubview(admireImageView)
        
        self.admireImageView.snp.remakeConstraints { (m) in
            m.left.equalTo(self)
            m.centerY.equalTo(self)
            m.size.equalTo(CGSize.init(width: 11, height: 11))
        }
        self.lab.snp.remakeConstraints { (m) in
            m.left.equalTo(self.admireImageView.snp.right).offset(2)
            m.right.equalToSuperview()
            m.bottom.top.equalToSuperview()
            m.height.equalTo(17)
        }
        
        self.insertSubview(self.animationView, at: 0)
        self.animationView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 54, height: 54))
        }
        
    }
    
    func changeImageTrailing() {
        self.lab.snp.remakeConstraints { (m) in
            m.left.bottom.top.equalToSuperview()
            m.height.equalTo(17)
        }
        self.admireImageView.snp.remakeConstraints { (m) in
            m.left.equalTo(self.lab.snp.right).offset(2)
            m.right.equalToSuperview()
            m.centerY.equalTo(self.lab)
            m.size.equalTo(CGSize.init(width: 11, height: 11))
        }
        
    }
    
    func setAdmire(info: String, state: SocketMessageUpvoteState, animation: Bool = false) {
        if animation, !info.isEmpty, state != .none {
            self.playAnimation()
        }
        self.lab.text = info
        switch state {
        case .none:
            self.lab.textColor = FZM_GrayWordColor
            self.admireImageView.image = GetBundleImage("chat_no_admire")
        case .admire:
            self.lab.textColor = FZM_TintColor
            self.admireImageView.image = GetBundleImage("chat_admire")
        case .reward, .admireReward:
            self.lab.textColor = FZM_EFA019Color
            self.admireImageView.image = GetBundleImage("chat_rewar")
        }
    }
    
    func playAnimation() {
        DispatchQueue.main.async {
            if !self.animationView.isAnimationPlaying {
                self.lab.alpha = 0
                self.admireImageView.alpha = 0
                self.lab.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                self.admireImageView.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 5, initialSpringVelocity: 10, options: .curveEaseInOut, animations: {
                    self.lab.alpha = 1
                    self.admireImageView.alpha = 1
                    self.lab.transform = CGAffineTransform.identity
                    self.admireImageView.transform = CGAffineTransform.identity
                }) { (_) in}
                self.animationView.isHidden = false
                self.animationView.play(fromFrame: 11, toFrame: 26) {[weak self] (_) in
                    self?.animationView.isHidden = true
                }
            }
        }
    }
    
    @objc func tapAction() {
        self.tapBlock?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
