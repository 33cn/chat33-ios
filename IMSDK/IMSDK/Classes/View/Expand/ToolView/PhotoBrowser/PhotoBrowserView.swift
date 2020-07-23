//
//  PhotoBrowserView.swift
//  IM_SocketIO_Demo
//
//  Created by Wang on 2018/6/1.
//  Copyright © 2018年 Wang. All rights reserved.
//

import UIKit
import RxSwift
import YYWebImage

class PhotoBrowserView: UIView {

    var dismissSelf: ((UIImageView) -> Void)?
    var dataModel: BrowserViewable = BrowserViewable()
    fileprivate lazy var scroll: UIScrollView = {
        let scv = UIScrollView()
        scv.clipsToBounds = true
        scv.showsHorizontalScrollIndicator = false
        scv.showsVerticalScrollIndicator = false
        return scv
    }()
    
    lazy var imageView: UIImageView = {
        let imgV = UIImageView()
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFit
        return imgV
    }()
    weak var alphaView: UIView? //用于下滑改变alpha的背景图
    fileprivate var canMoveDismiss = false //手指移动时是否可以开始缩小
    var distanceValue: (CGFloat, CGFloat) = (0, 0)
    fileprivate lazy var bgView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black
        return v
    }()
    var downloadSuccess = false
    fileprivate var disposeBag = DisposeBag()
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        initData()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        scroll.frame = frame
        reloadFrames()
    }
    fileprivate func initView() {
        bgView.frame = bounds
        addSubview(bgView)
        scroll.frame = bounds
        scroll.delegate = self
        imageView.frame = bounds
        scroll.addSubview(imageView)
        addSubview(scroll)
    }
    fileprivate func initData() {
        //单击手势
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tap)
        tap.rx.event.subscribe {[weak self] (_) in
            self?.viewDidTap()
        }.disposed(by: disposeBag)
       
        //双击手势
        let doubleTap = UITapGestureRecognizer()
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        doubleTap.rx.event.subscribe {[weak self] (_) in
            self?.viewDidDoubleTap(doubleTap)
            }.disposed(by: disposeBag)
        tap.require(toFail: doubleTap)
        //长按手势
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let ges) = event else { return }
            if ges.state == .began {
                self?.viewDidLongPressed()
            }
            }.disposed(by: disposeBag)
        self.addGestureRecognizer(longPress)
        //拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(PhotoBrowserView.viewDidPan(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }
    
    @objc fileprivate func viewDidPan(_ pan: UIPanGestureRecognizer) {
        guard self.downloadSuccess else {return}
        let windowRect = (self.convert(self.frame, to: UIApplication.shared.keyWindow))
        guard windowRect.origin.x == 0 else { return }//在屏幕中有效
        let movePoint = pan.translation(in: self)
        let velocity = pan.velocity(in: self)
        let panLocation = pan.location(in: self)
        switch pan.state {
        case .began:
            guard scroll.zoomScale == 1 else { return }
            /*
             if velocity.y > 1000 {//滑动速率过快，直接关闭
             if let dismissSelf = dismissSelf {
             let fixValue = 1/(fabs(movePoint.y) + 100) * 100
             scroll.setZoomScale(fixValue , animated: true)
             imageView.center = CGPoint(x: panLocation.x + distanceValue.0 * fixValue, y: panLocation.y + distanceValue.1 * fixValue)
             bgView.alpha = fixValue
             dismissSelf(self.imageView)
             return
             }
             }else {
             }
             */
            canMoveDismiss = velocity.y > 0 && fabs(velocity.y) >= fabs(velocity.x)
            if canMoveDismiss {
                bgView.alpha = 1.0
                bgView.isHidden = false
                alphaView?.backgroundColor = UIColor.clear
                let panPoint = pan.location(in: self)
                scroll.minimumZoomScale = 0.2
                distanceValue.0 = imageView.center.x - panPoint.x
                distanceValue.1 = imageView.center.y - panPoint.y
            }
            
        case .changed:
            if canMoveDismiss {//移动缩小
                let movePointY: CGFloat = fabs(movePoint.y)
                let totalmovePointY: CGFloat = movePointY + 100
                let tempmovePointY = 1 / totalmovePointY
                let fixValue: CGFloat = tempmovePointY * 100
                scroll.setZoomScale(fixValue, animated: true)
                imageView.center = CGPoint(x: panLocation.x + distanceValue.0 * fixValue, y: panLocation.y + distanceValue.1 * fixValue)
                bgView.alpha = fixValue
            }
        case .ended:
            if canMoveDismiss, let dismissSelf = dismissSelf, (scroll.zoomScale <= 0.6 || imageView.frame.origin.y >= ScreenBounds.height - 80 || panLocation.y >= ScreenBounds.height - 20) {//最后消失(消失的条件：缩小的足够倍数，图片快到底了，手指到底)
                imageView.frame.size = scroll.contentSize
                dismissSelf(self.imageView)
            } else if scroll.zoomScale <= 1 {
                resetScroll()
            }
        default://其它情况，image归位
            resetScroll()
        }
    }
    func resetScroll() {
        alphaView?.backgroundColor = UIColor.black
        bgView.isHidden = true
        scroll.minimumZoomScale = 0.6
        canMoveDismiss = false
        scroll.setZoomScale(1, animated: true)
        imageView.center = scrollContentCenter(scroll)
    }
    func pb_setImageWithUrl(_ urlString: String, placeHolder: UIImage?, finishBlock: OptionImageBlock? = nil) {
        self.downloadSuccess = false
        resetScroll()
//        waitingView.removeFromSuperview()
        guard let imgURL = URL(string: urlString) else {
            imageView.image = placeHolder
            return
        }
        //查询图片缓存
        self.imageView.yy_setImage(with: imgURL, placeholder: placeHolder, options: .setImageWithFadeAnimation, progress: { (current, total) in
            let _ = CGFloat(current) / CGFloat(total)
        }, transform: nil) { (img, _, _, _, error) in
            self.scroll.setZoomScale(1.0, animated: true)
            if error == nil {
                self.downloadSuccess = true
                self.layoutSubviews()
            }
            finishBlock?(img)
        }
    }
    fileprivate func reloadFrames() {
        if let image = self.imageView.image, self.downloadSuccess {
            let screenBounds = UIScreen.main.bounds
            //图片缩放
            let imageH = screenBounds.width / image.size.width * image.size.height
            imageView.size = CGSize(width: ScreenBounds.width, height: min(imageH, ScreenBounds.height))
            scroll.contentSize = CGSize(width: ScreenBounds.width, height:min(imageH, ScreenBounds.height))
            imageView.center = scrollContentCenter(scroll)
            let h_ratio = image.size.height / self.height
            let w_ratio = image.size.width / self.width  //缩放比例(图片宽为self.width时)
            let screenRatio = self.height / imageH
            let maxRatio = max(h_ratio, w_ratio, screenRatio, 2)
            scroll.minimumZoomScale = 1
            scroll.maximumZoomScale = maxRatio
            scroll.zoomScale = 1.0
        } else {
            imageView.frame = UIScreen.main.bounds
            scroll.contentSize = imageView.frame.size
        }
        scroll.contentOffset = CGPoint.zero
    }
    
    fileprivate func viewDidTap() { //单击
        if let dismissSelf = dismissSelf {
            dismissSelf(self.imageView)
            //            if scroll.zoomScale > 1 {
            //                scroll.setZoomScale(1, animated: true)
            //                let delay = DispatchTime.now() + 0.2
            //                DispatchQueue.main.asyncAfter(deadline: delay) {
            //                    dismissSelf(self.imageView)
            //                }
            //            } else {
            //                dismissSelf(self.imageView)
            //            }
        }
    }
    fileprivate func viewDidDoubleTap(_ doubleTap: UITapGestureRecognizer) {
        guard self.downloadSuccess else {return}
        guard let _ = imageView.image else {return}
        if scroll.zoomScale <= 1 {
            let zoomX = doubleTap.location(in: self).x + scroll.contentOffset.x
            let zoomY = doubleTap.location(in: self).y + scroll.contentOffset.y
            scroll.zoom(to: CGRect(x: zoomX, y: zoomY, width: 0, height: 0), animated: true)
            //            scroll.setZoomScale(2, animated: true)
        } else {//放大状态,双击还原
            scroll.setZoomScale(1, animated: true)
        }
    }
    fileprivate func viewDidLongPressed() {
        guard let img = self.imageView.image else { return }
        if let str = FZMQRCodeGenerator.detectorQRCode(with: img) {
            FZMBottomSelectView.show(with: [
                FZMBottomOption(title: "转发图片", block: {[weak self] in
                    guard let strongSelf = self else { return }
                    guard let image = strongSelf.imageView.image else { return }
                    FZMUIMediator.shared().pushVC(.multipleSendMsg(type: .image(image: image)))
                }),FZMBottomOption(title: "保存图片", block: {[weak self] in
                    self?.saveBtnClick()
                }),FZMBottomOption(title: "识别图中二维码", block: {[weak self] in
                    self?.viewDidTap()
                    FZMUIMediator.shared().parsingUrl(with: str)
                })])
        }else {
            FZMBottomSelectView.show(with: [
                FZMBottomOption(title: "转发图片", block: {[weak self] in
                    guard let strongSelf = self else { return }
                    guard let image = strongSelf.imageView.image else { return }
                    FZMUIMediator.shared().pushVC(.multipleSendMsg(type: .image(image: image)))
                }),FZMBottomOption(title: "保存图片", block: {[weak self] in
                    self?.saveBtnClick()
                })])
        }
    }
    fileprivate func scrollContentCenter(_ scrollView: UIScrollView) -> CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
            (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        
        let actualCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    @objc func saveBtnClick() {
        guard let img = self.imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(PhotoBrowserView.image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        var showMessage = ""
        if error != nil{
            showMessage = "图片保存失败"
        }else{
            showMessage = "图片已保存"
            
        }
        UIApplication.shared.keyWindow?.showToast(with: showMessage)
    }

}
extension PhotoBrowserView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {//不下滑缩小的时候允许collectionview的滑动
        if let otherView = otherGestureRecognizer.view, otherView.isKind(of: UICollectionView.self), !canMoveDismiss {
            return true
        }
        return false
    }
}
extension PhotoBrowserView: UIScrollViewDelegate {
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if !canMoveDismiss {
            imageView.center = scrollContentCenter(scrollView)
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard self.downloadSuccess else {return nil}
        return imageView
    }
}
