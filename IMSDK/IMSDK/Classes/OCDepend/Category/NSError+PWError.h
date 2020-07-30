//
//  NSError+PWError.h
//  PWallet
//
//  Created by .. on 2018/5/16.
//  Copyright © 2018年 ... All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSError (PWError)
+ (NSError *) errorWithCode:(NSInteger) errorCode errorMessage:(NSString *) errorMessage;
@end
