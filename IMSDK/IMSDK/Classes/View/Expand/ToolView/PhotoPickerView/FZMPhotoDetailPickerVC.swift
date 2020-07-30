//
//  FZMPhotoDetailPickerVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/12/6.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import Photos

class FZMPhotoDetailPickerVC: FZMBaseViewController {

    private var selectIndex : Int
    private var scrollIndex = 0
    private let manager : FZMPhotoManager
    var confirmBlock : (([UIImage])->())?
    
    lazy var selectBtn : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: UIColor.white, textAlignment: .center, text: nil)
        lab.isUserInteractionEnabled = true
        lab.enlargeClickEdge(20, 20, 20, 20)
        lab.layer.cornerRadius = 12.5
        lab.layer.borderColor = FZM_TintColor.cgColor
        lab.layer.borderWidth = 2
        lab.backgroundColor = FZM_GrayWordColor
        lab.clipsToBounds = true
        return lab
    }()
    
    
    lazy var bottomBar : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x142E4D, alpha: 1.0)
        view.addSubview(sendBtn)
        sendBtn.snp.makeConstraints({ (m) in
            m.right.equalToSuperview().offset(-15)
            m.bottom.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 100, height: 40))
        })
        view.addSubview(selectView)
        selectView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(10)
            m.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        return view
    }()
    
    private var photoArray = [PHAsset]()
    private var selectArr = [PHAsset]()
    lazy var photoListView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: ScreenWidth, height: ScreenHeight - StatusNavigationBarHeight - 140)
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.clear
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(FZMPhotoDetailCell.self, forCellWithReuseIdentifier: "FZMPhotoDetailCell")
        return view
    }()
    
    lazy var selectView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 50, height: 50)
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(FZMPhotoViewCell.self, forCellWithReuseIdentifier: "FZMPhotoViewCell")
        return view
    }()
    
    lazy var sendBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "发送(0/9)")
        btn.clipsToBounds = true
        return btn
    }()
    
    init(with manager: FZMPhotoManager, selectArr: [PHAsset], index: Int) {
        self.manager = manager
        self.selectIndex = index
        self.selectArr = selectArr
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "所有照片"
        selectBtn.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize(width: 25, height: 25))
        }
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            self?.clickSelect()
        }.disposed(by: disposeBag)
        selectBtn.addGestureRecognizer(tap)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectBtn)
        
        self.navTitleColor = FZM_TintColor
        self.navBarColor = UIColor(hex: 0x142E4D, alpha: 1.0)
        self.createUI()
    }
    
    var backBlock : (([PHAsset]) -> ())?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        backBlock?(selectArr)
    }
    
    private func createUI() {
        self.view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (m) in
            m.left.right.bottom.equalToSuperview()
            m.height.equalTo(140)
        }
        self.view.addSubview(photoListView)
        photoListView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
            m.bottom.equalTo(bottomBar.snp.top)
        }
        var arr = [PHAsset]()
        self.manager.photoAlbum.enumerateObjects { (asset, _, _) in
            arr.append(asset)
        }
        self.photoArray = arr.reversed()
        self.photoListView.reloadData()
        self.photoListView.alpha = 0;
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.photoListView.setContentOffset(CGPoint(x: ScreenWidth * CGFloat(self.photoArray.count - 1 - self.selectIndex), y: 0), animated: false)
            self.photoListView.alpha = 1;
        }
        
        sendBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            guard strongSelf.selectArr.count > 0 else {
                strongSelf.showToast(with: "请先选择照片")
                return
            }
            strongSelf.sendImages(list: strongSelf.selectArr, useList: [UIImage]())
        }.disposed(by: disposeBag)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / ScreenWidth)
        let asset = photoArray[index]
        if selectArr.contains(asset) {
            self.selectBtn.backgroundColor = FZM_TintColor
            self.selectBtn.text = "\(selectArr.count)"
        }else {
            self.selectBtn.backgroundColor = FZM_GrayWordColor
            self.selectBtn.text = ""
        }
        if scrollIndex != index {
            scrollIndex = index
            selectView.reloadData()
//            let scrollAsset = photoArray[index]
//            if let useIndex = selectArr.index(of: scrollAsset), useIndex > 5 {
//                selectView.scrollToItem(at: IndexPath(item: useIndex, section: 0), at: .centeredHorizontally, animated: true)
//            }
        }
    }
    
    func clickSelect() {
        let index = Int(photoListView.contentOffset.x / ScreenWidth)
        let asset = photoArray[index]
        if selectArr.contains(asset) {
            selectArr.remove(at: asset)
            self.selectBtn.backgroundColor = FZM_GrayWordColor
            self.selectBtn.text = ""
            
        }else {
            if selectArr.count >= 9 {
                let alert = FZMAlertView(onlyAlert: "最多只能选择9张图片", btnTitle: "知道了", confirmBlock: nil)
                alert.show()
                return
            }
            selectArr.append(asset)
            self.selectBtn.backgroundColor = FZM_TintColor
            self.selectBtn.text = "\(selectArr.count)"
        }
        selectView.reloadData()
        self.sendBtn.setAttributedTitle(NSAttributedString(string: "发送(\(selectArr.count)/9)", attributes: [.foregroundColor: UIColor.white,.font:UIFont.regularFont(16)]), for: .normal)
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
    
    func cancelClick() {
        self.navigationController?.dismiss(animated: true, completion: {
            
        })
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

extension FZMPhotoDetailPickerVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === selectView {
            return self.selectArr.count
        }else {
            return photoArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === selectView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMPhotoViewCell", for: indexPath) as! FZMPhotoViewCell
            let asset = selectArr[indexPath.item]
            cell.asset = asset
            manager.requestImg(asset: asset, size: CGSize(width: ScreenWidth/2, height: ScreenWidth/2), contentMode: .aspectFill, resultHandler: { (getAsset, img) in
                if getAsset === cell.asset {
                    cell.contentImageView.image = img
                }
            })
            cell.layer.cornerRadius = 4
            cell.clipsToBounds = true
            cell.layer.borderWidth = 2
            let scrollAsset = self.photoArray[scrollIndex]
            if scrollAsset === asset {
                cell.layer.borderColor = FZM_TintColor.cgColor
            }else {
                cell.layer.borderColor = UIColor.clear.cgColor
            }
            cell.showSelect = false
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMPhotoDetailCell", for: indexPath) as! FZMPhotoDetailCell
            let asset = photoArray[indexPath.item]
            self.manager.requestImg(asset: asset, size: CGSize(width: ScreenWidth/2, height: ScreenHeight/2), contentMode: .aspectFit) { (asset, img) in
                cell.contentImageView.image = img
            }
            return cell
        }
    }
}


class FZMPhotoDetailCell: UICollectionViewCell {
    let contentImageView : UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .white
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        self.contentView.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
