//
//  NSBundle+IRLocalizedString.h
//  IRPasscode
//
//  Created by Phil on 2019/11/15.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (IRLocalizedString)

+ (instancetype)safeBundle;
+ (NSString *)IR_localizedStringForKey:(NSString *)key;
+ (NSString *)IR_localizedStringForKey:(NSString *)key language:(NSString *)language;
+ (NSString *)IR_localizedStringForKey:(NSString *)key value:(nullable NSString *)value;
+ (NSString *)IR_localizedStringForKey:(NSString *)key value:(nullable NSString *)value language:(NSString *)language;

@end

NS_ASSUME_NONNULL_END
