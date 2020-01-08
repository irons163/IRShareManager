//
//  IRGalleryViewController.h
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "IRGalleryPhoto.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum
{
    IRGalleryPhotoSizeThumbnail,
    IRGalleryPhotoSizeFullsize
} IRGalleryPhotoSize;

typedef enum
{
    IRGalleryPhotoSourceTypeNetwork,
    IRGalleryPhotoSourceTypeLocal
} IRGalleryPhotoSourceType;

@protocol IRGalleryViewControllerDelegate;
@protocol IRGalleryViewControllerSourceDelegate;

@interface IRGalleryViewController : UIViewController <UIScrollViewDelegate,IRGalleryPhotoDelegate, UIDocumentInteractionControllerDelegate> {
    
    BOOL _isActive;
    BOOL _isFullscreen;
    BOOL _isScrolling;
    BOOL _isThumbViewShowing;
    
    UIStatusBarStyle _prevStatusStyle;
    CGFloat _prevNextButtonSize;
    CGRect _scrollerRect;
    NSInteger _currentIndex;
    
    UIView *_container; // used as view for the controller
    UIView *_innerContainer; // sized and placed to be fullscreen within the container
    UIToolbar *_toolbar;
    UIScrollView *_thumbsView;
    UICollectionView *_collectionView;
    
    NSMutableDictionary *_photoLoaders;
    NSMutableArray *_barItems;
    
    UIBarButtonItem *_deleteButton;
    UIBarButtonItem *_favoriteButton;
    UIBarButtonItem *_sendButton;
    
    UIActivityIndicatorView *activityIndicator;
}

- (id)initWithPhotoSource:(id<IRGalleryViewControllerSourceDelegate>)photoSrc;
- (id)initWithPhotoSource:(id<IRGalleryViewControllerSourceDelegate>)photoSrc barItems:(NSArray*)items;

- (void)next;
- (void)previous;
- (void)gotoImageByIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)reloadGallery;
- (void)setSlideEnable:(BOOL)enable;

- (IRGalleryPhoto*)currentPhoto;

@property NSInteger currentIndex;
@property NSInteger startingIndex;
@property (nonatomic, weak) id<IRGalleryViewControllerSourceDelegate> photoSource;
@property (nonatomic, readonly) UIToolbar *toolBar;
@property (nonatomic, readonly) UIView* thumbsView;
@property (nonatomic, strong) NSString *galleryID;
@property (nonatomic) BOOL useThumbnailView;
@property (nonatomic) BOOL beginsInThumbnailView;
@property (nonatomic) BOOL hideTitle;
@property (nonatomic) BOOL scrollEnable;
@property (nonatomic, weak) id<IRGalleryViewControllerDelegate> delegate;
@property (nonatomic, strong) UIDocumentInteractionController *fileInteractionController;
@property (nonatomic) UIImageView *preDisplayView;

@end


@protocol IRGalleryViewControllerSourceDelegate<NSObject>

@required
- (int)numberOfPhotosForPhotoGallery:(IRGalleryViewController*)gallery;
- (IRGalleryPhotoSourceType)photoGallery:(IRGalleryViewController*)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index;

@optional
- (NSString*)photoGallery:(IRGalleryViewController*)gallery captionForPhotoAtIndex:(NSUInteger)index;

// the photosource must implement one of these methods depending on which IRGalleryPhotoSourceType is specified
- (NSString*)photoGallery:(IRGalleryViewController*)gallery filePathForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index;
- (NSString*)photoGallery:(IRGalleryViewController*)gallery urlForPhotoSize:(IRGalleryPhotoSize)size atIndex:(NSUInteger)index;
- (bool)photoGallery:(IRGalleryViewController*)gallery isFavoriteForPhotoAtIndex:(NSUInteger)index;
- (UIImage*)photoGallery:(IRGalleryViewController*)gallery loadThumbnailFromLocalAtIndex:(NSUInteger)index;

@end

@protocol IRGalleryViewControllerDelegate<NSObject>

@optional

- (void)photoGallery:(IRGalleryViewController*)gallery deleteAtIndex:(NSUInteger)index;
- (void)photoGallery:(IRGalleryViewController*)gallery addFavorite:(bool)isAddToFavortieList atIndex:(NSUInteger)index;

@end


NS_ASSUME_NONNULL_END
