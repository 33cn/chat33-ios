//
//  FZMForwardBar.swift
//  AFNetworking
//
//  Created by 吴文拼 on 2019/1/7.
//

import UIKit
import RxCocoa
import RxSwift

enum FZMForwardBarClickEvent {
    case forward
    case allForward
    case collect
    case delete
    case download
}

class FZMForwardBar: UIView {

    let disposeBag = DisposeBag()
    
    var eventBlock : ((FZMForwardBarClickEvent)->())?
    
    var disableDelete = false {
        didSet {
            if let imageView = deletedView?.viewWithTag(imageViewTag) as? UIImageView {
                imageView.image = GetBundleImage(disableDelete ? "delete_msg_des" : "delete_msg" )
                deletedView?.isUserInteractionEnabled = !disableDelete
            }
        }
    }
    
    private var deletedView: UIView?
    private let imageViewTag = 1083
    
    init() {
        super.init(frame: CGRect.zero)
        self.makeOriginalShdowShow()
    }
    
    convenience init(normal: Bool) {
        self.init()
        guard normal == true else{return}
        let oneForwardView = self.getItemView(imgName: "forward", title: "逐条转发") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.forward)
        }
        let bothForwardView = self.getItemView(imgName: "forward_both", title: "合并转发") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.allForward)
        }
        let deleteView = self.getItemView(imgName: "delete_msg", title: "删除") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.delete)
        }
        self.addSubview(oneForwardView)
        oneForwardView.snp.makeConstraints { (m) in
            m.top.bottom.equalToSuperview()
            m.left.equalToSuperview()
            m.width.equalTo(ScreenWidth/3)
        }
        self.addSubview(bothForwardView)
        bothForwardView.snp.makeConstraints { (m) in
            m.top.bottom.width.equalTo(oneForwardView)
            m.left.equalTo(oneForwardView.snp.right)
        }
        self.addSubview(deleteView)
        deleteView.snp.makeConstraints { (m) in
            m.top.bottom.width.equalTo(oneForwardView)
            m.left.equalTo(bothForwardView.snp.right)
        }
    }
    
    convenience init(withDownload: Bool) {
        self.init()
        guard withDownload == true else{return}
        let oneForwardView = self.getItemView(imgName: "forward", title: "逐条转发") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.forward)
        }
        let bothForwardView = self.getItemView(imgName: "forward_both", title: "合并转发") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.allForward)
        }
        let downloadView = self.getItemView(imgName: "bar_download", title: "下载") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.download)
        }
        let deleteView = self.getItemView(imgName: "delete_msg", title: "删除") {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.eventBlock?(.delete)
        }
        self.deletedView = deleteView
        self.addSubview(oneForwardView)
        oneForwardView.snp.makeConstraints { (m) in
            m.top.bottom.equalToSuperview()
            m.left.equalToSuperview()
            m.width.equalTo(ScreenWidth/4)
        }
        self.addSubview(bothForwardView)
        bothForwardView.snp.makeConstraints { (m) in
            m.top.bottom.width.equalTo(oneForwardView)
            m.left.equalTo(oneForwardView.snp.right)
        }
        self.addSubview(downloadView)
        downloadView.snp.makeConstraints { (m) in
            m.top.bottom.width.equalTo(oneForwardView)
            m.left.equalTo(bothForwardView.snp.right)
        }
        self.addSubview(deleteView)
        deleteView.snp.makeConstraints { (m) in
            m.top.bottom.width.equalTo(oneForwardView)
            m.left.equalTo(downloadView.snp.right)
        }
        
    }
    
    
    func getItemView(imgName: String, title: String, block: NormalBlock? = nil) -> UIView {
        let view = UIView()
        let imV = UIImageView(image: GetBundleImage(imgName))
        imV.tag = imageViewTag
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview().offset(-8)
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 26, height: 26))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: title)
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.top.equalTo(imV.snp.bottom)
            m.centerX.equalToSuperview()
            m.height.equalTo(20)
        })
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe { (_) in
            block?()
        }.disposed(by: disposeBag)
        view.addGestureRecognizer(tap)
        return view
    }
    
    private func makeActions() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
