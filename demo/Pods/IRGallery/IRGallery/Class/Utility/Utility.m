//
//  Utility.m
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSString *)getUTI:(NSString *)type {
    // Text
    if ( [[type lowercaseString] isEqualToString:@"txt"] || [[type lowercaseString] isEqualToString:@"rtf"] ||
        [[type lowercaseString] isEqualToString:@"htm"] || [[type lowercaseString] isEqualToString:@"html"] )
        return @"public.text";
    else if ([[type lowercaseString] isEqualToString:@"pdf"])
        return @"com.adobe.pdf";
    else if ([[type lowercaseString] isEqualToString:@"sheet"])
        return @"org.openxmlformats.spreadsheetml.sheet";
    
    // MS Office
    else if ([[type lowercaseString] isEqualToString:@"doc"] || [[type lowercaseString] isEqualToString:@"docx"])
        return @"com.microsoft.word.doc";
    else if ([[type lowercaseString] isEqualToString:@"ppt"] || [[type lowercaseString] isEqualToString:@"pptx"])
        return @"com.microsoft.powerpoint.ppt";
    else if ([[type lowercaseString] isEqualToString:@"xls"] || [[type lowercaseString] isEqualToString:@"xlsx"])
        return @"com.microsoft.excel.xls";
    
    // iWork
    else if ([[type lowercaseString] isEqualToString:@"key"])
        return @"com.apple.keynote.key";
    else if ([[type lowercaseString] isEqualToString:@"numbers"])
        return @"public.content";
    else if ([[type lowercaseString] isEqualToString:@"pages"])
        return @"com.apple.pages";
    
    // Photo
    else if ([[type lowercaseString] isEqualToString:@"png"])
        return @"public.png";
    else if ([[type lowercaseString] isEqualToString:@"jpg"] || [[type lowercaseString] isEqualToString:@"jpeg"])
        return @"public.jpeg";
    else if ([[type lowercaseString] isEqualToString:@"tiff"])
        return @"public.tiff";
    else if ([[type lowercaseString] isEqualToString:@"heic"])
        return @"public.heif";

    // Music & Video
    else if ([[type lowercaseString] isEqualToString:@"mp3"])
        return @"public.mp3";
    else if ([[type lowercaseString] isEqualToString:@"mp4"])
        return @"public.mpeg-4";
    else if ([[type lowercaseString] isEqualToString:@"avi"])
        return @"public.avi";
    else if ([[type lowercaseString] isEqualToString:@"3gpp"])
        return @"public.3gpp";
    else if ([[type lowercaseString] isEqualToString:@"mpg"])
        return @"public.mpeg-2-video";
    else if ([[type lowercaseString] isEqualToString:@"mpeg"])
        return @"public.mpeg-2-video";
    return @"";
}

+ (NSBundle *)getCurrentBundle {
    return [NSBundle bundleForClass:self];
}

@end
