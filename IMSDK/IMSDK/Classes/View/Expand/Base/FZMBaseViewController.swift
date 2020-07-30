//
//  FZMBaseViewController.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import IQKeyboardManager


let hideBarViewControllers = ["FZMMeCenterVC",
                              "FZMSearchVC",
                              "FZMSweepQRCodeVC",
                              "FZMRedBagRecordVC",
                              "FZMPromoteDetailVC",
                              "FZMFullTextSearchVC",
                              "FZMVideoPlayerController",
                              "FZMRewardRankingVC"
]

class FZMBaseViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    convenience init(navTintColor: UIColor , navBarColor: UIColor , navTitleColor: UIColor) {
        self.init()
        self.navTintColor = navTintColor
        self.navBarColor = navBarColor
        self.navTitleColor = navTitleColor
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    
    var navBarColor: UIColor = FZM_BackgroundColor {
        didSet {
            self.setNavBarColor()
        }
    }
    var navTintColor: UIColor = FZM_TintColor {
        didSet {
            self.setNavTintColor()
        }
    }
    
    var navTitleColor: UIColor = FZM_TitleColor {
        didSet {
            self.setNavTitleColor()
        }
    }
    
    var isAutorotate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.navigationController?.navigationBar.isHidden = hideBarViewControllers.contains("\(type(of: self))")
        
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isTranslucent = false
        self.view.backgroundColor = FZM_BackgroundColor
        self.setNavBarColor()
        self.setNavTintColor()
        self.setNavTitleColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setNavBarColor()
        self.setNavTintColor()
        self.setNavTitleColor()
    }
    
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem(image: GetBundleImage("back_arrow")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(popBack))
    }
    
    private func setNavBarColor() {
        guard let nav = self.navigationController else { return }
        let case1 = !nav.navigationBar.isHidden && self == self.navigationController?.topViewController
        let case2 = self.tabBarController?.selectedViewController == self.navigationController
        guard case1 || case2 else {
            return
        }
        self.navigationController?.navigationBar.barTintColor = navBarColor
        self.navigationController?.navigationBar.shadowImage = UIImage.imageWithColor(with: navBarColor, size: CGSize(width: ScreenWidth, height: 1))
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(with: navBarColor, size: CGSize(width: ScreenWidth, height: 1)), for: .default)
        var white: CGFloat = 0
        let get = self.navBarColor.getWhite(&white, alpha: nil)
        UIApplication.shared.statusBarStyle = get && (white > 0.9) ? .default : .lightContent
    }
    
    private func setNavTintColor() {
        guard let nav = self.navigationController else { return }
        let case1 = !nav.navigationBar.isHidden && self == self.navigationController?.topViewController
        let case2 = self.tabBarController?.selectedViewController == self.navigationController
        guard case1 || case2 else {
            return
        }
        self.navigationController?.navigationBar.tintColor = self.navTintColor
        self.navigationController?.navigationBar.isTranslucent = false
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: self.navTintColor], for: .normal)
        return
        
    }
    
    override var shouldAutorotate: Bool {
        return self.isAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.isAutorotate ? UIInterfaceOrientationMask.allButUpsideDown : UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return  UIInterfaceOrientation.portrait
    }
    
    private func setNavTitleColor() {
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: self.navTitleColor]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
//    override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
//        return .bottom
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    @objc func popBack() {
        guard let nav = self.navigationController else { return }
        if let index = nav.viewControllers.index(of: self), index > 0 {
            if let vc = nav.viewControllers[index - 1] as? FZMBaseViewController {
                self.navTintColor = vc.navTintColor
                self.navBarColor = vc.navBarColor
                self.navTitleColor = vc.navTitleColor
            }
        }
        nav.popViewController(animated: true)
    }
    
    func popLongBack(to getClass: AnyClass) {
        guard let nav = self.navigationController else { return }
        var popVC : FZMBaseViewController?
        nav.viewControllers.forEach { (vc) in
            if vc.isKind(of: getClass) {
                popVC = vc as? FZMBaseViewController
            }
        }
        guard let backVC = popVC else { return }
        self.navTintColor = backVC.navTintColor
        self.navBarColor = backVC.navBarColor
        self.navTitleColor = backVC.navTitleColor
        nav.popToViewController(backVC, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        IMLog("\(type(of: self)) 销毁")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}




