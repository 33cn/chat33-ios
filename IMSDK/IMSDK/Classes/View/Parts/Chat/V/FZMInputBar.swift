//
//  FZMInputBar.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/26.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import TSVoiceConverter
import Photos

enum FZMInputBarShowState {
    case detail
    case normal
    case hide
}

class FZMInputBar: UIView {
    
    let disposeBag = DisposeBag()
    
    var showMoreBlock : NormalBlock?
    var recordAudioCompleteBlock : ((String,String,Double,Bool)->())?
    var showMore = false
    private var isSystemMsg = false //是否为公告
    private var canShowSystem = false {
        didSet{
            ctrlTypeView.snp.updateConstraints { (m) in
                m.width.equalTo(canShowSystem ? 52 : 0)
            }
        }
    }
    
    var sendMsgBlock : ((String,Bool,Bool,[String])->())?
    var sendImgsBlock : (([UIImage],Bool)->())?
    var group: IMGroupDetailInfoModel?
    
    lazy var moreBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("input_more"), for: .normal)
        btn.enlargeClickEdge(10, 10, 10, 10)
        return btn
    }()
    
    lazy var voiceBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.tintColor = FZM_TintColor
        btn.setImage(GetBundleImage("input_voice")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.enlargeClickEdge(10, 10, 10, 10)
        return btn
    }()
    
    lazy var keyboardBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.tintColor = FZM_TintColor
        btn.setImage(GetBundleImage("input_keyboard")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.enlargeClickEdge(10, 10, 10, 10)
        return btn
    }()
    
    lazy var textView : UITextView = {
        let tv = UITextView()
        tv.font = UIFont.regularFont(16)
        tv.returnKeyType = .send
        tv.backgroundColor = UIColor.clear
        tv.textColor = FZM_BlackWordColor
        tv.tintColor = FZM_TintColor
        tv.showsHorizontalScrollIndicator = false
        tv.addSubview(placeLab)
        placeLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(10)
            m.size.equalTo(CGSize(width: 180, height: 20))
        })
        tv.delegate = self
        return tv
    }()
    
    lazy var placeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "想说点什么")
    }()
    
    lazy var ctrlTypeView : UILabel = {
        let lab = UILabel.getLab(font: UIFont.iconfont(ofSize: 14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "普通\(FZMIconFont.down.rawValue)")
        lab.isUserInteractionEnabled = true
        lab.clipsToBounds = true
        return lab
    }()
    
    var recordHelper:AudioMessageManager!
    var lastSendVoicePath = "" //用于松开手指的时候判断是否已发送
    let recordHub: IMRecordTipHub = IMRecordTipHub(with: .recording)
    
    
    lazy var recordVoiceBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 5
        btn.clipsToBounds = true
        btn.layer.borderWidth = 1
        btn.layer.borderColor = FZM_TintColor.cgColor
        btn.setAttributedTitle(NSAttributedString(string: "按住说话", attributes: [.foregroundColor:FZM_TintColor,.font:UIFont.regularFont(16)]), for: .normal)
        btn.setAttributedTitle(NSAttributedString(string: "松开结束", attributes: [.foregroundColor:FZM_TintColor,.font:UIFont.regularFont(16)]), for: .highlighted)
        btn.setBackgroundColor(color: UIColor(hex: 0xE7F5FC), state: .normal)
        btn.setBackgroundColor(color: UIColor(hex: 0xD0E6F2), state: .highlighted)
        return btn
    }()
    
    lazy var bannedView : UILabel = {
        let lab = UILabel.getLab(font: UIFont.mediumFont(16), textColor: UIColor.white, textAlignment: .center, text: nil)
        lab.backgroundColor = UIColor(hex: 0x142E4D, alpha: 0.8)
        lab.isHidden = true
        lab.isUserInteractionEnabled = true
        return lab
    }()
    
    //阅后即焚
    var isBurnAfterRead = false {
        didSet{
            let color = isBurnAfterRead ? FZM_OrangeColor : FZM_TintColor
            voiceBtn.tintColor = color
            keyboardBtn.tintColor = color
            moreBtn.isHidden = isBurnAfterRead
            recordVoiceBtn.layer.borderColor = color.cgColor
            recordVoiceBtn.setAttributedTitle(NSAttributedString(string: "按住说话", attributes: [.foregroundColor:color,.font:UIFont.regularFont(16)]), for: .normal)
            recordVoiceBtn.setAttributedTitle(NSAttributedString(string: "松开结束", attributes: [.foregroundColor:color,.font:UIFont.regularFont(16)]), for: .highlighted)
            recordVoiceBtn.setBackgroundColor(color: isBurnAfterRead ? UIColor(hex: 0xF9EEE7) : UIColor(hex: 0xE7F5FC), state: .normal)
            recordVoiceBtn.setBackgroundColor(color: isBurnAfterRead ? UIColor(hex: 0xF2E3D9) : UIColor(hex: 0xD0E6F2), state: .highlighted)
            cancelBurnBtn.isHidden = !isBurnAfterRead
            imageBurnBtn.isHidden = !isBurnAfterRead
            ctrlTypeView.snp.updateConstraints { (m) in
                m.width.equalTo(canShowSystem && !isBurnAfterRead ? 52 : 0)
            }
            recordVoiceBtn.snp.updateConstraints { (m) in
                m.right.equalToSuperview().offset(isBurnAfterRead ? -125 : -75)
            }
            textView.snp.updateConstraints { (m) in
                m.right.equalToSuperview().offset(isBurnAfterRead ? -108 : -58)
            }
            self.ctrlText()
        }
    }//是否为阅后即焚模式
    var cancelBurnBlock : NormalBlock?
    
    lazy var cancelBurnBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("input_burn_cancel"), for: .normal)
        btn.enlargeClickEdge(5, 5, 5, 5)
        return btn
    }()
    
    lazy var imageBurnBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("input_burn_image"), for: .normal)
        btn.enlargeClickEdge(5, 5, 5, 5)
        return btn
    }()
    

    init() {
        super.init(frame: CGRect.zero)
        self.recordHelper = AudioMessageManager()
        self.recordHelper.updateMeterDelegate = self.recordHub
        self.recordHelper.stopRecordCompletion = {
            
        }
        self.recordHelper.recordMaxTimeBlock = {[weak self] in
            self?.endRecordVoiceSend()
        }
        self.initView()
    }
    
    
    private func initView() {
        self.layer.backgroundColor = FZM_BackgroundColor.cgColor
        self.layer.shadowColor = FZM_ShadowColor.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: -4)
        self.layer.shadowRadius = 3
        self.layer.shadowOpacity = 1.0
        self.clipsToBounds = false
        self.addSubview(voiceBtn)
        self.addSubview(keyboardBtn)
        self.addSubview(ctrlTypeView)
        self.addSubview(moreBtn)
        voiceBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(12)
            m.size.equalTo(CGSize(width: 26, height: 26))
        }
        keyboardBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(12)
            m.size.equalTo(CGSize(width: 26, height: 26))
        }
        moreBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-12)
            m.size.equalTo(CGSize(width: 26, height: 26))
        }
        ctrlTypeView.snp.makeConstraints { (m) in
            m.left.equalTo(voiceBtn.snp.right).offset(16)
            m.centerY.equalToSuperview()
            m.height.equalTo(40)
            m.width.equalTo(0)
        }
        keyboardBtn.isHidden = true
        
        self.addSubview(textView)
        textView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(ctrlTypeView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-58)
            m.height.equalTo(42)
        }
        self.addSubview(recordVoiceBtn)
        recordVoiceBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(75)
            m.right.equalToSuperview().offset(-75)
            m.height.equalTo(40)
        }
        recordVoiceBtn.isHidden = true
        
        self.addSubview(cancelBurnBtn)
        cancelBurnBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-12)
            m.size.equalTo(CGSize(width: 26, height: 26))
        }
        self.addSubview(imageBurnBtn)
        imageBurnBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalTo(cancelBurnBtn.snp.left).offset(-25)
            m.size.equalTo(CGSize(width: 26, height: 26))
        }
        cancelBurnBtn.isHidden = true
        imageBurnBtn.isHidden = true
        
        self.addSubview(bannedView)
        bannedView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        
        self.makeAction()
    }
    
    private func makeAction() {
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let window = UIApplication.shared.keyWindow else { return }
            strongSelf.ctrlTypeView.text = strongSelf.isSystemMsg ? "公告\(FZMIconFont.up.rawValue)" : "普通\(FZMIconFont.up.rawValue)"
            let view = FZMMenuView(with: [FZMMenuItem(title: "普通消息", block: {
                strongSelf.isSystemMsg = false
            }),FZMMenuItem(title: "公告消息", block: {
                strongSelf.isSystemMsg = true
            })])
            view.hideBlock = {
                strongSelf.ctrlTypeView.text = strongSelf.isSystemMsg ? "公告\(FZMIconFont.down.rawValue)" : "普通\(FZMIconFont.down.rawValue)"
                strongSelf.ctrlText()
            }
            let fixedRect = strongSelf.ctrlTypeView.superview!.convert(strongSelf.ctrlTypeView.frame, to: window)
            view.show(in: CGPoint(x: fixedRect.minX, y: fixedRect.minY))
        }.disposed(by: disposeBag)
        ctrlTypeView.addGestureRecognizer(tap)
        voiceBtn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
            self?.voiceBtn.isHidden = true
            self?.ctrlTypeView.isHidden = true
            self?.keyboardBtn.isHidden = false
            self?.textView.isHidden = true
            self?.recordVoiceBtn.isHidden = false
        }).disposed(by: disposeBag)
        keyboardBtn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
            self?.voiceBtn.isHidden = false
            self?.ctrlTypeView.isHidden = false
            self?.keyboardBtn.isHidden = true
            self?.textView.isHidden = false
            self?.recordVoiceBtn.isHidden = true
        }).disposed(by: disposeBag)
        moreBtn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
            guard let strongSelf = self else { return }
            if !strongSelf.showMore {
                strongSelf.showMore = true
                strongSelf.showMoreBlock?()
            }
        }).disposed(by: disposeBag)
        
        textView.rx.didChange.subscribe(onNext:{[weak self] in
            guard let strongSelf = self else{ return }
            
        }).disposed(by: disposeBag)
        textView.rx.didBeginEditing.subscribe(onNext:{[weak self] in
            self?.showMore = false
        }).disposed(by: disposeBag)
        
        cancelBurnBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.isBurnAfterRead = false
            strongSelf.cancelBurnBlock?()
        }.disposed(by: disposeBag)
        
        imageBurnBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.endEditing(true)
            FZMBottomSelectView.show(with: [
                FZMBottomOption(title: "从相册选择", block: {
                    FZMUIMediator.shared().pushVC(.photoLibrary(selectOne: false, maxSelectCount: 9, allowEditing: false, showVideo: false, selectBlock: { (list,_) in
                        strongSelf.sendImgsBlock?(list,strongSelf.isBurnAfterRead)
                    }))
                }),FZMBottomOption(title: "拍照", block: {
                    FZMUIMediator.shared().pushVC(.camera(allowEditing: false, selectBlock: { (list,_) in
                        strongSelf.sendImgsBlock?(list,strongSelf.isBurnAfterRead)
                }))
            })])
        }.disposed(by: disposeBag)
        
        self.setRecordActions()
    }
    
    private func setRecordActions() {
        //按下按钮
        recordVoiceBtn.rx.controlEvent(.touchDown).subscribe(onNext: {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.recordHub.type = .recording
            strongSelf.superview?.addSubview(strongSelf.recordHub)
            strongSelf.recordHub.snp.remakeConstraints({ (m) in
                m.centerY.equalToSuperview()
                m.centerX.equalToSuperview()
            })
            guard let path = FZMLocalFileClient.shared().createFile(with: .wav(fileName: String.getTimeStampStr())) else { return }
            strongSelf.recordHelper.startRecordingWithPath(path) { () -> Void in
                
            }
        }).disposed(by: disposeBag)
        
        //点击开始到结束
        recordVoiceBtn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
                self?.endRecordVoiceSend()
        }).disposed(by: disposeBag)
        
        //松开按钮
        recordVoiceBtn.rx.controlEvent(.touchUpOutside).subscribe(onNext: {[weak self] (_) in
            guard let strongSelf = self else { return }
            self?.recordHub.removeFromSuperview()
            guard let recordPath = strongSelf.recordHelper.recordPath else {
                return
            }
            if strongSelf.lastSendVoicePath != recordPath {
                self?.recordHelper.cancelledDeleteWithCompletion()
            }
        }).disposed(by: disposeBag)
        //取消发送
        recordVoiceBtn.rx.controlEvent(.touchDragExit).subscribe(onNext: {[weak self] (_) in
            self?.recordHub.type = .cancel
        }).disposed(by: disposeBag)
        //录音
        recordVoiceBtn.rx.controlEvent(.touchDragEnter).subscribe(onNext: {[weak self] (_) in
            self?.recordHub.type = .recording
        }).disposed(by: disposeBag)
        
    }
    
    private func endRecordVoiceSend(){
        guard let recordPath = self.recordHelper.recordPath else {
            return
        }
        if self.lastSendVoicePath == recordPath {
            return
        }
        self.lastSendVoicePath = recordPath
        self.recordHelper.finishRecordingCompletion()
        guard let duration = self.recordHelper.recordDuration, let durationNumber = Double(duration), durationNumber >= 1 else {
            self.recordHub.type = .shortTime
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                self.recordHub.removeFromSuperview()
            })
            return
        }
        self.recordHub.removeFromSuperview()
        UIApplication.shared.keyWindow?.showProgress(with: "处理中")
        DispatchQueue.global().async {
            guard let amrPath = FZMLocalFileClient.shared().createFile(with: .amr(fileName: self.recordHelper.recordPath!.fileName())) else { return }
            let result = TSVoiceConverter.convertWavToAmr(self.recordHelper.recordPath!, amrSavePath: amrPath)
            DispatchQueue.main.async {
                UIApplication.shared.keyWindow?.hideProgress()
                if result {
                    self.recordAudioCompleteBlock?(amrPath,self.recordHelper.recordPath!,durationNumber,self.isBurnAfterRead)
                }else {
                    IMLog("转码失败")
                }
            }
        }
    }
    
    //是否显示 普通消息和系统消息切换栏
    func showSystem(_ show: Bool) {
        canShowSystem = show
    }
    
    func bannedCtrl(with time: Double) {
        if time > 0 {
            bannedView.isHidden = false
            if time > OnedaySeconds {
                bannedView.text = "禁言中"
            }else {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                FZMAnimationTool.countdown(with: bannedView, fromValue: time, toValue: 0, block: { [weak self] (useTime) in
                    let time = useTime - 8 * 3600
                    let date = Date.init(timeIntervalSince1970: TimeInterval(time))
                    self?.bannedView.text = "禁言中 " + formatter.string(from: date)
                    },finishBlock: {[weak self] in
                        self?.bannedView.isHidden = true
                })
            }
        }else {
            bannedView.isHidden = true
            FZMAnimationTool.removeCountdown(with: bannedView)
        }
    }
    
    func showState(_ state: FZMInputBarShowState) {
        switch state {
        case .detail:
            self.isHidden = false
            self.textView.isHidden = false
            self.ctrlText()
        case .normal:
            self.isHidden = false
            self.textView.isHidden = true
            self.snp.updateConstraints { (m) in
                m.height.equalTo(70)
            }
        case .hide:
            self.isHidden = true
            self.snp.updateConstraints { (m) in
                m.height.equalTo(0)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBlankRow() {
        guard let range = textView.selectedTextRange else { return }
        self.textView.replace(range, withText: "\n")
    }
    
    private let atCache = FZMInputAtItemCache.init()
    
    func addAt(_ item: FZMInputAtItem) {
        guard let _ = self.group,let range = textView.selectedTextRange else { return }
        self.atCache.add(item)
        self.textView.replace(range, withText: item.name)
    }
    
    private func showSelectAtGroupMemberVC() {
        guard let group = self.group,let range = textView.selectedTextRange else { return }
        let vc = FZMAtPeopleVC.init(with: group)
        vc.selectedBlock = {[weak self] (atItem) in
            guard let strongSelf = self else { return }
            strongSelf.addAt(atItem)
            strongSelf.textView.becomeFirstResponder()
        }
        vc.cancelBlock = {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.textView.replace(range, withText: "@")
            strongSelf.textView.becomeFirstResponder()
        }
        UIViewController.current()?.present(FZMNavigationController.init(rootViewController: vc), animated: true, completion: nil)
    }
    
}

extension FZMInputBar: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let text = self.textView.text, text.count > 0 {
                var isEmpty = true
                text.forEach { (c) in
                    if c != " " && c != "\n" {
                        isEmpty = false
                    }
                }
                if !isEmpty {
                    self.textView.snp.updateConstraints { (m) in
                        m.height.equalTo(42)
                    }
                    self.snp.updateConstraints { (m) in
                        m.height.equalTo(70)
                    }
                    let atUids = self.atCache.getAllAtUids(by:self.textView.text)
                    self.sendMsgBlock?(self.textView.text,self.isSystemMsg,self.isBurnAfterRead,atUids)
                }
                self.atCache.clear()
                self.textView.text = nil
                self.placeLab.isHidden = false
            }
            return false
        }
        if !self.isBurnAfterRead && group != nil && text == "@" {
            self.showSelectAtGroupMemberVC()
            return false
        }
        
        if (group != nil && text == "" && range.length == 1) {
            let subInputText = self.textView.text.substring(to: range.location)
            if let needDelRange = self.getDeleteAtRange(in: subInputText) {
                let deletedAtInputText = (subInputText as NSString).replacingCharacters(in: needDelRange, with: "")
                DispatchQueue.main.async {
                    textView.text = deletedAtInputText + textView.text.substring(from: range.location + 1)
                    textView.selectedRange = NSRange.init(location: deletedAtInputText.count, length: 0)
                }
                return false
            }
        }
        return true
    }
    func textViewDidChange(_ textView: UITextView) {
        self.ctrlText()
    }
    
    func ctrlText() {
        if isSystemMsg {
            textView.limitText(with: 50)
        }else if isBurnAfterRead {
            textView.limitText(with: 500)
        }else {
            textView.limitText(with: 6000)
        }
        placeLab.isHidden = textView.text.count > 0
        var height = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height + 3
        if height > 140 {
            height = 140
        }
        self.updateConstraints(with: 0.3, updateBlock: {
            self.textView.snp.updateConstraints({ (m) in
                m.height.equalTo(height)
            })
            self.snp.updateConstraints({ (m) in
                m.height.equalTo(height > 70 ? height : 70)
            })
        }) {
            self.textView.scrollRangeToVisible(self.textView.selectedRange)
        }
    }
    
    private func getDeleteAtRange(in text: String) -> NSRange? {
        guard let range = self.atCache.atItemRang(in: text) else { return nil}
        return range
    }
}

