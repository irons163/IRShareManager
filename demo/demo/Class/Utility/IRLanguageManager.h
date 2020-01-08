//
//  IRLanguageManager.h
//  IRPasscode
//
//  Created by Phil on 2019/11/14.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define SETTING_LANGUALE_KEY                @"SettingLanguages"
#define DID_CHANGE_LANGUAGE_KEY             @"DidChangeLanguage"
//Language Key
#define LANGUAGE_ENGLISH_SHORT_ID              @"en"
#define LANGUAGE_CHINESE_TRADITIONAL_SHORT_ID  @"zh-Hant"
#define LANGUAGE_CHINESE_SIMPLIFIED_SHORT_ID   @"zh-Hans"
#define LANGUAGE_Germany_SHORT_ID              @"de"
#define LANGUAGE_Italy_SHORT_ID                @"it"
#define LANGUAGE_Swedish_SHORT_ID              @"sv"
#define LANGUAGE_French_SHORT_ID               @"fr"
#define LANGUAGE_Spanish_SHORT_ID              @"es"
#define LANGUAGE_Dutch_SHORT_ID                @"nl"

//Get multi language string
#define _(str)  [[IRLanguageManager sharedInstance] stringFor:str]

@interface IRLanguageManager : NSObject{
    NSString        *currentLanguage;
    NSBundle        *currentLanguageBundle;
}

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+ (instancetype)sharedInstance;

- (void)setLanguage:(NSString *)languageName;
- (NSString *)stringFor:(NSString *)srcString;
- (void)speakWithLabel:(UILabel *)label;
- (void)stopSpeak;

@property (nonatomic, strong) NSString *currentLanguage;

@end

NS_ASSUME_NONNULL_END
