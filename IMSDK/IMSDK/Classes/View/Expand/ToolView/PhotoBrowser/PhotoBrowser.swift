//
//  PhotoBrowser.swift
//  IM_SocketIO_Demo
//
//  Created by Wang on 2018/6/4.
//  Copyright © 2018年 Wang. All rights reserved.
//

import UIKit
// 显示数据的模型
class BrowserViewable: NSObject {
    // 小图地址
    var thumbnailUrl: String?
    // 小图
    var placeholder: UIImage?
    // 大图地址
    var imageUrl: String?
    // 图文信息
    var attributedTitle: NSAttributedString?
}
// 所有Cell,view需要实现的方法和属性
protocol BrowserVCHandler {
    var dataModel: BrowserViewable {get} // 当前数据模型
    var dismissSelf:((_ fadeOutView: UIImageView) -> Void)? {get}
}
class PhotoBrowser: NSObject {
    var modelArray = [BrowserViewable]()
    fileprivate lazy var mainCollectionView: UICollectionView = {
        let collectionBounds = CGRect(x: 0, y: 0, width: ScreenBounds.width + 20, height: ScreenBounds.height)
        //布局cell大小
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = collectionBounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        //创建collectionview
        let collectionView = UICollectionView(frame: collectionBounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        collectionView.bounces = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0)
        collectionView.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()
    
    lazy var view: UIView = {
        let v = UIView()
        return v
    }()
    var showing = true
    var fadeInView: UIView?
    var fadeOutViewBlock: ((_ index: Int) -> UIView?)?
    var isCycle = false //是否是轮播图的查看大图
    @objc dynamic var currentIndex = 0
    
    static let singleTon = PhotoBrowser()
    private override init() {
        super.init()
        self.view.frame = ScreenBounds
        view.backgroundColor = UIColor.black
        self.view.addSubview(mainCollectionView)
    }
    
    static func shared() -> PhotoBrowser {
        return singleTon
    }
    // 对外唯一调用的显示方法
    func show(startAt initialShowIndex: Int = 0, source dataSource: [BrowserViewable]) -> PhotoBrowser {
        self.currentIndex = initialShowIndex
        self.modelArray = dataSource
        self.mainCollectionView.reloadData()
        self.mainCollectionView.setContentOffset(CGPoint(x: self.currentIndex * Int((ScreenBounds.width + 20)), y: 0), animated: false)
        if let window = FZMUIMediator.shared().homeTabbarVC?.view {
            window.addSubview(self.view)
        }
        return self
    }
    
    func configurableFade(inView: UIView, outView outViewBlock: @escaping ((_ idx: Int) -> UIView?)) {
        fadeInView = inView
        fadeOutViewBlock = outViewBlock
    }
}

extension PhotoBrowser {
    fileprivate func fadeIn() {
        guard let fadeInView = fadeInView else {
            return
        }
        showing = true
        mainCollectionView.setContentOffset(CGPoint(x: self.currentIndex * Int((ScreenBounds.width + 20)), y: 0), animated: false)
        mainCollectionView.isHidden = true
        let fadeView = UIImageView()
        fadeView.clipsToBounds = true
        fadeView.contentMode = .scaleAspectFit
        fadeView.frame = (fadeInView.superview?.convert(fadeInView.frame, to: view))!
        let model = modelArray[self.currentIndex]
        fadeView.image = model.placeholder
        let finalFrame = CGRectMakeWithCenterAndSize(center: self.view.center, size: CGSize(width: ScreenBounds.width, height: ScreenBounds.height))
        view.addSubview(fadeView)
        UIView.animate(withDuration: 0.3, animations: {
            fadeView.frame = finalFrame
        }) { (_) in
            fadeView.removeFromSuperview()
            self.mainCollectionView.isHidden = false
            self.showing = false
        }
    }
    
    @objc fileprivate func fadeOut(currentView: UIImageView) {
        var fadeOutV: UIView?
        if self.isCycle {
            fadeOutV = self.fadeInView
        } else {
            fadeOutV = fadeOutViewBlock?(self.currentIndex)
        }
        guard let fadeOutView = fadeOutV else {
            view.removeFromSuperview()
            return
        }
        fadeOutView.alpha = 1.0
        let fadeView = UIImageView()
        fadeView.clipsToBounds = true
        fadeView.contentMode = .scaleAspectFit
        fadeView.image = currentView.image
        fadeView.frame = currentView.frame
        let finalFrame = (fadeOutView.superview?.convert(fadeOutView.frame, to: view))!
        if let window = FZMUIMediator.shared().homeTabbarVC?.view {
            window.addSubview(fadeView)
        }
        mainCollectionView.isHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            fadeView.frame = finalFrame
            self.view.alpha = 0.0
            fadeOutView.alpha = 0.0
        }) { (_) in
            fadeOutView.alpha = 1.0
            fadeView.removeFromSuperview()
            self.view.removeFromSuperview()
        }
    }
    func dismissSelf(currentView: UIImageView) {
        fadeOut(currentView: currentView)
    }
}
extension PhotoBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return modelArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PhotoBrowserCell
        cell.dismissSelf = dismissSelf(currentView:)
        let dataModel = modelArray[indexPath.row]
        cell.pb_imageWithUrl(dataModel.imageUrl!, placeHolder: dataModel.placeholder)
        cell.photoView.alphaView = self.view
        cell.backgroundColor =  UIColor.clear
        return cell
    }
    //MARK:
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let sw = scrollView.frame.width
        self.currentIndex = Int((scrollView.contentOffset.x + sw / 2) / sw)
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoCell = cell as! PhotoBrowserCell
        photoCell.resetPhotoScroll()
    }
}
