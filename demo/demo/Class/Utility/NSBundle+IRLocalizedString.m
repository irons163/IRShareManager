//
//  NSBundle+IRLocalizedString.m
//  IRPasscode
//
//  Created by Phil on 2019/11/15.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "NSBundle+IRLocalizedString.h"

#define BUNDLE_NAME @"IRPasscodeBundle"

@implementation NSBundle (IRLocalizedString)

+ (instancetype)safeBundle {
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        NSString *bundleName = BUNDLE_NAME;
        
        //Not use framework
        NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:bundleName withExtension:@"bundle"];
        //Use framework
        if (!bundleURL) {
            bundleURL = [[NSBundle mainBundle] URLForResource:@"Frameworks" withExtension:nil];
            bundleURL = [bundleURL URLByAppendingPathComponent:@"IRPasscode"];
            bundleURL = [bundleURL URLByAppendingPathExtension:@"framework"];
            NSBundle *associateBunle = [NSBundle bundleWithURL:bundleURL];
//            NSBundle *associateBunle = [NSBundle bundleForClass:self];
            bundleURL = [associateBunle URLForResource:bundleName withExtension:@"bundle"];
        }
        
        bundle = [NSBundle bundleWithURL:bundleURL];
    }
    return bundle;
}

+ (NSString *)IR_localizedStringForKey:(NSString *)key {
    return [self IR_localizedStringForKey:key value:nil];
}

+ (NSString *)IR_localizedStringForKey:(NSString *)key language:(NSString *)language {
    if (language == nil) {
        return [self IR_localizedStringForKey:key value:nil];
    }
    return [self IR_localizedStringForKey:key value:nil language:language];
}

+ (NSString *)IR_localizedStringForKey:(NSString *)key value:(nullable NSString *)value {
    NSString *language = [NSLocale preferredLanguages].firstObject;
    if ([language hasPrefix:@"en"]) {
        language = @"en";
    } else if ([language hasPrefix:@"zh"]) {
        if ([language rangeOfString:@"Hans"].location != NSNotFound) {
            language = @"zh-Hans";
        } else {
            language = @"zh-Hant";
        }
    } else {
        language = @"en";
    }
    return [self IR_localizedStringForKey:key value:value language:language];
}

+ (NSString *)IR_localizedStringForKey:(NSString *)key value:(nullable NSString *)value language:(NSString *)language {
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle safeBundle] pathForResource:language ofType:@"lproj"]];
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}
@end
