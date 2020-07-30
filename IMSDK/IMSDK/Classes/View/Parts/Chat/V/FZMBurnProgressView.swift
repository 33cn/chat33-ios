//
//  FZMBurnProgressView.swift
//  IMSDK
//
//  Created by .. on 2019/1/22.
//

import UIKit

class FZMBurnProgressView: UIView {
    
    var countDownCompleteBlock : NormalBlock?
    fileprivate lazy var lineView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: StatusBarHeight, width: ScreenWidth, height: 5))
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.backgroundColor = UIColor(hex: 0xF9EEE7)
        view.addSubview(self.progressLine)
        return view
    }()
    fileprivate lazy var progressLine : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 5))
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.backgroundColor = FZM_OrangeColor
        return view
    }()
    
    fileprivate lazy var countDownTimeView : FZMCountdownLab = {
        let view = FZMCountdownLab()
        return view
    }()
    
    init(endTime: Double) {
        super.init(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 30))
        self.backgroundColor = UIColor.black
        self.addSubview(lineView)
        self.addSubview(countDownTimeView)
        countDownTimeView.snp.makeConstraints { (m) in
            m.top.equalTo(lineView.snp.bottom).offset(11)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize.zero)
        }
        self.countDown(endTime: endTime)
    }
    
    private func countDown(endTime: Double) {
        guard endTime > 0 else { return }
        FZMAnimationTool.countdown(with: countDownTimeView, fromValue: endTime, toValue: 0, block: { (time) in
            self.countDownTimeView.setTime(Int(time))
            self.progressLine.frame = CGRect(x: 0, y: 0, width: ScreenWidth * (30 - time) / 30, height: 5)
        }) {
            self.countDownCompleteBlock?()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
