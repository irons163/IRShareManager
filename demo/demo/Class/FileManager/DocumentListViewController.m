//
//  DocumentListViewController.m
//  demo
//
//  Created by Phil on 2019/11/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "DocumentListViewController.h"
#import <IRMusicPlayer/IRMusicPlayer.h>
//#import "DataManager.h"
#import "PlayerViewController.h"
//#import "KxVideoViewController.h"
#import "File+CoreDataClass.h"
#import "AZAPreviewController.h"
#import "AZAPreviewItem.h"
#import "IRLanguageManager.h"
//#import "KGModal.h"
//#import "EnShareTools.h"
//#import "SuccessView.h"
//#import "CommonTools.h"
//#import "ColorDefine.h"
//#import "UIColor+Helper.h"
//#import "MyFavoritesCollectionViewCell.h"
//#import "File.h"
//#import "StorageDeleteView.h"
//#import "StorageSelectWarningView.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "Masonry.h"
#import "DemoUtility.h"

@implementation DocumentListViewController {
    NSMutableArray *items;
    NSMutableArray *photos;
    
    AZAPreviewController *previewController;
    AZAPreviewItem *previewItem;
  
    NSString *titleStr;
    NSOperationQueue *queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 2;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.importFile) {
        File *file = appDelegate.importFile;
        appDelegate.importFile = nil;
        
        [self openFile:file useArray:@[file]];
    }
    
    self.fileType = ALL_TYPE;
}

//-(void)createGallery{
//    galleryVC = [[OnlineFGalleryViewController alloc] initWithPhotoSource:self];
//    galleryVC.startingIndex = 0;
//    galleryVC.useThumbnailView = FALSE;
//    galleryVC.delegate = self;
//}

-(void)startAnimating{
    [self.loadingView startAnimating];
    [self.view setUserInteractionEnabled:NO];
    self.loadingView.hidden = NO;
}

-(void)stopAnimating{
    [self.loadingView stopAnimating];
    [self.view setUserInteractionEnabled:YES];
    self.loadingView.hidden = YES;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
}

-(void)viewWillAppear:(BOOL)animated{
    self.navigationItem.title = titleStr;
    [self.navigationController setNavigationBarHidden:NO];
    
    [self loadData];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //設定通知對應的函數
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(notificationHandle:)
                                                 name: @"ReloadNotificationHandle"
                                               object: nil];
}

//當通知發生時會執行此函數
- (void) notificationHandle: (NSNotification*) sender;
{
    NSLog(@"-notificationHandle");
    [self loadData];
}

-(NSString*)getFileTypeString:(FILE_TYPE)type{
    NSString* fileTypeString = nil;
    switch (type) {
        case DOCUMENT_TYPE:
            fileTypeString = @"DOCUMENT";
            break;
        case MUSIC_TYPE:
            fileTypeString = @"MUSIC";
            break;
        case VIDEO_TYPE:
            fileTypeString = @"VIDEO";
            break;
        case PHOTO_TYPE:
            fileTypeString = @"PICTURE";
            break;
        default:
            break;
    }
    
    return fileTypeString;
}

- (void)loadData {
    NSString* fileTypeString = [self getFileTypeString:self.fileType];
    
    items = [NSMutableArray array];
    photos = [NSMutableArray array];
    
    NSArray* readFromDB = nil;
    readFromDB = [File MR_findAll];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    for(File *file in readFromDB){
        [items addObject:file];
    }
    
    for(File *file in readFromDB){
        [photos addObject:file];
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* simpleTableIdentifier = @"Simple";
    DocumentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if(cell == nil){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"DocumentTableViewCell" owner:self options:nil] objectAtIndex:0];
    }
    
    File* file;
    
    file = ((File*)[items objectAtIndex:indexPath.row]);
    
    cell.titleLabel.text = file.name;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:file.name];
    
    if (self.fileType == VIDEO_TYPE) {
        [self setThumbToCell:cell byVideoPath:filePath];
    } else if(self.fileType == MUSIC_TYPE) {
        cell.thumbnailImageView.image = [DemoUtility getMusicCover:filePath];
        if(cell.thumbnailImageView.image==nil)
            cell.thumbnailImageView.image = [DemoUtility getImageWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
    } else if(self.fileType == DOCUMENT_TYPE) {
        cell.thumbnailImageView.image = [DemoUtility getImageWithType:@"DOCUMENT" ext:[cell.titleLabel.text pathExtension]];
    } else if(self.fileType == PHOTO_TYPE) {
        
    } else if(self.fileType == ALL_TYPE) {
        if ([file.type isEqualToString:@"VIDEO"]) {
            [self setThumbToCell:cell byVideoPath:filePath];
        } else if([file.type isEqualToString:@"MUSIC"]) {
            if(cell.thumbnailImageView.image==nil)
                cell.thumbnailImageView.image = [DemoUtility getImageWithType:@"MUSIC" ext:[cell.titleLabel.text pathExtension]];
        } else if([file.type isEqualToString:@"PICTURE"]) {
            cell.thumbnailImageView.image = [UIImage imageNamed:@"img_photo.jpg"];
            @autoreleasepool {
                [cell.thumbnailImageView setImageWithURL:[NSURL fileURLWithPath:filePath] placeholderImage:[UIImage imageNamed:@"img_photo.jpg"]  options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                }];
            }
        } else {
            cell.thumbnailImageView.image = [DemoUtility getImageWithType:file.type ext:[cell.titleLabel.text pathExtension]];
        }
    }
    
    cell.fileSizeLabel.text = [[NSString stringWithFormat:@"%lld", file.size] stringByAppendingString:@", "];
    [cell.fileSizeLabel setNumberOfLines:1];
    [cell.fileSizeLabel sizeToFit];
    CGRect newFrame = cell.createDateLabel.frame;
    newFrame.origin.x = cell.fileSizeLabel.frame.origin.x + cell.fileSizeLabel.frame.size.width;
    cell.createDateLabel.frame = newFrame;
    cell.createDateLabel.text = file.createTime.description;
    [cell.createDateLabel setNumberOfLines:1];
    [cell.createDateLabel sizeToFit];
    
    cell.delegate = self;
    cell.file = file;
    
    return cell;
}

- (void)setThumbToCell:(DocumentTableViewCell*)cell byVideoPath:(NSString*)filePath {
    if(!cell.operation){
        [cell.operation cancel];
    }
    
    cell.thumbnailImageView.image = [DemoUtility getImageWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
    
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *image = [DemoUtility generateThumbImage:filePath];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            cell.thumbnailImageView.image = image;
            if(cell.thumbnailImageView.image==nil)
                cell.thumbnailImageView.image = [DemoUtility getImageWithType:@"VIDEO" ext:[cell.titleLabel.text pathExtension]];
        }];
    }];
    
    cell.operation = operation;
    
    [queue addOperation:operation];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DocumentTableViewCell *docCell = (DocumentTableViewCell*)cell;
    if(!docCell.operation){
        [docCell.operation cancel];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *useArray = nil;
    File *item;

    useArray = items;
    item = items[indexPath.row];
    
    [self openFile:item useArray:useArray];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)openFile:(File*)item useArray:(NSArray*)useArray {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"type %@",[item valueForKey:@"type"]);
    //    NSLog(@"type %@",[item objectForKeyedSubscript:@"type"]);
    if ([item.type isEqualToString:@"MUSIC"]) {
        // 播放元件
        
        MusicPlayerViewController *playerViewController = [[MusicPlayerViewController alloc] init];
        
        int c=0;
        for (File *dict in useArray) {
            NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:dict.name];
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:file, @"musicAddress", dict.name, @"musicName", nil];
            [playerViewController.musicListArray addObject:dictionary];
            if ([dict.name isEqualToString:item.name]) {
                playerViewController.musicIndex = c;
            }
            c++;
        }
        
        [self presentViewController:playerViewController animated:YES completion:nil];
    } else if ([item.type isEqualToString:@"VIDEO"]) {
        int c = 0, videoPosition = 0;
        NSMutableArray *videoArray = [[NSMutableArray alloc] init];
        for (File *dict in useArray) {
            if ([[dict.name lowercaseString] rangeOfString:@".mov"].length>0 || [[dict.name lowercaseString] rangeOfString:@".avi"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".mp4"].length>0 || [[dict.name lowercaseString] rangeOfString:@".3gp"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".m4v"].length>0 || [[dict.name lowercaseString] rangeOfString:@".mkv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".wmv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".asf"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".dv"].length>0 || [[dict.name lowercaseString] rangeOfString:@".vob"].length>0 ||
                [[dict.name lowercaseString] rangeOfString:@".mpg"].length>0) {
                
                NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:dict.name];
                [videoArray addObject:file];
                //                LogMessage(nil, 0, @"file %@", file);
                
                if ([dict.name isEqualToString:item.name]) {
                    videoPosition = c;
                }
                c++;
            }
        }
        
        PlayerViewController *videoViewController = [[PlayerViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:videoViewController];
        navigationController.navigationBar.barStyle = UIBarStyleBlack;
        navigationController.navigationBarHidden = YES;
        [self presentViewController:navigationController animated:YES completion:nil];
        
    } else if ([item.type isEqualToString:@"PICTURE"]) {
        int idx = 0;
        for (File *photo in photos) {
            if ([photo.name isEqualToString:item.name])
                break;
            idx++;
        }
        IRGalleryViewController *galleryVC = [[IRGalleryViewController alloc] initWithPhotoSource:self];
        galleryVC.startingIndex = idx;
        galleryVC.useThumbnailView = FALSE;
        galleryVC.delegate = self;
        [galleryVC gotoImageByIndex:idx animated:NO];
        [self.navigationController pushViewController:galleryVC animated:YES];
    } else if ([item.type isEqualToString:@"DOCUMENT"]) {
        // 預覽
        NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:item.name];
        previewItem = [AZAPreviewItem previewItemWithURL:[NSURL fileURLWithPath:file] title:[[file pathComponents] lastObject]];
        previewController = [[AZAPreviewController alloc] init];
        previewController.dataSource = self;
        previewController.delegate = self;
        [self presentViewController:previewController animated:YES completion:nil];
    }
}

- (BOOL)isTheStringDate: (NSString*) theString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *dateFromString = [[NSDate alloc] init];
    
    dateFromString = [dateFormatter dateFromString:theString];
    
    if (dateFromString !=nil) {
        return true;
    }
    else {
        return false;
    }
}

#pragma mark - IRGalleryViewControllerDelegate
- (int)numberOfPhotosForPhotoGallery:(IRGalleryViewController *)gallery {
    return photos.count;
}

- (IRGalleryPhotoSourceType)photoGallery:(IRGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    return IRGalleryPhotoSourceTypeLocal;
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index {
    NSString *filename = [NSString stringWithFormat:@"%@", ((File*)photos[index]).name];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(IRGalleryViewController *)gallery urlForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index {
    NSString *filename = [NSString stringWithFormat:@"%@", photos[index]];
    return [[filename pathComponents] lastObject];
}

- (NSString*)photoGallery:(IRGalleryViewController*)gallery filePathForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *str = [[paths objectAtIndex:0] stringByAppendingPathComponent:[photos[index] valueForKey:@"name"]];
    return str;
}

- (bool)photoGallery:(IRGalleryViewController*)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index{
    return NO;
}

- (void)photoGallery:(IRGalleryViewController*)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index{

}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    return previewItem;
}

#pragma mark - AZAPreviewControllerDelegate

- (void)AZA_previewController:(AZAPreviewController *)controller failedToLoadRemotePreviewItem:(id<QLPreviewItem>)previewItem withError:(NSError *)error{
}

- (void)backBtnDidClick {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)cancelClick {
    [self.tableView reloadData];
    
    self.tableView.allowsMultipleSelection = NO;
}

- (void)setFileType:(FILE_TYPE)fileType {
    self->_fileType = fileType;
    
    switch (fileType) {
        case DOCUMENT_TYPE:
            titleStr = _(@"Documents List");
            break;
        case VIDEO_TYPE:
            titleStr = _(@"Videos List");
            break;
        case PHOTO_TYPE:
            titleStr = _(@"Photos List");
            break;
        case MUSIC_TYPE:
            titleStr = _(@"Musics List");
            break;
        case ALL_TYPE:
            titleStr = _(@"Files List");
            break;
    }
    
    self.navigationItem.title = titleStr;
}

@end
