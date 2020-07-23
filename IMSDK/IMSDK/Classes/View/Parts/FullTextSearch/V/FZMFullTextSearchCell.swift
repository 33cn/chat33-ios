//
//  FZMFullTextSearchCell.swift
//  IMSDK
//
//  Created by .. on 2019/9/20.
//

import UIKit
import RxSwift

class FZMFullTextSearchCell: UITableViewCell {
    let disposeBag = DisposeBag.init()
    lazy var headerImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.contentMode = .scaleAspectFill
        return imV
    }()
    
    lazy var timeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_TintColor, textAlignment: .right, text: nil)
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    var searchString: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        
        self.contentView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-90)
            m.height.equalTo(23)
        }
        self.contentView.addSubview(timeLab)
        timeLab.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-10)
            m.top.equalTo(headerImageView)
        }
        self.contentView.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.left.right.equalTo(nameLab)
            m.top.equalTo(nameLab.snp.bottom).offset(3)
            m.bottom.equalToSuperview().offset(-5)
            m.height.equalTo(17)
        }
    }
    
    func configure(with model: IMFullTextSearchVM) {
        self.headerImageView.image = nil
        self.nameLab.attributedText = nil
        self.desLab.attributedText = nil
        self.nameLab.text = nil
        self.desLab.text = nil
        self.timeLab.text = nil
        self.desLab.snp.updateConstraints { (m) in
            m.height.equalTo(5)
        }
        
        model.avatarSubject.subscribe(onNext: {[weak self] (avatar) in
            if case FZMFullTextSearchType.chatRecord(_) = model.type, let msg = model.msgs.first {
                self?.headerImageView.loadNetworkImage(with: model.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage(msg.channelType == .group ? "chat_group_head" : "chat_normal_head"))
            } else {
                self?.headerImageView.loadNetworkImage(with: model.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage(model.type == .group ? "chat_group_head" : "chat_normal_head"))
            }
        }).disposed(by: disposeBag)
        
        model.nameSubject.subscribe(onNext: {[weak self] (name) in
            self?.nameLab.text = model.showName
            if self?.searchString != nil {
                self?.dealSearchString(data: model, name: model.showName)
            }
        }).disposed(by: disposeBag)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}



extension FZMFullTextSearchCell {
    
    private func dealSearchString(data: IMFullTextSearchVM, name: String) {
        if let searchString = self.searchString {
            if case let FZMFullTextSearchType.chatRecord(_) = data.type {
                let desString = data.remark
                self.desLab.text = desString
                self.desLab.snp.updateConstraints { (m) in
                    m.height.equalTo(15)
                }
                if data.msgs.count ==  1 {
                    let attStr = NSMutableAttributedString.init(string: desString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                    attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(desString.lowercased() as NSString).range(of: searchString.lowercased()))
                    self.desLab.attributedText = attStr
                    self.timeLab.text = String.yyyyMMddDateString(with: data.msgs.first?.datetime ?? 0)
                }
            } else {
                if name.lowercased().contains(searchString.lowercased()) {
                    let attStr = NSMutableAttributedString.init(string: name, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                    attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(name.lowercased() as NSString).range(of: searchString.lowercased()))
                    self.nameLab.attributedText = attStr
                } else {
                    if data.type == .friend {
                        self.nameLab.text = name
                        var desString = ""
                        if data.name.lowercased().contains(searchString.lowercased()) {
                            desString = "昵称: " + data.name
                        }
                        guard desString != "" else { return }
                        self.desLab.snp.updateConstraints { (m) in
                            m.height.equalTo(15)
                        }
                        let attStr = NSMutableAttributedString.init(string: desString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                        attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(desString.lowercased() as NSString).range(of: searchString.lowercased()))
                        self.desLab.attributedText = attStr
                    }
                }
            }
        }
    }
}
