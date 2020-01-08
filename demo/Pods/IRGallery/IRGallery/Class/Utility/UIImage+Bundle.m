//
//  UIImage+Bundle.m
//  IRMusicPlayer
//
//  Created by Phil on 2019/11/1.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "UIImage+Bundle.h"
#import "Utility.h"

@implementation UIImage (Bundle)

+ (UIImage *)imageNamedForCurrentBundle:(NSString *)name {
    return [UIImage imageNamed:name inBundle:[Utility getCurrentBundle] compatibleWithTraitCollection:nil];
}

@end
