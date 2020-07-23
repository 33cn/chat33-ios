//
//  UIViewController+Tool.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/25.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

extension UIViewController{
    
    var safeArea : ConstraintRelatableTarget {
        return self.view.safeArea
    }
    
    var safeTop : ConstraintItem {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaLayoutGuide.snp.top
        }
        return self.view.snp.top
    }
    
    var safeBottom : ConstraintItem {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaLayoutGuide.snp.bottom
        }
        return self.view.snp.bottom
    }
    
    var safeCenterY : ConstraintItem {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaLayoutGuide.snp.centerY
        }
        return self.view.snp.centerY
    }
    
    func showProgress(with text : String? = nil){
        self.view.showProgress(with: text)
    }
    
    func hideProgress(){
        self.view.hideProgress()
    }
    
    func showToast(with text: String){
        self.view.showToast(with: text)
    }
    
}

extension UIViewController :UIDocumentInteractionControllerDelegate {
    
    func previewDocument(url:URL,name:String = "") {
        let vc = UIDocumentInteractionController.init(url: url)
        vc.delegate = self
        vc.name = name
        let canOpen = vc.presentPreview(animated: true)
        if !canOpen {
            if var navRect = self.navigationController?.navigationBar.frame {
                navRect.size = CGSize.init(width: 1500, height: 40)
                vc.presentOpenInMenu(from: navRect, in: self.view, animated: true)
            }
        }
    }
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
}

extension UIViewController {
    class func current(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return current(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return current(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return current(base: presented)
        }
        return base
    }
}
