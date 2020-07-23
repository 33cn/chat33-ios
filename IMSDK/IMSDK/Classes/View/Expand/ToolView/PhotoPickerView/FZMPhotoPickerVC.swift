//
//  FZMPhotoPickerVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/26.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import Photos

class FZMPhotoPickerVC: FZMBaseViewController {

    private let selectOne : Bool
    private let shouldEdit : Bool
    private let manager =  FZMPhotoManager()
    private var selectArr = [PHAsset]()
    
    var confirmBlock : (([UIImage])->())?
    
    private lazy var collectionView : UICollectionView = {
        let defaultLayout = UICollectionViewFlowLayout()
        defaultLayout.scrollDirection = .vertical//设置垂直显示
        defaultLayout.minimumLineSpacing = 2 //每个相邻的layout的上下间隔
        defaultLayout.minimumInteritemSpacing = 2.0 //每个相邻layout的左右间隔
        let view = UICollectionView(frame:CGRect.zero, collectionViewLayout: defaultLayout)
        view.backgroundColor = UIColor.white
        view.contentInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        view.delegate = self
        view.dataSource = self
        view.showsVerticalScrollIndicator = false
        view.register(FZMPhotoViewCell.self, forCellWithReuseIdentifier: "FZMPhotoViewCell")
        return view
    }()
    
    private lazy var bottomBar : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.makeOriginalShdowShow()
        
        view.addSubview(sendBtn)
        sendBtn.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 100, height: 40))
        })
        return view
    }()
    
    private lazy var sendBtn : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: UIColor.white, textAlignment: .center, text: "发送(0/9)")
        lab.isUserInteractionEnabled = true
        lab.layer.backgroundColor = FZM_TintColor.cgColor
        lab.layer.cornerRadius = 5
        lab.makeNormalShadow()
        return lab
    }()
    
    init(with selectOne: Bool, shouldEdit: Bool = false) {
        self.selectOne = selectOne
        self.shouldEdit = shouldEdit
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "所有照片"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelClick))
        self.createUI()
    }
    
    @objc func cancelClick() {
        self.navigationController?.dismiss(animated: true, completion: {
            
        })
    }
    
    private func createUI() {
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (m) in
            m.left.right.top.equalToSuperview()
            m.bottom.equalToSuperview().offset(selectOne ? 0 : -70)
        }
        if !selectOne {
            self.view.addSubview(bottomBar)
            bottomBar.snp.makeConstraints { (m) in
                m.left.right.bottom.equalToSuperview()
                m.top.equalTo(collectionView.snp.bottom)
            }
        }
        
        collectionView.reloadData()
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            guard strongSelf.selectArr.count > 0 else {
                strongSelf.showToast(with: "请先选择照片")
                return
            }
            strongSelf.sendImages(list: strongSelf.selectArr, useList: [UIImage]())
        }.disposed(by: disposeBag)
        sendBtn.addGestureRecognizer(tap)
    }
    
    private func sendImages( list: [PHAsset], useList: [UIImage]) {
        var list = list
        var useList = useList
        let failBlock = {
            self.showToast(with: "载入照片出错，请重试")
        }
        if let asset = list.first {
            manager.requestPhotoData(asset: asset) {[weak self] (data, dic) in
                guard let strongSelf = self else {
                    failBlock()
                    return
                }
                guard let data = data, let image = UIImage(data: data) else { return }
                useList.append(image)
                if list.count != 0 {
                    list.remove(at: 0)
                }
                if list.count == 0 {
                    strongSelf.confirmBlock?(useList)
                    strongSelf.cancelClick()
                }else {
                    strongSelf.sendImages(list: list, useList: useList)
                }
            }
        }else {
            failBlock()
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

extension FZMPhotoPickerVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /// 返回数据数组.count 加一个新建按钮
        return self.manager.photoAlbum.count
    }
    /// cell点击方法
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectOne {
            manager.getPhotoData(index: indexPath.row) {[weak self] (data, infoDic) in
                guard let strongSelf = self else { return }
                guard let data = data, let image = UIImage(data: data) else { return }
                if strongSelf.shouldEdit {
                    let vc = FZMImageCropVC(with: image)
                    vc.confirmBlock = { editImg in
                        strongSelf.confirmBlock?([editImg])
                        strongSelf.cancelClick()
                    }
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }else {
                    strongSelf.confirmBlock?([image])
                    strongSelf.cancelClick()
                }
            }
        }else {
            let vc = FZMPhotoDetailPickerVC(with: manager, selectArr: selectArr, index: indexPath.item)
            vc.backBlock = { arr in
                self.selectArr = arr
                self.collectionView.reloadData()
            }
            vc.confirmBlock = self.confirmBlock
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMPhotoViewCell", for: indexPath) as! FZMPhotoViewCell
        let asset = manager.photoAlbum[indexPath.row]
        cell.asset = asset
        manager.requestImg(asset: asset, size: CGSize(width: ScreenWidth/2, height: ScreenWidth/2), contentMode: .aspectFill, resultHandler: { (getAsset, img) in
            if getAsset === cell.asset {
                cell.contentImageView.image = img
            }
        })
        cell.configure(index: self.selectArr.index(of: asset))
        cell.showSelect = !selectOne
        cell.selectBlock = {[weak self] in
            guard let strongSelf = self else { return }
            if let index = strongSelf.selectArr.index(of: asset) {
                strongSelf.selectArr.remove(at: index)
            }else {
                if strongSelf.selectArr.count >= 9 {
                    let alert = FZMAlertView(onlyAlert: "最多只能选择9张图片", btnTitle: "知道了", confirmBlock: nil)
                    alert.show()
                    return
                }else {
                    strongSelf.selectArr.append(asset)
                }
            }
            strongSelf.sendBtn.text = "发送(\(strongSelf.selectArr.count)/9)"
            strongSelf.collectionView.reloadData()
        }
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return FZMPhotoManager.pickerPhotoSize
    }
}
