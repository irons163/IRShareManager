//
//  Utility.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "Utility.h"
#import <AVFoundation/AVFoundation.h>

@implementation Utility

+ (NSDate *)getFileCreationTimeFromPath:(NSString *)filePath {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDictionary* attrs = [fm attributesOfItemAtPath:filePath error:nil];
    NSDate *date;
    if (attrs != nil) {
        date = (NSDate*)[attrs objectForKey: NSFileCreationDate];
        NSLog(@"Date Created: %@", [date description]);
    }
    else {
        NSLog(@"Not found");
    }
    
    return date;
}

+ (NSNumber *)getFileSize:(NSString *)filepath {
    NSError* error;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error: &error];
    NSNumber *fileSize = [fileDictionary objectForKey:NSFileSize];
    return fileSize;
}

+ (NSString *)getFileType:(NSString *)ext {
    if ( [[ext lowercaseString] isEqualToString:@"pdf"] || [[ext lowercaseString] isEqualToString:@"txt"] || [[ext lowercaseString] isEqualToString:@"rtf"] ||
        [[ext lowercaseString] isEqualToString:@"htm"] || [[ext lowercaseString] isEqualToString:@"html"] ||
        [[ext lowercaseString] isEqualToString:@"doc"] || [[ext lowercaseString] isEqualToString:@"docx"] ||
        [[ext lowercaseString] isEqualToString:@"xls"] || [[ext lowercaseString] isEqualToString:@"xlsx"] ||
        [[ext lowercaseString] isEqualToString:@"ppt"] || [[ext lowercaseString] isEqualToString:@"pptx"] ||
        [[ext lowercaseString] isEqualToString:@"key"] || [[ext lowercaseString] isEqualToString:@"numbers"] || [[ext lowercaseString] isEqualToString:@"pages"] )
        return @"DOCUMENT";
    else if ([[ext lowercaseString] isEqualToString:@"mp3"] || [[ext lowercaseString] isEqualToString:@"m4a"]
             || [[ext lowercaseString] isEqualToString:@"aac"] || [[ext lowercaseString] isEqualToString:@"wav"]
             //             || [[ext lowercaseString] isEqualToString:@"ac3"] || [[ext lowercaseString] isEqualToString:@"aiff"] || [[ext lowercaseString] isEqualToString:@"mp2"] || [[ext lowercaseString] isEqualToString:@"ogg"] || [[ext lowercaseString] isEqualToString:@"wma"]
             )
        return @"MUSIC";
    else if ([[ext lowercaseString] isEqualToString:@"avi"] ||
             //             [[ext lowercaseString] isEqualToString:@"mpg"] ||
             [[ext lowercaseString] isEqualToString:@"mp4"] ||
             //             [[ext lowercaseString] isEqualToString:@"m4v"] ||
             [[ext lowercaseString] isEqualToString:@"mov"] ||
             //             [[ext lowercaseString] isEqualToString:@"3gp"] ||
             [[ext lowercaseString] isEqualToString:@"mkv"] ||
             [[ext lowercaseString] isEqualToString:@"wmv"] ||
             [[ext lowercaseString] isEqualToString:@"asf"] ||
             //             [[ext lowercaseString] isEqualToString:@"dv"]  ||
             //             [[ext lowercaseString] isEqualToString:@"vob"] ||
             [[ext lowercaseString] isEqualToString:@"mpg"] ||
             [[ext lowercaseString] isEqualToString:@"mpeg"])
        return @"VIDEO";
    else if ([[ext lowercaseString] isEqualToString:@"jpeg"] ||
             [[ext lowercaseString] isEqualToString:@"jpg"] ||
             [[ext lowercaseString] isEqualToString:@"png"] ||
             [[ext lowercaseString] isEqualToString:@"tiff"] ||
             [[ext lowercaseString] isEqualToString:@"tif"] ||
             [[ext lowercaseString] isEqualToString:@"gif"] ||
             [[ext lowercaseString] isEqualToString:@"bmp"] ||
             [[ext lowercaseString] isEqualToString:@"heic"])
        return @"PICTURE";
    else
        return @"DOCUMENT";
}

+ (UIImage *)getImageWithType:(NSString*)type ext:(NSString *)ext {
    if ([[ext lowercaseString] isEqualToString:@"pdf"])
        return [UIImage imageNamed:@"router_cut-24.png"];
    else if ([[ext lowercaseString] isEqualToString:@"doc"] || [[ext lowercaseString] isEqualToString:@"docx"] || [[ext lowercaseString] isEqualToString:@"pages"])
        return [UIImage imageNamed:@"router_cut-23.png"];
    else if ([[ext lowercaseString] isEqualToString:@"xls"] || [[ext lowercaseString] isEqualToString:@"xlsx"] || [[ext lowercaseString] isEqualToString:@"numbers"])
        return [UIImage imageNamed:@"btn_list_doc.png"];
    else if ([[ext lowercaseString] isEqualToString:@"ppt"] || [[ext lowercaseString] isEqualToString:@"pptx"] || [[ext lowercaseString] isEqualToString:@"key"])
        return [UIImage imageNamed:@"router_cut-26.png"];
    else if ([[ext lowercaseString] isEqualToString:@"txt"])
        return [UIImage imageNamed:@"router_cut-25.png"];
    else if ([[ext lowercaseString] isEqualToString:@"mp3"] || [[ext lowercaseString] isEqualToString:@"m4a"] || [[ext lowercaseString] isEqualToString:@"wav"] || [[ext lowercaseString] isEqualToString:@"aac"])
        return [UIImage imageNamed:@"btn_list_music.png"];
    else if ([[ext lowercaseString] isEqualToString:@"avi"])
        return [UIImage imageNamed:@"img_video.jpg"];
    else if ([[ext lowercaseString] isEqualToString:@"mp4"])
        return [UIImage imageNamed:@"img_video.jpg"];
    //    else if ([[ext lowercaseString] isEqualToString:@"m4v"])
    //        return [UIImage imageNamed:@"video.png"];
    //    else if ([[ext lowercaseString] isEqualToString:@"3gp"])
    //        return [UIImage imageNamed:@"video.png"];
    else if ([[ext lowercaseString] isEqualToString:@"mov"])
        return [UIImage imageNamed:@"img_video.jpg"];
    else if ([[ext lowercaseString] isEqualToString:@"mkv"])
        return [UIImage imageNamed:@"img_video.jpg"];
    else if ([[ext lowercaseString] isEqualToString:@"wmv"])
        return [UIImage imageNamed:@"img_video.jpg"];
    else if ([[ext lowercaseString] isEqualToString:@"asf"])
        return [UIImage imageNamed:@"img_video.jpg"];
    //else if ([[ext lowercaseString] isEqualToString:@"dv"])
    //    return [UIImage imageNamed:@"video.png"];
    //    else if ([[ext lowercaseString] isEqualToString:@"vob"])
    //        return [UIImage imageNamed:@"video.png"];
    else if ([[ext lowercaseString] isEqualToString:@"mpg"])
        return [UIImage imageNamed:@"img_video.jpg"];
    else if ([[ext lowercaseString] isEqualToString:@"mpeg"])
        return [UIImage imageNamed:@"img_video.jpg"];
    
    else if ([[ext lowercaseString] isEqualToString:@"jpg"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else if ([[ext lowercaseString] isEqualToString:@"jpeg"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else if ([[ext lowercaseString] isEqualToString:@"png"] || [[ext lowercaseString] isEqualToString:@"gif"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else if ([[ext lowercaseString] isEqualToString:@"tiff"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else if ([[ext lowercaseString] isEqualToString:@"tif"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else if ([[ext lowercaseString] isEqualToString:@"bmp"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else if ([[ext lowercaseString] isEqualToString:@"heic"])
        return [UIImage imageNamed:@"btn_list_photo.png"];
    else {
        if ([type isEqualToString:@"MUSIC"]) {
            return [UIImage imageNamed:@"btn_list_music.png"];
        } else if ([type isEqualToString:@"VIDEO"]) {
            return [UIImage imageNamed:@"img_video.jpg"];
        } else if ([type isEqualToString:@"PICTURE"]) {
            return [UIImage imageNamed:@"btn_list_photo.png"];
        } else if ([type isEqualToString:@"DOCUMENT"]) {
            return [UIImage imageNamed:@"btn_list_doc.png"];
        }
    }
    return [UIImage imageNamed:@"btn_list_doc.png"];
}

+ (UIImage *)getMusicCover:(NSString *)urlString {
//    NSString * s = [urlString substringFromIndex:1];
    NSURL *url = [NSURL fileURLWithPath:urlString];
    AVAsset *asset = [AVAsset assetWithURL:url];
//    UIImage* defaultImage = [UIImage imageNamed:@"music"];
    UIImage* defaultImage = nil;
    for (AVMetadataItem *metadataItem in asset.commonMetadata) {
        if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceID3]){
            if ([metadataItem.value isKindOfClass:[NSDictionary class]]) {
                NSDictionary *imageDataDictionary = (NSDictionary *)metadataItem.value;
                NSData *imageData = [imageDataDictionary objectForKey:@"data"];
                UIImage *image = [UIImage imageWithData:imageData];
                // Display this image on my UIImageView property imageView
                if (image) {
                    defaultImage = image;
                    break;
                }
            }else if([metadataItem.value isKindOfClass:[NSData class]]){
                UIImage *image = [UIImage imageWithData:(NSData*)metadataItem.value];
                if (image) {
                    defaultImage = image;
                    break;
                }
            }
        }else if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceiTunes]){
            if([[metadataItem.value copyWithZone:nil] isKindOfClass:[NSData class]]){
                UIImage* image = [UIImage imageWithData:[metadataItem.value copyWithZone:nil]];
                if (image) {
                    defaultImage = image;
                    break;
                }
            }
        }
    }
    
    return defaultImage;
}

+ (UIImage *)generateThumbImage:(NSString *)filepath {
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = [asset duration];
    time.value = 0;
    CGSize maxSize = CGSizeMake(320, 180);
    imageGenerator.maximumSize = maxSize;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return thumbnail;
}

@end
