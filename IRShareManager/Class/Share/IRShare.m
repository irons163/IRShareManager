//
//  IRShare.m
//  IRShareManager
//
//  Created by Phil on 2020/1/9.
//  Copyright © 2020 Phil. All rights reserved.
//

#import "IRShare.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation IRShare {
    int inputItemsCount;
    int counter;
    dispatch_queue_t queue;
}

+ (instancetype)sharedInstance {
    static IRShare *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        queue = dispatch_queue_create("com.irons.IRShare", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)showSaveAlertIn:(UIViewController *)vc {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saving..." message:@"\n\n" preferredStyle:UIAlertControllerStyleAlert];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    indicator.center = CGPointMake(130.5, 65.5);
    [alert.view addSubview:indicator];
    [indicator startAnimating];
    
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)didSelectPostWith:(NSExtensionContext *)extensionContext {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    _extensionContext = extensionContext;
    inputItemsCount = 0;
    counter = 0;
    
    for(NSExtensionItem *item in extensionContext.inputItems){
        inputItemsCount += item.attachments.count;
    }

    for (NSExtensionItem *item in extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                [self loadFileBy:itemProvider item:item type:(NSString *)kUTTypeImage];
            }else if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeAudiovisualContent]){
                [self loadFileBy:itemProvider item:item type:(NSString *)kUTTypeAudiovisualContent];
            }else if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePDF]){
                [self loadFileBy:itemProvider item:item type:(NSString *)kUTTypePDF];
            }else if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePresentation]){
                [self loadFileBy:itemProvider item:item type:(NSString *)kUTTypePresentation];
            }else if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]){
                [self loadFileBy:itemProvider item:item type:(NSString *)kUTTypeFileURL];
            }else if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]){
                [self loadFileBy:itemProvider item:item type:(NSString *)kUTTypeURL];
            }else {
                counter++;
                if(counter >= inputItemsCount){
                    // Return any edited content to the host app.
                    // This template doesn't do anything, so we just echo the passed in items.
                    [extensionContext completeRequestReturningItems:extensionContext.inputItems completionHandler:nil];
                }
            }
        }
    }
    
}

- (void)loadFileBy:(NSItemProvider*)itemProvider item:(NSExtensionItem*)item type:(NSString*)type{
    [itemProvider loadItemForTypeIdentifier:type options:nil completionHandler:^(id file, NSError *error) {
        if(file) {
            NSString* fileName;
            
            if([[file class] isSubclassOfClass:[NSURL class]]){
                fileName = [file lastPathComponent];
                
                [self saveFileByNSFileManager:file fileName:fileName];
            }else if([[file class] isSubclassOfClass:[NSData class]]){
                NSString *MIMETypeStr = nil;
                for(NSString *registeredType in itemProvider.registeredTypeIdentifiers){
                    CFStringRef registeredUTI = (__bridge CFStringRef)registeredType;
                    BOOL isRegisteredIsKindOfType = UTTypeConformsTo(registeredUTI, (__bridge CFStringRef)type);
                    
                    if(isRegisteredIsKindOfType){
                        CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(registeredUTI, kUTTagClassMIMEType);
                        if(MIMEType){
                            MIMETypeStr = [(__bridge_transfer NSString *)MIMEType lastPathComponent];
                            break;
                        }
                    }
                }
                
                if(item.attributedTitle && item.attributedTitle.string)
                    fileName = item.attributedTitle.string;
                else
                    fileName = [self formatDate_yyyyMMddHHmmss:[NSDate date]];
                
                if([[fileName pathExtension] isEqualToString:@""] && MIMETypeStr)
                    fileName = [fileName stringByAppendingPathExtension:MIMETypeStr];
                
                [self saveFileByNSFileManager:file fileName:fileName];
                
                self->counter++;
                
                if(self->counter >= inputItemsCount){
                    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                }
            }else{
                self->counter++;
                
                if(self->counter >= inputItemsCount){
                    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                }
            }
        }else{
            self->counter++;
            
            if(self->counter >= inputItemsCount){
                // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }
        }
    }];
}

- (BOOL)saveFileByNSFileManager:(id)image fileName:(NSString*)fileName {
    NSError *err = nil;
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.groupID];
    containerURL = [containerURL URLByAppendingPathComponent:@"Library/Caches"];
    containerURL = [containerURL URLByAppendingPathComponent:fileName];
    
    containerURL = [NSURL fileURLWithPath:[self getNewFilePathIfExistsByFilePath:[containerURL path]]];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:[containerURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *value = @"";
    NSData * binaryImageData = nil;
    
    if([[image class] isSubclassOfClass:[NSURL class]]){
//        binaryImageData = [NSData dataWithContentsOfURL:image];
        
        __block NSError *error = nil;
        
        dispatch_async(queue, ^{
            NSURL * url = image;
            NSInputStream *stream = [NSInputStream inputStreamWithURL:url];
            
//            [stream setDelegate:self];
            [stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            [stream open];
            
            NSOutputStream *oStream = [NSOutputStream outputStreamWithURL:containerURL append:NO];
//            [oStream setDelegate:self];
            [oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
            [oStream open];
            
            while ([stream hasBytesAvailable] && [oStream hasSpaceAvailable]) {
                uint8_t buffer[1024];
                
                NSInteger bytesRead = [stream read:buffer maxLength:1024];
                if (stream.streamError || bytesRead < 0) {
                    error = stream.streamError;
                    break;
                }
                
                NSInteger bytesWritten = [oStream write:buffer maxLength:(NSUInteger)bytesRead];
                if (oStream.streamError || bytesWritten < 0) {
                    error = oStream.streamError;
                    break;
                }
                
                if (bytesRead == 0 && bytesWritten == 0) {
                    break;
                }
            }
            
            [oStream close];
            [stream close];
            
            self->counter++;
            
            if(self->counter >= inputItemsCount){
                // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }
            
//            if (handler) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    handler(error);
//                });
//            }
        });
        
        return YES;
    }else if([[image class] isSubclassOfClass:[NSData class]]){
        binaryImageData = image;
        
        BOOL result = [binaryImageData writeToURL:containerURL options:NSDataWritingAtomic error:&err];
        if (!result) {
            NSLog(@"%@",err);
        } else {
            NSLog(@"save value:%@ success.",value);
        }
        
        return result;
    }else{
        return NO;
    }
    
    
}

-(NSString*)formatDate_yyyyMMddHHmmss:(NSDate*)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSString *datestring = [formatter stringFromDate:date];
    return datestring;
}

-(NSString*)getNewFilePathIfExistsByFilePath:(NSString*)filePath{
    if (![self checkExistWithFilePath:filePath]) {
        return filePath;
    }else{
        
        NSString *filenameWithOutExtension = [filePath stringByDeletingPathExtension];
        NSString *ext = [filePath pathExtension];
        
        int limit = 999;
        NSString* newFilePath;
        for(int i = 0; i < limit; i++){
            newFilePath = [NSString stringWithFormat:@"%@(%d).%@", filenameWithOutExtension, i+1, ext];
            if(![self checkExistWithFilePath:newFilePath]){
                NSLog(@"%@", newFilePath);
                break;
            }
        }
        
        return newFilePath;
    }
}

-(BOOL)checkExistWithFilePath:(NSString*)filePath{
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return YES;
    return NO;
}

- (NSURL *)directoryURL {
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.groupID];
    directoryURL = [directoryURL URLByAppendingPathComponent:@"Library/Caches" isDirectory:YES];
    return directoryURL;
}

@end
