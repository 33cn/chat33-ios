//
//  FZMPromoteDetailVC.swift
//  IMSDK
//
//  Created by .. on 2019/7/1.
//

import UIKit

class FZMPromoteDetailVC: FZMBaseViewController {
    
    
    lazy var topTotalAwardLab: UILabel = {
        let lab = UILabel.init()
        lab.textAlignment = .center
        lab.numberOfLines = 0
        return lab
    }()
    
    lazy var awardScrrolView: UIScrollView = {
        let v = UIScrollView.init()
        v.showsHorizontalScrollIndicator = false
        return v
    }()
    
    var awardItems = [UIView()] {
        didSet {
            guard !awardItems.isEmpty else {return}
            for i in 0..<awardItems.count {
                let item = awardItems[i]
                awardScrrolView.addSubview(item)
                awardScrrolView.contentSize = CGSize.init(width: awardScrrolView.contentSize.width + item.width + 10, height: 0)
                item.snp.makeConstraints { (m) in
                    m.top.equalToSuperview()
                    m.size.equalTo(item.size)
                    if i == 0 {
                        if awardItems.count == 1 {
                            m.centerX.equalToSuperview()
                        } else if awardItems.count > 2 {
                            m.left.equalToSuperview()
                        } else {
                            m.right.equalTo(awardScrrolView.snp.centerX).offset(-5)
                        }
                    } else {
                        m.left.equalTo(awardItems[i - 1].snp.right).offset(10)
                    }
                }
            }
        }
    }
    
    var promoteHeader: FZMPromoteHeader?
    
    lazy var headerView: UIView = {
        let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 225))
        let imageView = UIImageView.init(frame: v.bounds)
        imageView.image = GetBundleImage("me_promote_bg")
        imageView.isUserInteractionEnabled = true
        v.addSubview(imageView)
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(GetBundleImage("back_arrow")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backBtn.tintColor = FZM_WhiteColor
        backBtn.addTarget(self, action: #selector(popBack), for: .touchUpInside)
        backBtn.enlargeClickEdge(20, 20, 20, 20)
        imageView.addSubview(backBtn)
        backBtn.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(StatusNavigationBarHeight - 33)
            m.left.equalToSuperview().offset(20)
            m.size.equalTo(CGSize(width: 10, height: 17))
        }
        
        let titleLab = UILabel.getLab(font: UIFont.boldFont(17), textColor: FZM_WhiteColor, textAlignment: .center, text: "推广详情")
        imageView.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.centerY.equalTo(backBtn)
            m.centerX.equalToSuperview()
        })
        
        let ruleBtn = UIButton.init()
        ruleBtn.setTitle(" 规则", for: .normal)
        ruleBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        ruleBtn.setImage(GetBundleImage("me_promote_rule"), for: .normal)
        ruleBtn.setImage(GetBundleImage("me_promote_rule"), for: .highlighted)
        ruleBtn.addTarget(self, action: #selector(ruleBtnPress), for: .touchUpInside)
        imageView.addSubview(ruleBtn)
        ruleBtn.snp.makeConstraints({ (m) in
            m.centerY.equalTo(titleLab)
            m.right.equalToSuperview().offset(-20)
        })
        
        imageView.addSubview(topTotalAwardLab)
        topTotalAwardLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab.snp.bottom).offset(29)
            m.centerX.equalToSuperview()
        })
        
        imageView.addSubview(awardScrrolView)
        awardScrrolView.snp.makeConstraints({ (m) in
            m.top.equalTo(topTotalAwardLab.snp.bottom).offset(15)
            m.left.equalToSuperview().offset(20)
            m.right.equalToSuperview().offset(-20)
            m.bottom.equalToSuperview()
        })
        return v
    }()
    
    
    @objc func ruleBtnPress() {
        let vc = FZMWebViewController.init()
        vc.url = (qrCodeShareUrl as NSString).replacingOccurrences(of: "share.html?", with: "rule")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func getAwardItemBtn(title: String) -> UIButton {
        let btn = UIButton.init()
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btn.setTitle(title, for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 16, bottom: 0, right: 16)
        btn.frame = CGRect.init(x: 0, y: 0, width: title.getContentWidth(height: 30, font: UIFont.boldSystemFont(ofSize: 14)) + 36, height: 30)
        btn.setBackgroundColor(color: FZM_LightBlueColor, state: .normal)
        btn.setBackgroundColor(color: FZM_LightBlueColor, state: .highlighted)
        btn.setTitleColor(FZM_LightWhiteColor, for: .normal)
        btn.layer.cornerRadius = 15
        btn.layer.masksToBounds = true
        return btn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createUI()

        self.loadHeaderData()
    }
    
    func createUI() {
        self.view.addSubview(self.headerView)
        
        let view1 = FZMPromoteDetailPageView.init(with: "下级奖励")
        let view2 = FZMPromoteAccumulateDetailPageView.init(with: "条件奖励")
        let param = FZMSegementParam()
        
        let pageView = FZMScrollPageView(frame: CGRect(x: 0, y: self.headerView.height, width: ScreenWidth, height: ScreenHeight - self.headerView.height), dataViews: [view1,view2], param: param)
        
        self.view.addSubview(pageView)
        
    }
    
    func loadHeaderData() {
        self.showProgress()
        HttpConnect.shared().getInviteStatistics { (response) in
            self.hideProgress()
            guard response.success, let data = response.data else { return }
            let promoteHeader = FZMPromoteHeader.init(json: data)
            var promoteStatistics = promoteHeader.statistics.compactMap({ (promoteCoin) -> UIButton? in
                if !promoteCoin.currency.isEmpty && !promoteCoin.total.isEmpty {
                    return self.getAwardItemBtn(title: "累计奖励\((Double.init(promoteCoin.total) ?? 0))" + promoteCoin.currency)
                }
                return nil
            })
            promoteStatistics.insert(self.getAwardItemBtn(title: "累计推广\((Int.init(promoteHeader.inviteNum) ?? 0))人"), at: 0)
            self.awardItems = promoteStatistics
            
            let mutAttStr = NSMutableAttributedString.init(string: "累计奖励" + promoteHeader.primary.currency , attributes: [NSAttributedString.Key.foregroundColor: FZM_LightWhiteColor, NSAttributedString.Key.font: UIFont.regularFont(14)])
            let countStr = NSMutableAttributedString.init(string: "\n" + "\((Double.init(promoteHeader.primary.total) ?? 0))" , attributes: [NSAttributedString.Key.foregroundColor: FZM_WhiteColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 30)])
            mutAttStr.insert(countStr, at: mutAttStr.length)
            self.topTotalAwardLab.attributedText = mutAttStr
            self.promoteHeader = promoteHeader
        }
    }
}

