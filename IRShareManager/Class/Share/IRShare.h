//
//  IRShare.h
//  IRShareManager
//
//  Created by Phil on 2020/1/9.
//  Copyright © 2020 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IRShare : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

@property NSString *groupID;
@property (readonly) NSURL *directoryURL;
@property (readonly) NSExtensionContext *extensionContext;

- (void)showSaveAlertIn:(UIViewController *)vc;
- (void)didSelectPostWith:(NSExtensionContext *)extensionContext;

@end

NS_ASSUME_NONNULL_END
