//
//  IRGalleryPhoto.h
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IRGalleryPhotoDelegate;

@interface IRGalleryPhoto : NSObject {
    
    // value which determines if the photo was initialized with local file paths or network paths.
    BOOL _useNetwork;
    
    NSMutableData *_thumbData;
    NSMutableData *_fullsizeData;
    
    NSURLConnection *_thumbConnection;
    NSURLConnection *_fullsizeConnection;
}

- (id)initWithThumbnailUrl:(NSString*)thumb fullsizeUrl:(NSString*)fullsize delegate:(NSObject<IRGalleryPhotoDelegate>*)delegate;
- (id)initWithThumbnailPath:(NSString*)thumb fullsizePath:(NSString*)fullsize delegate:(NSObject<IRGalleryPhotoDelegate>*)delegate;

- (void)loadThumbnail;
- (void)loadFullsize;

- (void)unloadFullsize;
- (void)unloadThumbnail;

@property NSUInteger tag;

@property (nonatomic,readonly) NSString *thumbUrl;
@property (nonatomic,readonly) NSString *fullsizeUrl;

@property (readonly) BOOL isThumbLoading;
@property (readonly) BOOL hasThumbLoaded;

@property (readonly) BOOL isFullsizeLoading;
@property (readonly) BOOL hasFullsizeLoaded;

@property (nonatomic,readonly) UIImage *thumbnail;
@property (nonatomic,readonly) UIImage *fullsize;

@property (nonatomic,weak) id<IRGalleryPhotoDelegate> delegate;

#pragma mark - Progressive behavior messages
/// Launch the image download
-(void)loadImageAtURL:(NSURL*)url isThumbSize:(BOOL)isThumbSize;
/// This will remove all cached images managed by any NYXProgressiveImageView instances
+(void)resetImageCache;

+(NSUInteger)getCacheSize;

#pragma mark - Progressive behavior properties

// Enable / Disable caching
@property (nonatomic, getter = isCaching) BOOL caching;
// Cache time in seconds
@property (nonatomic) NSTimeInterval cacheTime;

@property (nonatomic) BOOL enableProgressive;

@property (nonatomic) UIImageOrientation imageOrientation;

@end

@protocol IRGalleryPhotoDelegate<NSObject>

@required
- (void)galleryPhoto:(IRGalleryPhoto*)photo didLoadThumbnail:(UIImage*)image;
- (void)galleryPhoto:(IRGalleryPhoto*)photo didLoadFullsize:(UIImage*)image;

@optional
- (void)galleryPhoto:(IRGalleryPhoto*)photo willLoadThumbnailFromUrl:(NSString*)url;
- (void)galleryPhoto:(IRGalleryPhoto*)photo willLoadFullsizeFromUrl:(NSString*)url;

- (void)galleryPhoto:(IRGalleryPhoto*)photo willLoadThumbnailFromPath:(NSString*)path;
- (void)galleryPhoto:(IRGalleryPhoto*)photo willLoadFullsizeFromPath:(NSString*)path;

- (void)galleryPhoto:(IRGalleryPhoto*)photo loadingFullsize:(UIImage*)image;
- (void)galleryPhoto:(IRGalleryPhoto*)photo loadingThumbnail:(UIImage*)image;

- (void)galleryPhoto:(IRGalleryPhoto*)photo showThumbnail:(BOOL)show;

- (UIImage*)galleryPhotoLoadThumbnailFromLocal:(IRGalleryPhoto*)photo;

@end


NS_ASSUME_NONNULL_END
