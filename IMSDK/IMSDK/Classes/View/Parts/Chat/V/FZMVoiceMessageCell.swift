//
//  FZMVoiceMessageCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/27.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMVoiceMessageCell: FZMBaseMessageCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var voiceBtn : UIImageView = {
        let btn = UIImageView()
        btn.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        btn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        btn.image = image
        btn.isUserInteractionEnabled = true
        return btn
    }()
    
    //小喇叭动画
    lazy var voiceImageView: UIImageView = {
        let imgV = UIImageView()
        imgV.contentMode = .scaleAspectFit
        imgV.animationDuration = 2
        imgV.animationRepeatCount = 0
        return imgV
    }()
    
    lazy var unreadView : UIView = {
        let view = UIView()
        view.backgroundColor = FZM_RedColor
        view.layer.cornerRadius = 3.5
        view.clipsToBounds = true
        return view
    }()
    
    lazy var secondLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .center, text: "1s")
    }()
    
    let countDownCount = 10
    
    var voiceDisposeBag = DisposeBag()
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(voiceBtn)
        voiceBtn.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-8)
            m.left.equalTo(self.headerImageView.snp.right).offset(5)
            m.height.equalTo(60)
            m.width.equalTo(100)
            m.bottom.equalToSuperview().offset(-5)
        }
        
        voiceBtn.addSubview(voiceImageView)
        voiceImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(20)
            m.size.equalTo(CGSize(width: 21, height: 21))
        }
        self.contentView.addSubview(unreadView)
        unreadView.snp.makeConstraints { (m) in
            m.top.equalTo(voiceBtn).offset(10)
            m.left.equalTo(voiceBtn.snp.right).offset(-5)
            m.size.equalTo(CGSize(width: 7, height: 7))
        }
        self.contentView.addSubview(secondLab)
        secondLab.snp.makeConstraints { (m) in
            m.centerY.equalTo(voiceBtn)
            m.left.equalTo(voiceBtn.snp.right).offset(-5)
            m.height.equalTo(23)
        }
        
        self.contentView.addSubview(self.lockView)
        self.lockView.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-5)
            m.left.equalToSuperview().offset(55)
            m.size.equalTo(CGSize(width: 120, height: 65))
        }
        self.voiceBtn.addSubview(self.countDownTimeView)
        self.countDownTimeView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(10)
            m.centerX.equalTo(self.voiceBtn.snp.right).offset(-10)
            m.size.equalTo(CGSize(width: 0, height: 0))
        }
        
        sendingView.snp.makeConstraints { (m) in
            m.centerY.equalTo(secondLab)
            m.left.equalTo(secondLab.snp.right).offset(5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(voiceBtn.snp.bottom).offset(-15)
            m.left.equalTo(secondLab.snp.right).offset(5)
        }

        
        voiceImageView.image = UIImage(text: .rightVoice_3, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor)
        let animationArray = [UIImage(text: .rightVoice_1, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor),
                              UIImage(text: .rightVoice_2, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor),
                              UIImage(text: .rightVoice_3, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor)].compactMap({$0})
        voiceImageView.animationImages = animationArray
        
        
       
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            self?.playVoice()
        }.disposed(by: disposeBag)
        voiceBtn.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            if press.state == .began {
                guard let view = press.view else { return }
                self?.showMenu(in: view)
            }
        }.disposed(by: disposeBag)
        voiceBtn.addGestureRecognizer(longPress)
        
    }
    
    
    private func playVoice() {
        guard let data = self.vm as? FZMVoiceMessageVM else { return }
        actionDelegate?.playVoice(msgId: data.msgId)
        VoiceMessagePlayerManager.shared().playVoice(msg: self.vm.message)
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMVoiceMessageVM else { return }
        secondLab.text = String(format: "%.0fs", data.duration)
        voiceBtn.snp.updateConstraints { (m) in
            m.width.equalTo((ScreenWidth - 200)/60*CGFloat(data.duration) + 80)
        }
        if let dbMsg = SocketMessage.getMsg(with: data.message.msgId, conversationId: data.message.conversationId, conversationType: data.message.channelType)  {
            data.message.body.isRead = dbMsg.body.isRead
            data.isRead = dbMsg.body.isRead
        }
        unreadView.isHidden = data.isRead || data.direction == .send
        self.voiceDisposeBag = DisposeBag()
        VoiceMessagePlayerManager.shared().voicePalyStateSubject.subscribe{[weak self] (event) in
            guard let strongSelf = self ,
                case .next(let e) = event,
                let msgId = e?.0,
                let state = e?.1
                else { return }
            guard let msg = self?.vm.message, msg.msgId == msgId else { return }
            msg.body.isRead = true
            data.isRead = true
            strongSelf.unreadView.isHidden = true
            if state == .start {
                strongSelf.voiceImageView.startAnimating()
            } else if state == .finish {
                strongSelf.voiceImageView.stopAnimating()
                guard data.direction == .receive else { return }
                if strongSelf.countDownTimeView.text == "\(strongSelf.countDownCount)" {
                    strongSelf.actionDelegate?.shouldBurnData(msgId: data.msgId)
                }
            } else if state == .failed {
                strongSelf.voiceImageView.stopAnimating()
                UIApplication.shared.keyWindow?.showToast(with: "播放失败")
            }
        }.disposed(by: voiceDisposeBag)
        
        guard data.direction == .receive else { return }
        if data.snap == .burn {
            voiceBtn.isHidden = true
            unreadView.isHidden = true
            secondLab.isHidden = true
            lockView.isHidden = false
        }else {
            voiceBtn.isHidden = false
            secondLab.isHidden = false
            lockView.isHidden = true
            countDownTimeView.setTime(data.snap == .open ? countDownCount : 0)
        }        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}


class FZMMineVoiceMessageCell: FZMVoiceMessageCell {
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        self.contentView.addSubview(sourceLab)
        sourceLab.snp.makeConstraints { (m) in
            m.right.equalTo(headerImageView.snp.left).offset(-20)
            m.left.greaterThanOrEqualToSuperview().offset(80)
            m.bottom.equalToSuperview().offset(-10)
            m.height.lessThanOrEqualTo(35)
        }
        voiceBtn.snp.remakeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-8)
            m.right.equalTo(self.headerImageView.snp.left).offset(-5)
            m.height.equalTo(60)
            m.width.equalTo(100)
            m.bottom.equalTo(sourceLab.snp.top).offset(5)
        }
        voiceImageView.snp.remakeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-20)
            m.size.equalTo(CGSize(width: 21, height: 21))
        }
        unreadView.snp.remakeConstraints { (m) in
            m.top.equalTo(voiceBtn).offset(10)
            m.right.equalTo(voiceBtn.snp.left).offset(5)
            m.size.equalTo(CGSize(width: 7, height: 7))
        }
        unreadView.isHidden = true
        secondLab.snp.remakeConstraints { (m) in
            m.centerY.equalTo(voiceBtn)
            m.right.equalTo(voiceBtn.snp.left).offset(5)
            m.height.equalTo(23)
        }
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(secondLab)
            m.right.equalTo(secondLab.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text_mine")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        voiceBtn.image = image
        
        voiceImageView.image = UIImage(text: .leftVoice_3, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor)
        let animationArray = [UIImage(text: .leftVoice_1, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor),
                              UIImage(text: .leftVoice_2, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor),
                              UIImage(text: .leftVoice_3, imageSize: CGSize(width: 13, height: 21), imageColor: FZM_BlackWordColor)].compactMap({$0})
        voiceImageView.animationImages = animationArray
        
        lockView.removeFromSuperview()
        countDownTimeView.removeFromSuperview()
        self.voiceBtn.addSubview(lockImg)
        lockImg.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(8)
            m.left.equalToSuperview()
            m.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(voiceBtn.snp.bottom).offset(-15)
            m.right.equalTo(secondLab.snp.left).offset(-5)
        }
        
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        self.lockImg.isHidden = data.snap == .none
        sourceLab.text = data.forwardType == .detail ? data.forwardDescriptionText : nil
    }
}
