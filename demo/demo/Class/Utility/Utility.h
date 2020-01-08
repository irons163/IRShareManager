//
//  Utility.h
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utility : NSObject

+ (NSDate *)getFileCreationTimeFromPath:(NSString *)filePath ;
+ (NSNumber *)getFileSize:(NSString *)filepath;
+ (NSString *)getFileType:(NSString *)ext;
+ (UIImage *)getImageWithType:(NSString*)type ext:(NSString *)ext;
+ (UIImage *)getMusicCover:(NSString *)urlString;
+ (UIImage *)generateThumbImage:(NSString *)filepath;

@end

NS_ASSUME_NONNULL_END
