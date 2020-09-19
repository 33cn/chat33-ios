//
//  PWLoginViewController.h
//  PWallet
//
//  Created by 于优 on 2018/12/26.
//  Copyright © 2018 陈健. All rights reserved.
//



NS_ASSUME_NONNULL_BEGIN

typedef void(^LoginSuccess) (id);
@interface PWLoginViewController : UIViewController

/** 是否回到首页 */
@property (nonatomic, assign) BOOL isBackHome;
/** 是否是红包 **/
@property (nonatomic, assign) BOOL isHongBao;

@property (nonatomic, copy)LoginSuccess loginSuccess;
@end

NS_ASSUME_NONNULL_END
