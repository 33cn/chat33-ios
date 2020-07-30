//
//  PWSessionManagerSingleton.h
//  PWallet
//
//  Created by .. on 2018/5/16.
//  Copyright © 2018年 ... All rights reserved.
//

#import <Foundation/Foundation.h>
@class AFHTTPSessionManager;

@interface PWSessionManagerSingleton : NSObject
+ (AFHTTPSessionManager *) sharedSessionManager;
@end
