//
//  FZMWebViewController.swift
//  IMSDK
//
//  Created by .. on 2019/4/18.
//

import UIKit

class FZMWebViewController: FZMBaseViewController {

    var url: String = ""
    
    lazy var webView: WKWebView = {
       let v = WKWebView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - StatusNavigationBarHeight))
        if let url = URL.init(string: self.url) {
            v.load(URLRequest.init(url: url))
        }
        return v
    }()
    
    lazy var progressView: UIProgressView = {
        let v = UIProgressView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: 1))
        v.tintColor = FZM_TintColor
        v.trackTintColor = .clear
        v.progress = 0
        return v
    }()
    
    var progress:Float = 0 {
        didSet {
            self.title = webView.title
            self.progressView .setProgress(progress, animated: true)
            if progress >= 1 {
                self.progressView.isHidden = true
                self.progressView.progress = 0
            }
        }
    }
    
    let estimatedProgress = "estimatedProgress"
    
    deinit {
        self.webView.removeObserver(self, forKeyPath: estimatedProgress)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)
        self.view.addSubview(progressView)
        webView.addObserver(self, forKeyPath: estimatedProgress, options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == estimatedProgress {
            progress = Float(self.webView.estimatedProgress)
        }
    }

}
