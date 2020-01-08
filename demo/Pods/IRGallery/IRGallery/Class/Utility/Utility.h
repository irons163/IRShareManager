//
//  Utility.h
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utility : NSObject

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (NSString *)getUTI:(NSString *)type;
+ (NSBundle *)getCurrentBundle;

@end

NS_ASSUME_NONNULL_END
