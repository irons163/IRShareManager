//
//  AppDelegate.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoUtility.h"
#import <IRShareManager/IRShareManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Setup CoreData with MagicalRecord
    // Step 1. Setup Core Data Stack with Magical Record
    // Step 2. Relax. Why not have a beer? Surely all this talk of beer is making you thirsty…
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"demo"];
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //        [self saveNotificationIfExistInActionExtention];
            [self saveImageIfExistInActionExtention];
            
        });
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
    NSLog(@"applicationWillEnterForeground");

    [self saveImageIfExistInActionExtention];
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

//share from ShareExtention
-(void)saveImageIfExistInActionExtention{
    [IRShare sharedInstance].groupID = @"group.com.irons163.IRShare";
    NSURL *directoryURL = [IRShare sharedInstance].directoryURL;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSLog(@"%@", [NSString stringWithFormat:@"directoryURL:%@" , directoryURL]);
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    if(!directoryURL)
        return;
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *url in enumerator) {
        NSLog(@"url:%@", url);
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (! [isDirectory boolValue]) {
            [self saveImportFileIntoDB:url autoOpenFileWhileAPPapear:NO];
        }
        
        [urlsToDelete addObject:url];
    }
    
    if(urlsToDelete.count > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName: @"ReloadNotificationHandle" object:nil];
        });
    }
    
    for(NSURL *url in urlsToDelete){
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
}

- (void)saveImportFileIntoDB:(NSURL *)url autoOpenFileWhileAPPapear:(BOOL)autoOpen {
    NSString *fileName = [[url absoluteString] lastPathComponent];
    fileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *resourceDocPath = [[NSString alloc] initWithString:[[NSTemporaryDirectory() stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Documents"]];
    
    fileName = [self getNewFileNameIfExistsByFileName:fileName];
    
    NSString *filePath = [resourceDocPath stringByAppendingPathComponent:fileName];

    [[NSFileManager defaultManager] copyItemAtPath:[url path] toPath:filePath error:nil];

    NSString *fileTypeString = [DemoUtility getFileType:[fileName pathExtension]];
    File *file = [File MR_createEntity];
    file.name = fileName;
    file.type = fileTypeString;
    file.size = [[DemoUtility getFileSize:filePath] longLongValue];
    file.createTime = [DemoUtility getFileCreationTimeFromPath:filePath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"You successfully saved your context.");
            } else if (error) {
                NSLog(@"Error saving context: %@", error.description);
            }
        }];
    });
    
    if(!autoOpen)
        return;
    
    self.importFile = file;
}



-(NSString*)getNewFileNameIfExistsByFileName:(NSString*)fullfilename{
    if (![self checkExistWithFileName:fullfilename]) {
        return fullfilename;
    }else{
        
        NSString *filenameWithOutExtension = [fullfilename stringByDeletingPathExtension];
        NSString *ext = [fullfilename pathExtension];
        
        int limit = 999;
        NSString* newFilename;
        for(int i = 0; i < limit; i++){
            newFilename = [NSString stringWithFormat:@"%@(%d).%@", filenameWithOutExtension, i+1, ext];
            if(![self checkExistWithFileName:newFilename]){
                NSLog(nil, 0, @"%@", newFilename);
                break;
            }
        }
        
        if(newFilename==nil){
            
             NSString *ext = [NSString stringWithFormat:@".%@",[fullfilename pathExtension]];
             NSString *fileName = [[fullfilename lastPathComponent] stringByDeletingPathExtension];
             NSString *folder = [fullfilename stringByReplacingOccurrencesOfString:fileName withString:@""];
             folder = [folder stringByReplacingOccurrencesOfString:ext withString:@""];
             
             NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
             NSDate *date = [NSDate date];
             [formatter setDateFormat:@"YYYYMMddhhmmss'"];
             NSString *today = [formatter stringFromDate:date];
             
             newFilename = [NSString stringWithFormat:@"%@%@_%@.%@", folder, fileName, today, [fullfilename pathExtension]];
             NSLog(@"%@", newFilename);
            
        }
        
        return newFilename;
    }
}

-(BOOL)checkExistWithFileName:(NSString*)fullfilename{
    /*
    NSString *uid = [[DataManager sharedInstance].database getSqliteString:[NSString stringWithFormat:@"SELECT uid FROM Collection WHERE type = '%@' AND filename = '%@'; ", [[DataManager sharedInstance] getType:[fullfilename pathExtension]], fullfilename]];
    if (uid.length == 0)
        return NO;
    return YES;
     */
    return NO;
}


@end
