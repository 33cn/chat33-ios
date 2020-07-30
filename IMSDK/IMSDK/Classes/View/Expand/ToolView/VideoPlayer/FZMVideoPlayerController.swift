//
//  FZMVideoPlayerController.swift
//  IMSDK
//
//  Created by .. on 2019/2/18.
//

import UIKit
import RxSwift
import BMPlayer
import AVFoundation
import NVActivityIndicatorView

class FZMVideoPlayerController: FZMBaseViewController {
    fileprivate let videoPath: String
    init(videoPath: String) {
        self.videoPath = videoPath
        super.init()
        self.isAutorotate = true
    }
    
    fileprivate let longPress = UILongPressGestureRecognizer()
    private func setGesture() {
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let ges) = event else { return }
            if ges.state == .began {
                self?.viewDidLongPressed()
            }
        }.disposed(by: disposeBag)
        self.view.addGestureRecognizer(longPress)
    }
       
    
    private func viewDidLongPressed() {
        VoiceMessagePlayerManager.shared().vibrateAction()
        FZMBottomSelectView.show(with: [
            FZMBottomOption(title: "转发给朋友", block: {
                FZMUIMediator.shared().pushVC(.multipleSendMsg(type: .video(videoPath: self.videoPath)))
            }),FZMBottomOption(title: "保存视频", block: {[weak self] in
                self?.saveBtnClick()
            })])
    }
    
    
    private func saveBtnClick() {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.videoPath) {
            UISaveVideoAtPathToSavedPhotosAlbum(self.videoPath, self, #selector(video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    @objc private func video(videoPath: String?, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        var showMessage = ""
        if error != nil{
            showMessage = "视频保存失败"
        }else{
            showMessage = "视频已保存"
            
        }
        UIApplication.shared.keyWindow?.showToast(with: showMessage)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let player = BMPlayer(customControlView: nil)
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGesture()
        setupPlayerManager()
        preparePlayer()
        setupPlayerResource()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc func applicationWillEnterForeground() {
        
    }
    
    @objc func applicationDidEnterBackground() {
        player.pause(allowAutoPlay: false)
    }
    
    /**
     prepare playerView
     */
    func preparePlayer() {
        view.addSubview(player)
        player.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        player.delegate = self
        player.backBlock = { [weak self] (isFullScreen) in
            self?.dismiss(animated: true, completion: nil)
        }
        self.view.layoutIfNeeded()
    }
    
    func setupPlayerResource() {
        let url = URL.init(fileURLWithPath: self.videoPath)
        let asset = BMPlayerResource.init(url: url)
        player.setVideo(resource: asset)
    }
    
    // 设置播放器单例，修改属性
    func setupPlayerManager() {
        BMPlayerConf.allowLog = false
        BMPlayerConf.shouldAutoPlay = true
        BMPlayerConf.tintColor = UIColor.white
        BMPlayerConf.topBarShowInCase = .always
        BMPlayerConf.loaderType  = NVActivityIndicatorType.ballRotateChase
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: false)
        // If use the slide to back, remember to call this method
        // 使用手势返回的时候，调用下面方法
        player.pause(allowAutoPlay: true)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: false)
        // If use the slide to back, remember to call this method
        // 使用手势返回的时候，调用下面方法
        player.autoPlay()
    }

    deinit {
        // If use the slide to back, remember to call this method
        // 使用手势返回的时候，调用下面方法手动销毁
        player.prepareToDealloc()
        print("VideoPlayViewController Deinit")
    }
    
}

// MARK:- BMPlayerDelegate example
extension FZMVideoPlayerController: BMPlayerDelegate {
  // Call when player orinet changed
  func bmPlayer(player: BMPlayer, playerOrientChanged isFullscreen: Bool) {
    self.longPress.isEnabled = !isFullscreen
  }
  
  // Call back when playing state changed, use to detect is playing or not
  func bmPlayer(player: BMPlayer, playerIsPlaying playing: Bool) {
    print("| BMPlayerDelegate | playerIsPlaying | playing - \(playing)")
  }
  
  // Call back when playing state changed, use to detect specefic state like buffering, bufferfinished
  func bmPlayer(player: BMPlayer, playerStateDidChange state: BMPlayerState) {
    print("| BMPlayerDelegate | playerStateDidChange | state - \(state)")
  }
  
  // Call back when play time change
  func bmPlayer(player: BMPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
    //        print("| BMPlayerDelegate | playTimeDidChange | \(currentTime) of \(totalTime)")
  }
  
  // Call back when the video loaded duration changed
  func bmPlayer(player: BMPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
    //        print("| BMPlayerDelegate | loadedTimeDidChange | \(loadedDuration) of \(totalDuration)")
  }
}
