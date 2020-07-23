//
//  FZMSweepQRCodeVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/5.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import AVFoundation
import pop

class FZMSweepQRCodeVC: FZMBaseViewController {
    
    var session : AVCaptureSession?
    
    lazy var centerView : UIImageView = {
        let view = UIImageView(image: GetBundleImage("tool_sweep_center")?.withRenderingMode(.alwaysTemplate))
        view.tintColor = FZM_TintColor
        view.layer.borderWidth = 2
        view.layer.borderColor = FZM_TintColor.cgColor
        view.addSubview(sweepLine)
        sweepLine.center = CGPoint(x: (ScreenWidth - 110)/2, y: 0)
        return view
    }()
    
    lazy var sweepLine : UIImageView = {
        let view = UIImageView(image: GetBundleImage("tool_sweep_line")?.withRenderingMode(.alwaysTemplate))
        view.tintColor = FZM_TintColor
        view.bounds = CGRect(x: 0, y: 0, width: 309, height: 6)
        return view
    }()
    
    lazy var animation : POPBasicAnimation = {
        let animate = POPBasicAnimation()
        animate.property = (POPAnimatableProperty.property(withName: kPOPViewCenter) as! POPAnimatableProperty)
        animate.toValue = NSValue(cgPoint: CGPoint(x: (ScreenWidth - 110)/2, y: ScreenWidth - 110))
        animate.repeatForever = true
        animate.duration = 1.5
        animate.completionBlock = {[weak self] (_,finished) in
            if finished {
                self?.sweepLine.center = CGPoint(x: (ScreenWidth - 110)/2, y: 0)
            }
        }
        return animate
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navTitleColor = FZM_TintColor
        self.createUI()
        self.setCamera()
    }
    
    private func createUI() {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 55, height: ScreenHeight))
        leftView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(leftView)
        
        let rightView = UIView(frame: CGRect(x: ScreenWidth - 55, y: 0, width: 55, height: ScreenHeight))
        rightView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(rightView)
        
        let topView = UIView(frame: CGRect(x: 55, y: 0, width: ScreenWidth - 110, height: (ScreenHeight - ScreenWidth + 110)/2))
        topView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(topView)
        
        let bottomView = UIView(frame: CGRect(x: 55, y: (ScreenHeight + ScreenWidth - 110)/2, width: ScreenWidth - 110, height: (ScreenHeight - ScreenWidth + 110)/2))
        bottomView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(bottomView)
        
        let titleLab = UILabel.getLab(font: UIFont.mediumFont(17), textColor: FZM_TintColor, textAlignment: .center, text: "扫一扫")
        self.view.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(StatusBarHeight + 13)
            m.centerX.equalToSuperview()
        }
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(GetBundleImage("back_arrow")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backBtn.tintColor = FZM_TintColor
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backBtn.enlargeClickEdge(20, 20, 20, 20)
        self.view.addSubview(backBtn)
        backBtn.snp.makeConstraints { (m) in
            m.centerY.equalTo(titleLab)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 10, height: 17))
        }
        
        self.view.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.top.equalTo(topView.snp.bottom)
            m.left.equalTo(leftView.snp.right)
            m.right.equalTo(rightView.snp.left)
            m.bottom.equalTo(bottomView.snp.top)
        }
        let alertLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: UIColor.white, textAlignment: .center, text: "请将二维码放入扫描框内")
        self.view.addSubview(alertLab)
        alertLab.snp.makeConstraints { (m) in
            m.bottom.equalTo(centerView.snp.top).offset(-30)
            m.centerX.equalToSuperview()
        }
        let albumBtn = UIButton(type: .custom)
        albumBtn.setAttributedTitle(NSAttributedString(string: "从相册选择", attributes: [.foregroundColor:FZM_TintColor,.font:UIFont.regularFont(16)]), for: .normal)
        self.view.addSubview(albumBtn)
        albumBtn.snp.makeConstraints { (m) in
            m.top.equalTo(centerView.snp.bottom).offset(50)
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 90, height: 23))
        }
        sweepLine.pop_add(animation, forKey: "kPOPViewCenter")
        albumBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            let uiManager = FZMUIMediator.shared()
            uiManager.pushVC(.photoLibrary(selectOne: true, maxSelectCount: 1, allowEditing: false, showVideo: false, selectBlock: {[weak uiManager] (list,_) in
                guard let image = list.first else { return }
                strongSelf.session?.stopRunning()
                if let str = FZMQRCodeGenerator.detectorQRCode(with: image) {
                    strongSelf.dismissBack(animated: false) {
                        uiManager?.parsingUrl(with: str, isSweep: true)
                    }
                }else {
                    strongSelf.showToast(with: "解析失败")
                    strongSelf.session?.startRunning()
                }
            }))
        }.disposed(by: disposeBag)
    }
    
    //设置相机
    func setCamera(){
        //获取摄像设备
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        do {
            //创建输入流
            let input =  try AVCaptureDeviceInput(device: device)
            //创建输出流
            let output = AVCaptureMetadataOutput()
            //设置会话
            session = AVCaptureSession()
            //连接输入输出
            guard let session = session else { return }
            if session.canAddInput(input){
                session.addInput(input)
            }
            
            if session.canAddOutput(output){
                session.addOutput(output)
                //设置输出流代理，从接收端收到的所有元数据都会被传送到delegate方法，所有delegate方法均在queue中执行
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                //设置扫描二维码类型
                output.metadataObjectTypes = [ AVMetadataObject.ObjectType.qr]
                //扫描区域
                //rectOfInterest 属性中x和y互换，width和height互换。
                output.rectOfInterest = CGRect(x: (ScreenHeight - ScreenWidth + 110)/2/ScreenHeight, y: 55/ScreenWidth, width: (ScreenWidth - 110)/ScreenHeight, height: (ScreenWidth - 110)/ScreenWidth)
                
            }
            //捕捉图层
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.view.layer.bounds
            self.view.layer.insertSublayer(previewLayer, at: 0)
            //持续对焦
            if device.isFocusModeSupported(.continuousAutoFocus){
                try  input.device.lockForConfiguration()
                input.device.focusMode = .continuousAutoFocus
                input.device.unlockForConfiguration()
            }
            session.startRunning()
        } catch  {
            
        }
    }
    
    @objc func goBack() {
        self.dismissBack()
    }
    
    func dismissBack(animated:Bool = true,completion:(()->())? = nil) {
        if let count = self.navigationController?.viewControllers.count, count > 1 {
            self.popBack()
        } else {
            self.dismiss(animated: animated, completion: completion)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FZMSweepQRCodeVC: AVCaptureMetadataOutputObjectsDelegate {
    //扫描完成的代理
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session?.stopRunning()
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject
            let str = readableObject.stringValue!
            FZMLog("二维码结果:\(str)")
            self.dismissBack(animated: false) {
                FZMUIMediator.shared().parsingUrl(with: str, isSweep: true)
            }
        }
    }
}
