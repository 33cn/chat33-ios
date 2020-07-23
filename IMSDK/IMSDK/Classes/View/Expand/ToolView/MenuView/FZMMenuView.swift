//
//  FZMMenuView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/15.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift

class FZMMenuView: UIView {
    
    var hideBlock : NormalBlock?
    
    let disposeBag = DisposeBag()
    
    var itemArr = [FZMMenuItem]()
    
    lazy var listView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.isScrollEnabled = false
        view.makeOriginalShdowShow()
        view.layer.backgroundColor = UIColor.white.cgColor
        view.separatorStyle = .none
        view.rowHeight = 40
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "FZMMenuViewCell")
        return view
    }()
    
    init(with arr: [FZMMenuItem]) {
        super.init(frame: ScreenBounds)
        itemArr += arr
        let control = UIControl(frame: ScreenBounds)
        control.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.hide()
        }.disposed(by: disposeBag)
        self.addSubview(control)
    }
    
    func show(in point: CGPoint) {
        UIApplication.shared.keyWindow?.addSubview(self)
        self.addSubview(listView)
        let height = CGFloat(itemArr.count*40)
        listView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize(width: 100, height: height))
            if point.y + height > ScreenHeight - 100 {
                m.bottom.equalToSuperview().offset(point.y - ScreenHeight)
            }else {
                m.top.equalToSuperview().offset(point.y)
            }
            if point.x > ScreenWidth / 2 {
                m.right.equalToSuperview().offset(point.x - ScreenWidth)
            }else {
                m.left.equalToSuperview().offset(point.x)
            }
        }
    }
    
    func hide() {
        hideBlock?()
        self.removeFromSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FZMMenuView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMMenuViewCell", for: indexPath)
        let item = itemArr[indexPath.row]
        cell.clipsToBounds = false
        cell.backgroundColor = UIColor.clear
        cell.contentView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: item.title)
        cell.contentView.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = itemArr[indexPath.row]
        item.block?()
        self.hide()
    }
}

class FZMMenuItem: NSObject {
    
    let title: String
    
    let block: NormalBlock?
    init(title: String, block: NormalBlock?) {
        self.title = title
        self.block = block
        super.init()
    }
}



class FZMImageMenuView: UIView {
    
    var hideBlock : NormalBlock?
    
    let disposeBag = DisposeBag()
    
    var itemArr = [FZMImageMenuItem]()
    
    lazy var listView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.isScrollEnabled = false
        view.makeOriginalShdowShow()
        view.layer.backgroundColor = UIColor.white.cgColor
        view.separatorStyle = .none
        view.rowHeight = 40
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "FZMMenuViewCell")
        return view
    }()
    
    init(with arr: [FZMImageMenuItem]) {
        super.init(frame: ScreenBounds)
        itemArr += arr
        let control = UIControl(frame: ScreenBounds)
        control.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.hide()
            }.disposed(by: disposeBag)
        self.addSubview(control)
    }
    
    func show(in point: CGPoint) {
        UIApplication.shared.keyWindow?.addSubview(self)
        self.addSubview(listView)
        let height = CGFloat(itemArr.count*40)
        listView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize(width: 150, height: height))
            if point.y + height > ScreenHeight - 100 {
                m.bottom.equalToSuperview().offset(point.y - ScreenHeight)
            }else {
                m.top.equalToSuperview().offset(point.y)
            }
            if point.x > ScreenWidth / 2 {
                m.right.equalToSuperview().offset(point.x - ScreenWidth)
            }else {
                m.left.equalToSuperview().offset(point.x)
            }
        }
    }
    
    func hide() {
        hideBlock?()
        self.removeFromSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FZMImageMenuView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMMenuViewCell", for: indexPath)
        let item = itemArr[indexPath.row]
        cell.clipsToBounds = false
        cell.backgroundColor = UIColor.clear
        cell.contentView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: item.title)
        cell.contentView.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalToSuperview().offset(46)
        }
        let imageV = UIImageView(image: item.image)
        cell.contentView.addSubview(imageV)
        imageV.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.centerX.equalTo(cell.contentView.snp.left).offset(23)
            m.size.equalTo(item.imageSize)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = itemArr[indexPath.row]
        item.block?()
        self.hide()
    }
}

class FZMImageMenuItem: NSObject {
    
    let title: String
    let image: UIImage?
    let imageSize: CGSize
    let block: NormalBlock?
    init(title: String, image: UIImage?, size: CGSize, block: NormalBlock?) {
        self.title = title
        self.block = block
        self.image = image
        self.imageSize = size
        super.init()
    }
}
