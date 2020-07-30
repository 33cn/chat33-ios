//
//  ViewController.swift
//  IMSDK
//
//  Created by Laughing on 12/25/2018.
//  Copyright (c) 2018 Laughing. All rights reserved.
//

import UIKit
import IMSDK
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print(IMSDK.sdkVersion())
        let configure = IMSDKConfigureModel()
        IMSDK.launchApp(configure)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

