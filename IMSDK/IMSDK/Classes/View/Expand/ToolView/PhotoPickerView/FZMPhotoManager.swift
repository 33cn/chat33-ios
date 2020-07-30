//
//  FZMPhotoManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/26.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class FZMPhotoManager: NSObject {

    private(set) var photoAlbum  = PHFetchResult<PHAsset>()
    
    private var photoManage = PHCachingImageManager()
    /// 照片获取偏好设置
    private let photoOption = PHImageRequestOptions()
    //pickerCell照片的size
    class public var pickerPhotoSize: CGSize {
        let width = (ScreenWidth - CGFloat(10)) / CGFloat(4)
        return CGSize(width: width, height: width)
    }
    
    override init() {
        super.init()
        // 如何调整所请求的图像大小。
        self.photoOption.resizeMode   = .fast //最快速的调整图像大小，有可能比给定大小略大
        // 请求的图像质量和交付优先级。
        self.photoOption.deliveryMode = .opportunistic //平衡图像质量和响应速度
        // 是否同步处理一个图像请求.
        self.photoOption.isSynchronous = true
        getPhotoAlbums()
    }
    /// 获取手机相册内所有照片
    ///
    /// - Returns: 手机相册内所有照片
    public func getAllPhoto(isDetail: Bool = false) -> [UIImage]{
        var imageArray = [UIImage]()
        let scale = UIScreen.main.scale
        /// 重要,不对size进行重置会使显示效果变差
        let size = isDetail ? CGSize(width: ScreenWidth, height: ScreenHeight) : FZMPhotoManager.pickerPhotoSize
        let photoScaleSize = CGSize(width: size.width * scale, height: size.height * scale)
        /// 将图片添加到数组
        for i in 0 ..< self.photoAlbum.count {
            /// 按顺序获取图片
            self.photoManage.requestImage(for: self.photoAlbum[i], targetSize: photoScaleSize, contentMode: .aspectFill, options: self.photoOption) { (image, infoDic) in
                guard let image = image else { return }
                imageArray.append(image)
            }
        }
        return imageArray
    }
    /// 获取单个照片信息,用于裁剪
    ///
    /// - Parameters:
    ///   - index: 照片处在array的index
    ///   - resultHandler: 将获取data回调
    public func getPhotoData(index: Int, resultHandler: ((Data?, UIImage.Orientation) -> Void)?) {
        self.photoManage.requestImageData(for: self.photoAlbum[index], options: nil, resultHandler: { (data, str, orientation, hashable) in
            resultHandler?(data, orientation)
        })
    }
    
    public func requestImg(asset: PHAsset, size: CGSize, contentMode: PHImageContentMode = .default, resultHandler: ((PHAsset, UIImage?)->())?) {
        self.photoManage.requestImage(for: asset, targetSize: size, contentMode: contentMode, options: nil) { (image, _) in
            resultHandler?(asset, image)
        }
    }
    
    public func requestPhotoData(asset: PHAsset, resultHandler: ((Data?, UIImage.Orientation) -> Void)?) {
        self.photoManage.requestImageData(for: asset, options: nil) { (data, str, orientation, hashable) in
            if data != nil {
                resultHandler?(data, orientation)
            } else {
                //当使用iCloud图片时 图片未下载 data可能为空 则使用下面这种方式获取低质量图片
                self.photoManage.requestImage(for: asset, targetSize: CGSize(width: ScreenWidth, height: ScreenHeight), contentMode: .aspectFit, options: nil, resultHandler: { (image, _) in
                    let data = image?.jpegData(compressionQuality: 1)
                    resultHandler?(data, orientation)
                })
            }
        }
    }
    
    /// 获取手机中所有相册照片源
    private func getPhotoAlbums(){
        //创建一个PHFetchOptions对象检索照片
        let options = PHFetchOptions()
        //通过创建时间来检索
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        //通过数据类型来检索，这里为只检索照片
        options.predicate = NSPredicate.init(format: "mediaType in %@", [PHAssetMediaType.image.rawValue])
        //通过检索条件检索出符合检索条件的所有数据，也就是所有的照片
        let allResult = PHAsset.fetchAssets(with: options)
        //将获取的相片加入到相片的数组中
        photoAlbum = allResult
    }
    
}
