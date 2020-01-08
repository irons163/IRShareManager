//
//  IRLanguageManager.m
//  IRPasscode
//
//  Created by Phil on 2019/11/14.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRLanguageManager.h"
#import "NSBundle+IRLocalizedString.h"

@import AVFoundation;

@interface IRLanguageManager()<AVSpeechSynthesizerDelegate>
{
    __weak UILabel* inputLabel;
}

@property (strong, nonatomic) NSArray *languageCodes;
@property (strong, nonatomic) NSDictionary *languageDictionary;
@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;
@property (nonatomic) dispatch_semaphore_t semaphore;

typedef NS_ENUM(NSInteger, UYLSpeedControlIndex)
{
    UYLSpeedControlQuarterSpeed = 0,
    UYLSpeedControlHalfSpeed = 1,
    UYLSpeedControlNormalSpeed = 2,
    UYLSpeedControlDoubleSpeed = 3
};

typedef NS_ENUM(NSInteger, UYLPitchControlIndex)
{
    UYLPitchControlDeepPitch = 0,
    UYLPitchControlNormalPitch = 1,
    UYLPitchControlHighPitch = 2
};

@property (assign, nonatomic) UYLSpeedControlIndex selectedSpeed;
@property (assign, nonatomic) UYLPitchControlIndex selectedPitch;
@property (strong, nonatomic) NSString *selectedLanguage;

@property (strong, nonatomic) NSString *restoredTextToSpeak;

@end

@implementation IRLanguageManager

@synthesize currentLanguage;

NSString *UYLPrefKeySelectedSpeed = @"UYLPrefKeySelectedSpeed";
NSString *UYLPrefKeySelectedPitch = @"UYLPrefKeySelectedPitch";
NSString *UYLPrefKeySelectedLanguage = @"UYLPrefKeySelectedLanguage";
NSString *UYLKeySpeechText = @"UYLKeySpeechText";

+ (instancetype)sharedInstance {
    static IRLanguageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        currentLanguage = nil;
        currentLanguageBundle = nil;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:SETTING_LANGUALE_KEY]) {
            NSString *path = [self getPathWithLanguage:[userDefaults objectForKey:SETTING_LANGUALE_KEY]];
            if (path) {
                currentLanguageBundle = [NSBundle bundleWithPath:path];
                currentLanguage = [userDefaults objectForKey:SETTING_LANGUALE_KEY];
            }else{
                [userDefaults removeObjectForKey:SETTING_LANGUALE_KEY];
                [userDefaults synchronize];
            }
        }
        
        [self restoreUserPreferences];
        
        
    }
    return self;
}

- (void)setLanguage:(NSString *)languageName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [self getPathWithLanguage:languageName];
    if (path) {
        currentLanguageBundle = [NSBundle bundleWithPath:path];
        currentLanguage = languageName;
        [userDefaults setObject:languageName forKey:SETTING_LANGUALE_KEY];
    }else{
        currentLanguage = nil;
        currentLanguageBundle = nil;
        [userDefaults removeObjectForKey:SETTING_LANGUALE_KEY];
    }
    [userDefaults synchronize];
}

- (NSString *)stringFor:(NSString *)srcString {
    if (srcString == nil) {
        return nil;
    }
    if (currentLanguageBundle) {
        return NSLocalizedStringFromTableInBundle(srcString, nil, currentLanguageBundle, nil);
    }
    return NSLocalizedString(srcString, nil);
//    return [NSBundle IR_localizedStringForKey:srcString];
}

- (NSString *)getPathWithLanguage:(NSString *)languageName {
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_EN", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_ENGLISH_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_TC", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_CHINESE_TRADITIONAL_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_SC", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_CHINESE_SIMPLIFIED_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_GE", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_Germany_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_IT", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_Italy_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_SW", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_Swedish_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_FR", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_French_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_SP", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_Spanish_SHORT_ID ofType:@"lproj"];
    }
    if ([languageName isEqualToString:NSLocalizedString(@"LANGUAGE_DU", nil)])
    {
        return [[NSBundle safeBundle] pathForResource:LANGUAGE_Dutch_SHORT_ID ofType:@"lproj"];
    }
    return nil; //is Auto
}

- (void)speakWithLabel:(UILabel*)label {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (label.text && !self.synthesizer.isSpeaking) {
                self->inputLabel = label;
                AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.selectedLanguage];
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:label.text];
                utterance.voice = voice;
                
                float adjustedRate = AVSpeechUtteranceDefaultSpeechRate * [self rateModifier];
                
                if (adjustedRate > AVSpeechUtteranceMaximumSpeechRate)
                {
                    adjustedRate = AVSpeechUtteranceMaximumSpeechRate;
                }
                
                if (adjustedRate < AVSpeechUtteranceMinimumSpeechRate)
                {
                    adjustedRate = AVSpeechUtteranceMinimumSpeechRate;
                }
                
                utterance.rate = adjustedRate;
                
                float pitchMultiplier = [self pitchModifier];
                if ((pitchMultiplier >= 0.5) && (pitchMultiplier <= 2.0))
                {
                    utterance.pitchMultiplier = pitchMultiplier;
                }
                
                [self.synthesizer speakUtterance:utterance];
            }
        });
    });
}

- (void)stopSpeak {
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

#pragma mark - AVSpeechSynthesizer
// Language codes used to create custom voices. Array is sorted based
// on the display names in the language dictionary
- (NSArray *)languageCodes {
    if (!_languageCodes) {
        _languageCodes = [self.languageDictionary keysSortedByValueUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _languageCodes;
}

- (NSDictionary *)languageDictionary {
    if (!_languageDictionary) {
        NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
        NSArray *languages = [voices valueForKey:@"language"];
        
        NSLocale *currentLocale = [NSLocale autoupdatingCurrentLocale];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (NSString *code in languages) {
            dictionary[code] = [currentLocale displayNameForKey:NSLocaleIdentifier value:code];
        }
        _languageDictionary = dictionary;
    }
    return _languageDictionary;
}

- (AVSpeechSynthesizer *)synthesizer {
    if (!_synthesizer) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
    }
    return _synthesizer;
}

- (float)rateModifier
{
    float rate = 1.0;
    switch (self.selectedSpeed)
    {
        case UYLSpeedControlQuarterSpeed:
            rate = 0.25;
            break;
        case UYLSpeedControlHalfSpeed:
            rate = 0.5;
            break;
        case UYLSpeedControlNormalSpeed:
            rate = 1.0;
            break;
        case UYLSpeedControlDoubleSpeed:
            rate = 2.0;
            break;
        default:
            rate = 1.0;
            break;
    }
    return rate;
}

- (float)pitchModifier {
    float pitch = 1.0;
    switch (self.selectedPitch)
    {
        case UYLPitchControlDeepPitch:
            pitch = 0.75;
            break;
        case UYLPitchControlNormalPitch:
            pitch = 1.0;
            break;
        case UYLPitchControlHighPitch:
            pitch = 1.5;
            break;
        default:
            pitch = 1.0;
            break;
    }
    return pitch;
}

- (dispatch_semaphore_t)semaphore {
    if (!_semaphore) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return _semaphore;
}

#pragma mark - State Restoration
- (void)restoreUserPreferences {
    NSString *currentLanguageCode = [AVSpeechSynthesisVoice currentLanguageCode];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaults = @{ UYLPrefKeySelectedPitch:[NSNumber numberWithInteger:UYLPitchControlNormalPitch],
                                UYLPrefKeySelectedSpeed:[NSNumber numberWithInteger:UYLSpeedControlNormalSpeed],
                                UYLPrefKeySelectedLanguage:currentLanguageCode
                                };
    [preferences registerDefaults:defaults];
    
    self.selectedPitch = [preferences integerForKey:UYLPrefKeySelectedPitch];
    self.selectedSpeed = [preferences integerForKey:UYLPrefKeySelectedSpeed];
    self.selectedLanguage = [preferences stringForKey:UYLPrefKeySelectedLanguage];
}

#pragma mark - AVSpeechSynthesizerDelegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance {
    if (inputLabel) {
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:inputLabel.text];
        [text addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:characterRange];
        inputLabel.attributedText = text;
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:inputLabel.attributedText];
    [text removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [text length])];
    inputLabel.attributedText = text;
    inputLabel = nil;
    dispatch_semaphore_signal(self.semaphore);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:inputLabel.attributedText];
    [text removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [text length])];
    inputLabel.attributedText = text;
    inputLabel = nil;
    dispatch_semaphore_signal(self.semaphore);
}

@end

