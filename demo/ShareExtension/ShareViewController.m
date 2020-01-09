//
//  ShareViewController.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "ShareViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <IRShareManager/IRShare.h>

@interface ShareViewController ()

@end

@implementation ShareViewController
- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    [self.textView setText:NSLocalizedStringFromTable(@"ShareMessage", @"Localizable",nil)];
    self.navigationController.navigationBar.topItem.rightBarButtonItem.title = NSLocalizedStringFromTable(@"SAVE", @"Localizable", nil);
    self.navigationController.navigationBar.topItem.leftBarButtonItem.title = NSLocalizedStringFromTable(@"Cancel", @"Localizable", nil);
    [IRShare sharedInstance].groupID = @"group.com.irons163.IRShare";
    return YES;
}

- (void)didSelectPost {
    [[IRShare sharedInstance] showSaveAlertIn:self];
    [[IRShare sharedInstance] didSelectPostWith:self.extensionContext];
}

@end

