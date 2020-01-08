//
//  IRGalleryViewController.m
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGalleryViewController.h"
#import "IRGalleryPhotoView.h"
#import "Utility.h"
#import "UIImage+Bundle.h"

#define kThumbnailSize 75
#define kThumbnailSpacing 4
#define kCaptionPadding 3
#define kToolbarHeight 45

@interface MyCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IRGalleryPhotoView *imageView;

@end

@implementation MyCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]){
        CGRect imageFrame = frame;
        imageFrame.origin = CGPointZero;
        
        self.imageView = [[IRGalleryPhotoView alloc] initWithFrame:imageFrame];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.autoresizesSubviews = YES;
        self.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];
    }
    
    return self;
}

- (void)prepareForReuse {
    [self.imageView setFrame:self.contentView.frame];
}

@end

@interface MyUICollectionViewFlowLayout : UICollectionViewFlowLayout
@end

@implementation MyUICollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *newAttributes = [NSMutableArray arrayWithCapacity:attributes.count];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        if ((attribute.frame.origin.x + attribute.frame.size.width <= self.collectionViewContentSize.width) &&
            (attribute.frame.origin.y + attribute.frame.size.height <= self.collectionViewContentSize.height)) {
            [newAttributes addObject:attribute];
        }
    }
    return newAttributes;
}

@end

@interface IRGalleryViewController (Private) <UICollectionViewDelegate, UICollectionViewDataSource, IRGalleryPhotoViewDelegate>

// general
- (void)destroyViews;
- (void)layoutViews;
- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation;
- (void)updateTitle;
- (void)updateButtons;
- (void)layoutButtons;
- (void)updateScrollSize;
- (void)updateCaption;
- (void)resizeImageViewsWithRect:(CGRect)rect;
- (void)resetImageViewZoomLevels;

- (void)enterFullscreen;
- (void)exitFullscreen;
- (void)enableApp;
- (void)disableApp;

- (void)positionInnerContainer;
- (void)positionToolbar;

// thumbnails
- (void)toggleThumbnailViewWithAnimation:(BOOL)animation;
- (void)showThumbnailViewWithAnimation:(BOOL)animation;
- (void)hideThumbnailViewWithAnimation:(BOOL)animation;

- (void)preloadThumbnailImages;
- (void)unloadFullsizeImageWithIndex:(NSUInteger)index;

- (void)scrollingHasEnded;

- (IRGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index;

- (void)loadThumbnailImageWithIndex:(NSUInteger)index;
- (void)loadFullsizeImageWithIndex:(NSUInteger)index;

- (void)shareClk:(id)sender;
- (void)shareByFileURLStringWithPath:(NSString*)fileURLStringWithPath;

@end

@implementation IRGalleryViewController

#pragma mark - Public Methods
- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
    if((self = [super initWithNibName:nil bundle:nil])) {
        // init gallery id with our memory address
        self.galleryID = [NSString stringWithFormat:@"%p", self];

        // configure view controller
        self.hidesBottomBarWhenPushed = YES;
        
        // set defaults
        _useThumbnailView = YES;
        _prevStatusStyle = [[UIApplication sharedApplication] statusBarStyle];
        _hideTitle = NO;
        
        // create storage objects
        _currentIndex = 0;
        _startingIndex = 0;
        _photoLoaders = [[NSMutableDictionary alloc] init];
        _barItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        self.galleryID = [NSString stringWithFormat:@"%p", self];
        
        // configure view controller
        self.hidesBottomBarWhenPushed = YES;
        
        // set defaults
        _useThumbnailView = YES;
        _prevStatusStyle = [[UIApplication sharedApplication] statusBarStyle];
        _hideTitle = NO;
        
        // create storage objects
        _currentIndex = 0;
        _startingIndex = 0;
        _photoLoaders = [[NSMutableDictionary alloc] init];
        _barItems = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithPhotoSource:(id<IRGalleryViewControllerSourceDelegate>)photoSrc {
    if((self = [self initWithNibName:nil bundle:nil])) {
        _photoSource = photoSrc;
        
        _container = [[UIView alloc] initWithFrame:CGRectZero];
        _innerContainer = [[UIView alloc] initWithFrame:CGRectZero];
//        MyUICollectionViewFlowLayout *flowLayout =[[MyUICollectionViewFlowLayout alloc]init];
//        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:flowLayout];
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
        _thumbsView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        _toolbar.barStyle = UIBarStyleDefault;
        _toolbar.barTintColor = [UIColor whiteColor];
        _container.backgroundColor = [UIColor whiteColor];
        
    
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        // make things flexible
        _container.autoresizesSubviews = NO;
        _innerContainer.autoresizesSubviews = NO;
        _collectionView.autoresizesSubviews = NO;
        _container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // set view
        self.view = _container;
        
        _preDisplayView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _preDisplayView.backgroundColor = [UIColor whiteColor];
        _preDisplayView.hidden = NO;
        _preDisplayView.contentMode = UIViewContentModeScaleAspectFit;
        
        // add items to their containers
        [_container addSubview:_innerContainer];
        [_innerContainer addSubview:_collectionView];
        [_innerContainer addSubview:_toolbar];
        
        [self positionInnerContainer];
        [self positionCollectionView];
        [self positionToolbar];
        
        [self createToolbarItems];
        _prevNextButtonSize = 30;
        
        // set buttons on the toolbar.
        NSMutableArray *items = [NSMutableArray arrayWithArray:_barItems];
        for(int i = 1; i < items.count; i+=2){
            UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [items insertObject:space atIndex:i];
        }
        [_toolbar setItems:items animated:NO];
        [self initMyFavorites];
        [self reloadGallery];
        if( _currentIndex == -1 ) [self next];
        
        [activityIndicator stopAnimating];
        activityIndicator = nil;
    }
    
    return self;
}

- (id)initWithPhotoSource:(id<IRGalleryViewControllerSourceDelegate>)photoSrc barItems:(NSArray *)items {
    if((self = [self initWithPhotoSource:photoSrc])) {
        // Use custom batItems.
        [_barItems removeAllObjects];
        [_barItems addObjectsFromArray:items];
    }
    return self;
}

- (void)destroyViews {
    // remove photo loaders
    NSArray *photoKeys = [_photoLoaders allKeys];
    for (int i=0; i<[photoKeys count]; i++) {
        IRGalleryPhoto *photoLoader = [_photoLoaders objectForKey:[photoKeys objectAtIndex:i]];
        photoLoader.delegate = nil;
        [photoLoader unloadFullsize];
        [photoLoader unloadThumbnail];
    }
    [_photoLoaders removeAllObjects];
}

- (void)reloadGallery {
    _currentIndex = _startingIndex;
    _isThumbViewShowing = NO;
    
    // remove the old
    [self destroyViews];
    
    NSLog(@"Load start");
    // build the new
    if ([_photoSource numberOfPhotosForPhotoGallery:self] > 0) {
        [self layoutViews];
    }
}

- (void)buildGalleryViews {
    NSLog(@"Load start");
    // build the new
    if ([_photoSource numberOfPhotosForPhotoGallery:self] > 0) {
        
        NSLog(@"buildView Finish");
        
        // layout
        [self layoutViews];
        
        NSLog(@"reloadGallery Finish");
    }
}

- (void)createToolbarItems {
    // create buttons for toolbar
    UIButton* doDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    
    UIImage *image = [UIImage imageNamedForCurrentBundle:@"btn_trash"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamedForCurrentBundle:@"btn_trash"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(20, 26.67)];
    [doDeleteButton setImage:image forState:UIControlStateHighlighted];
    [doDeleteButton addTarget:self action:@selector(deleteClk:) forControlEvents:UIControlEventTouchUpInside];
    _deleteButton = [[UIBarButtonItem alloc] initWithCustomView:doDeleteButton];
    
    UIButton* doFavoriteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    image = [UIImage imageNamedForCurrentBundle:@"btn_video_heart"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(21.4, 20)];
    [doFavoriteButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamedForCurrentBundle:@"btn_video_heart"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(21.4, 20)];
    [doFavoriteButton setImage:image forState:UIControlStateHighlighted];
    image = [UIImage imageNamedForCurrentBundle:@"btn_heart_h"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(21.4, 20)];
    [doFavoriteButton setImage:image forState:UIControlStateSelected];
    [doFavoriteButton addTarget:self action:@selector(addToMyFavoritesClk:) forControlEvents:UIControlEventTouchUpInside];
    _favoriteButton = [[UIBarButtonItem alloc] initWithCustomView:doFavoriteButton];
    
    UIButton* doSendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    image = [UIImage imageNamedForCurrentBundle:@"btn_video_send"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [doSendButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamedForCurrentBundle:@"btn_video_send"];
    image = [Utility imageWithImage:image scaledToSize:CGSizeMake(25, 25)];
    [doSendButton setImage:image forState:UIControlStateHighlighted];
    [doSendButton addTarget:self action:@selector(shareClk:) forControlEvents:UIControlEventTouchUpInside];
    _sendButton = [[UIBarButtonItem alloc] initWithCustomView:doSendButton];
    
    [_barItems insertObject:_sendButton atIndex:0];
    [_barItems insertObject:_favoriteButton atIndex:0];
    [_barItems insertObject:_deleteButton atIndex:0];
}

- (IRGalleryPhoto *)currentPhoto {
    return [_photoLoaders objectForKey:[NSString stringWithFormat:@"%li", (long)_currentIndex]];
}

- (void)viewDidLoad {
    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear Start");
    [super viewWillAppear:animated];
    
    _isActive = YES;
    
    self.useThumbnailView = _useThumbnailView;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _isActive = NO;

    [[UIApplication sharedApplication] setStatusBarStyle:_prevStatusStyle animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    _preDisplayView.hidden = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [_collectionView.collectionViewLayout invalidateLayout];
}

- (void)updateItemSize {
    CGRect newFrame = _collectionView.frame;
    newFrame.origin.y = self.view.bounds.origin.y + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    newFrame.size.height = self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - kToolbarHeight;
    newFrame.size.width = self.view.bounds.size.width;
//    _collectionView.frame = newFrame;
//    newFrame.size.height = newFrame.size.height - 2;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).sectionInset = UIEdgeInsetsMake(newFrame.size.width < newFrame.size.height ? 20 : 20, 0, 0, 0);
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize = newFrame.size;
    [_collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLayoutSubviews {
    [self updateItemSize];
}

- (void)resizeImageViewsWithRect:(CGRect)rect {
    _preDisplayView.frame = rect;
}

- (void)next {
    NSUInteger numberOfPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
    NSUInteger nextIndex = _currentIndex+1;
    
    // don't continue if we're out of images.
    if( nextIndex <= numberOfPhotos )
    {
        [self gotoImageByIndex:nextIndex animated:NO];
    }
}

- (void)previous {
    NSUInteger prevIndex = _currentIndex-1;
    [self gotoImageByIndex:prevIndex animated:NO];
}

- (void)gotoImageByIndex:(NSUInteger)index animated:(BOOL)animated {
    NSUInteger numPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
    
    // constrain index within our limits
    if( index >= numPhotos ) index = numPhotos - 1;
    
    
    if( numPhotos == 0 ) {
        // no photos!
        _currentIndex = -1;
    }
    else {
        
        // clear the fullsize image in the old photo
        [self unloadFullsizeImageWithIndex:_currentIndex];
        
        _currentIndex = index;
        [self moveScrollerToCurrentIndexWithAnimation:animated];
        [self updateTitle];
        
        if( !animated )    {
            [self preloadThumbnailImages];
            [self loadFullsizeImageWithIndex:index];
        }
    }
    [self updateButtons];
    [self updateCaption];
}

- (void)layoutViews {
    NSLog(@"layoutViews go");
    [self positionInnerContainer];
    [self positionToolbar];
    [self updateScrollSize];
    [self updateCaption];
//    [self resizeImageViewsWithRect:_scroller.frame];
    [self resizeImageViewsWithRect:_collectionView.frame];
    [self layoutButtons];
    [self moveScrollerToCurrentIndexWithAnimation:NO];
    NSLog(@"layoutViews end");
}

- (void)setUseThumbnailView:(BOOL)useThumbnailView {
    [self setNavigatinItem];
    
    _useThumbnailView = useThumbnailView;
}

- (void)setNavigatinItem {
    self.navigationItem.hidesBackButton = YES;
    UIView* leftview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage* backImage = [UIImage imageNamedForCurrentBundle:@"btn_nav_back.png"];
    UIImage* iBackImage = [UIImage imageNamedForCurrentBundle:@"ibtn_nav_back"];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (iBackImage) {
        [backButton setImage:iBackImage forState:UIControlStateHighlighted];
    }
    [backButton setImage:backImage forState:UIControlStateNormal];
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect backButtonFrame = backButton.frame;
    backButtonFrame.origin.x = 0 ;
    backButtonFrame.origin.y = 5 ;
    backButtonFrame.size.width = 35.f;
    backButtonFrame.size.height = 24.f;
    backButton.frame = backButtonFrame;
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    [backButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [backButton addTarget:self action:@selector(closeClk:) forControlEvents:UIControlEventTouchUpInside];
    
    [leftview addSubview:backButton];
    
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftview];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacer setWidth:-10];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, leftItem, nil];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

#pragma mark - Private Methods
- (void)positionInnerContainer {
//    CGRect screenFrame = [[UIScreen mainScreen] bounds];
//    CGRect innerContainerRect;
//
//    if( self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown )
//    {//portrait
//        innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.height , _container.frame.size.width, screenFrame.size.height);
//    }
//    else
//    {// landscape
//        innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.width, _container.frame.size.width, screenFrame.size.width );
//    }
//
//    _innerContainer.frame = innerContainerRect;
    
    _innerContainer.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:_innerContainer attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_innerContainer.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:_innerContainer attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_innerContainer.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    NSLayoutConstraint * bottomConstraint = [NSLayoutConstraint constraintWithItem:_innerContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_innerContainer.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:_innerContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_innerContainer.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    bottomConstraint.active = YES;
    topConstraint.active = YES;
    leadingConstraint.active = YES;
    trailingConstraint.active = YES;
}

- (void)positionCollectionView {
    _collectionView.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_collectionView.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_collectionView.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    NSLayoutConstraint * bottomConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_collectionView.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_collectionView.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    bottomConstraint.active = YES;
    topConstraint.active = YES;
    leadingConstraint.active = YES;
    trailingConstraint.active = YES;
}

- (void)positionToolbar {
    _toolbar.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:_toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_toolbar.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:_toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_toolbar.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    NSLayoutConstraint * bottomConstraint = [NSLayoutConstraint constraintWithItem:_toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toolbar.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint = nil;
    if (@available(iOS 11.0, *)) {
        topConstraint = [_toolbar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
        topConstraint.constant = -44;
    } else {
        topConstraint = [NSLayoutConstraint constraintWithItem:_toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-44];
    }
    
    bottomConstraint.active = YES;
    topConstraint.active = YES;
    leadingConstraint.active = YES;
    trailingConstraint.active = YES;
}

- (void)enterFullscreen {
    if (!_isThumbViewShowing) {
        _isFullscreen = YES;
        
        [self disableApp];
        
        UIApplication* application = [UIApplication sharedApplication];
        if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
            [[UIApplication sharedApplication] setStatusBarHidden: YES withAnimation: UIStatusBarAnimationFade]; // 3.2+
        } else {
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] setStatusBarHidden: YES animated:YES]; // 2.0 - 3.2
    #pragma GCC diagnostic warning "-Wdeprecated-declarations"
        }
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        [UIView beginAnimations:@"galleryOut" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(enableApp)];
        _toolbar.alpha = 0.0;
//        _captionContainer.alpha = 0.0;
        [UIView commitAnimations];
    }
}

- (void)exitFullscreen {
    _isFullscreen = NO;
    
    [self disableApp];
    
    UIApplication* application = [UIApplication sharedApplication];
    if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade]; // 3.2+
    } else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; // 2.0 - 3.2
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIView beginAnimations:@"galleryIn" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(enableApp)];
    _toolbar.alpha = 1.0;
//    _captionContainer.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)enableApp {
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}


- (void)disableApp {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

- (void)setSlideEnable:(BOOL)enable {
    _collectionView.scrollEnabled = enable;
}

- (void)updateCaption {
    /*
    if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
    {
        if([_photoSource respondsToSelector:@selector(photoGallery:captionForPhotoAtIndex:)])
        {
            NSString *caption = [_photoSource photoGallery:self captionForPhotoAtIndex:_currentIndex];
            
            if([caption length] > 0 )
            {
                float captionWidth = _container.frame.size.width-kCaptionPadding*2;
                CGSize textSize = [caption sizeWithFont:_caption.font];
                NSUInteger numLines = ceilf( textSize.width / captionWidth );
                NSInteger height = ( textSize.height + kCaptionPadding ) * numLines;
                
                _caption.numberOfLines = numLines;
                _caption.text = caption;
                
                NSInteger containerHeight = height+kCaptionPadding*2;
                _captionContainer.frame = CGRectMake(0, -containerHeight, _container.frame.size.width, containerHeight );
                _caption.frame = CGRectMake(kCaptionPadding, kCaptionPadding, captionWidth, height );
                
                // show caption bar
                _captionContainer.hidden = NO;
            }
            else {
                
                // hide it if we don't have a caption.
                _captionContainer.hidden = YES;
            }
        }
    }*/
    
    if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
    {
        if([_photoSource respondsToSelector:@selector(photoGallery:captionForPhotoAtIndex:)])
        {
            NSString *caption = [_photoSource photoGallery:self captionForPhotoAtIndex:_currentIndex];
            self.navigationItem.title = caption;
//            [caption release];
//            caption = nil;
        }
    }
}


- (void)updateScrollSize {
//    float contentWidth = _scroller.frame.size.width * [_photoSource numberOfPhotosForPhotoGallery:self];
//    [_scroller setContentSize:CGSizeMake(contentWidth, _scroller.frame.size.height - 80)];
    float contentWidth = _collectionView.frame.size.width * [_photoSource numberOfPhotosForPhotoGallery:self];
    [_collectionView setContentSize:CGSizeMake(contentWidth, _collectionView.frame.size.height - 80)];
}

- (void)updateTitle {
//    if (!_hideTitle){
//        [self setTitle:[NSString stringWithFormat:@"%i %@ %i", _currentIndex+1, NSLocalizedString(@"of", @"") , [_photoSource numberOfPhotosForPhotoGallery:self]]];
//    }else{
//        [self setTitle:@""];
//    }
}

- (void)updateButtons {
//    _prevButton.enabled = ( _currentIndex <= 0 ) ? NO : YES;
//    _nextButton.enabled = ( _currentIndex >= [_photoSource numberOfPhotosForPhotoGallery:self]-1 ) ? NO : YES;
    if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
    {
        if([_photoSource respondsToSelector:@selector(photoGallery:isFavoriteForPhotoAtIndex:)])
        {
            bool isFavorite = [_photoSource photoGallery:self isFavoriteForPhotoAtIndex:_currentIndex];
            ((UIButton*)[_favoriteButton customView]).selected = isFavorite;
        }
    }
}

- (void)layoutButtons {
    NSUInteger buttonWidth = roundf( _toolbar.frame.size.width / [_barItems count] - _prevNextButtonSize * .5);
    
    // loop through all the button items and give them the same width
    NSUInteger i, count = [_barItems count];
    for (i = 0; i < count; i++) {
        UIBarButtonItem *btn = [_barItems objectAtIndex:i];
        btn.width = buttonWidth;
    }
    [_toolbar setNeedsLayout];
}

- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation {
    int xp = _collectionView.frame.size.width * _currentIndex;
    [_collectionView scrollRectToVisible:CGRectMake(xp, 0, _collectionView.frame.size.width, _collectionView.frame.size.height) animated:animation];
    _isScrolling = animation;;
}

- (void)toggleThumbnailViewWithAnimation:(BOOL)animation {
    if (_isThumbViewShowing) {
        [self hideThumbnailViewWithAnimation:animation];
    }
    else {
        [self showThumbnailViewWithAnimation:animation];
    }
}

- (void)showThumbnailViewWithAnimation:(BOOL)animation {
    _isThumbViewShowing = YES;
    
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Close", @"")];
    
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"uncurl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_thumbsView cache:YES];
        [_thumbsView setHidden:NO];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:NO];
    }
}

- (void)hideThumbnailViewWithAnimation:(BOOL)animation {
    _isThumbViewShowing = NO;
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"See all", @"")];
    
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"curl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_thumbsView cache:YES];
        [_thumbsView setHidden:YES];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:YES];
    }
    
    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)closeClk:(id)sender {
    NSArray *keys = [_photoLoaders allKeys];
    NSUInteger i, count = [keys count];
    for (i = 0; i < count; i++) {
        IRGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
        [photo unloadThumbnail];
        [photo unloadFullsize];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteClk:(id)sender
{
    IRGalleryPhoto *file = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", _currentIndex]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm" message:@"Do you want to delete this photo?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self delete];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)delete {
    if([self.delegate respondsToSelector:@selector(photoGallery:deleteAtIndex:)])
        [self.delegate photoGallery:self deleteAtIndex:_currentIndex];

    _collectionView.delegate = nil;
    _photoSource = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addToMyFavoritesClk:(id)sender {
    if([self.delegate respondsToSelector:@selector(photoGallery:addFavorite:atIndex:)])
    {
        if(((UIButton*)[_favoriteButton customView]).selected){
            ((UIButton*)[_favoriteButton customView]).selected = NO;
            [self.delegate photoGallery:self addFavorite:NO atIndex:_currentIndex];
        }else{
            ((UIButton*)[_favoriteButton customView]).selected = YES;
            [self.delegate photoGallery:self addFavorite:YES atIndex:_currentIndex];
        }
    }
}

- (void)shareClk:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *file = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.navigationItem.title];
    [self shareByFileURLStringWithPath:file];
}

-(void)shareByFileURLStringWithPath:(NSString*)file{
    self.fileInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:file]];
    self.fileInteractionController.delegate = self;
    self.fileInteractionController.UTI = [Utility getUTI:[file pathExtension]];
    BOOL isValid = [self.fileInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    if (isValid == FALSE){
        [self.fileInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
        /*[self showWarnning:_(@"SHARE_ALERT")];*/
    }
}
/*
- (void)showWarnning:(NSString*)info{
    SuccessView *successView;;
    VIEW(successView, SuccessView);
    successView.infoLabel.text = NSLocalizedString(info, nil);
    [[KGModal sharedInstance] setShowCloseButton:FALSE];
    [[KGModal sharedInstance] showWithContentView:successView andAnimated:YES];
}
*/
#pragma mark - Image Loading
- (void)preloadThumbnailImages {
    NSInteger index = _currentIndex;
    NSInteger count = [self.photoSource numberOfPhotosForPhotoGallery:self];
    
    // make sure the images surrounding the current index have thumbs loading
    NSInteger nextIndex = index + 1;
    NSInteger prevIndex = index - 1;
    
    // the preload count indicates how many images surrounding the current photo will get preloaded.
    // a value of 2 at maximum would preload 4 images, 2 in front of and two behind the current image.
    NSInteger preloadCount = 1;
    
    IRGalleryPhoto *photo;
    
    // check to see if the current image thumb has been loaded
    photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", index]];
    
    if( !photo )
    {
        [self loadThumbnailImageWithIndex:index];
        photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", index]];
    }
    
    if( !photo.hasThumbLoaded && !photo.isThumbLoading )
    {
        [photo loadThumbnail];
    }
    
    NSInteger curIndex = prevIndex;
    NSInteger invalidIndex = -1;
    while( (curIndex > invalidIndex) && (curIndex > (prevIndex - preloadCount)) )
    {
        photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", curIndex]];
        
        if( !photo ) {
            [self loadThumbnailImageWithIndex:curIndex];
            photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", curIndex]];
        }
        
        if( !photo.hasThumbLoaded && !photo.isThumbLoading )
        {
            [photo loadThumbnail];
        }
        
        curIndex--;
    }
    
    curIndex = nextIndex;
    while( curIndex < count && curIndex < nextIndex + preloadCount )
    {
        photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", curIndex]];
        
        if( !photo ) {
            [self loadThumbnailImageWithIndex:curIndex];
            photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", curIndex]];
        }
        
        if( !photo.hasThumbLoaded && !photo.isThumbLoading )
        {
            [photo loadThumbnail];
        }
        
        curIndex++;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
}

- (void)loadThumbnailImageWithIndex:(NSUInteger)index {
    IRGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", index]];
    
    if( photo == nil )
        photo = [self createGalleryPhotoForIndex:index];
    
    [photo loadThumbnail];
}

- (void)loadFullsizeImageWithIndex:(NSUInteger)index {
    IRGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", index]];
    
    if( photo == nil )
        photo = [self createGalleryPhotoForIndex:index];
    
    [photo loadFullsize];
}

- (void)unloadFullsizeImageWithIndex:(NSUInteger)index {
//    if (index < [_photoViews count]) {
    if (index < [self.photoSource numberOfPhotosForPhotoGallery:self]) {
        IRGalleryPhoto *loader = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", index]];
        [loader unloadFullsize];
        
//        IRGalleryPhotoView *photoView = [_photoViews objectAtIndex:index];
        IRGalleryPhotoView *photoView = nil;
        for(NSIndexPath *indexPath in [_collectionView indexPathsForVisibleItems]){
            if(indexPath.row == index){
                photoView = ((MyCollectionViewCell*)[_collectionView cellForItemAtIndexPath:indexPath]).imageView;
                break;
            }
        }
        
        if(!photoView)
            return;
        
        photoView.imageView.image = loader.thumbnail;
    }
}

- (IRGalleryPhoto *)createGalleryPhotoForIndex:(NSUInteger)index {
    IRGalleryPhotoSourceType sourceType = [_photoSource photoGallery:self sourceTypeForPhotoAtIndex:index];
    IRGalleryPhoto *photo;
    NSString *thumbPath;
    NSString *fullsizePath;
    
    if( sourceType == IRGalleryPhotoSourceTypeLocal )
    {
        thumbPath = [_photoSource photoGallery:self filePathForPhotoSize:IRGalleryPhotoSizeThumbnail atIndex:index];
        fullsizePath = [_photoSource photoGallery:self filePathForPhotoSize:IRGalleryPhotoSizeFullsize atIndex:index];
        photo = [[IRGalleryPhoto alloc] initWithThumbnailPath:thumbPath fullsizePath:fullsizePath delegate:self];
    }
    else if( sourceType == IRGalleryPhotoSourceTypeNetwork )
    {
        thumbPath = [_photoSource photoGallery:self urlForPhotoSize:IRGalleryPhotoSizeThumbnail atIndex:index];
        fullsizePath = [_photoSource photoGallery:self urlForPhotoSize:IRGalleryPhotoSizeFullsize atIndex:index];
        photo = [[IRGalleryPhoto alloc] initWithThumbnailUrl:thumbPath fullsizeUrl:fullsizePath delegate:self];
    }
    else
    {
        // invalid source type, throw an error.
        [NSException raise:@"Invalid photo source type" format:@"The specified source type of %d is invalid", sourceType];
    }
    
    // assign the photo index
    photo.tag = index;
    
    // store it
    [_photoLoaders setObject:photo forKey: [NSString stringWithFormat:@"%ld", index]];
    
    return photo;
}

- (void)scrollingHasEnded {
    NSLog(@"scrollingHasEnded start");
    _isScrolling = NO;
    
//    NSUInteger newIndex = floor( _scroller.contentOffset.x / _scroller.frame.size.width );
    NSUInteger newIndex = floor( _collectionView.contentOffset.x / _collectionView.frame.size.width );
    
    // don't proceed if the user has been scrolling, but didn't really go anywhere.
    if( newIndex == _currentIndex )
        return;
    
    // clear previous
    [self unloadFullsizeImageWithIndex:_currentIndex];
    
    _currentIndex = newIndex;
    [self updateCaption];
    [self updateTitle];
    [self updateButtons];
    [self loadFullsizeImageWithIndex:_currentIndex];
    [self preloadThumbnailImages];
    
    NSLog(@"scrollingHasEnded finish");
}

//////////////////////
////// Collection
//////////////////////
static NSString* myFavoritesCellIdentifier = @"MyCollectionCell";

- (void)initMyFavorites {
//    [_collectionView registerNib:[UINib nibWithNibName:@"MyFavoritesCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:myFavoritesCellIdentifier];
    [_collectionView registerClass:MyCollectionViewCell.class forCellWithReuseIdentifier:myFavoritesCellIdentifier];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.showsHorizontalScrollIndicator = NO;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).minimumInteritemSpacing = CGFLOAT_MAX;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).scrollDirection = UICollectionViewScrollDirectionHorizontal;
    ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).minimumLineSpacing = 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.photoSource numberOfPhotosForPhotoGallery:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:myFavoritesCellIdentifier forIndexPath:indexPath];
    cell.imageView.zoomScale = 1;
//    cell.hidden = NO;
    
    cell.imageView.photoDelegate = self;
    [cell.imageView.activity startAnimating];
    // only set the fullsize image if we're currently on that image
    if( _currentIndex == indexPath.row )
    {
        IRGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", indexPath.row]];
        cell.imageView.imageView.image = photo.fullsize;
        if(_currentIndex == _preDisplayView.tag && !photo.thumbnail)
            cell.imageView.thumbView.image = _preDisplayView.image;
        else
            cell.imageView.thumbView.image = photo.thumbnail;
    }
    // otherwise, we don't need to keep this image around
    else
    {
        IRGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", indexPath.row]];
        [photo unloadFullsize];
        
        cell.imageView.imageView.image = photo.fullsize;
        cell.imageView.thumbView.image = photo.thumbnail;
    }
    
    if(cell.imageView.imageView.image || cell.imageView.thumbView.image){
        [cell.imageView.activity stopAnimating];
    }
    
    return cell;
}

//////////////////////
//////
//////////////////////


#pragma mark - IRGalleryPhoto Delegate Methods

- (UIImage *)galleryPhotoLoadThumbnailFromLocal:(IRGalleryPhoto *)photo {
    if([_photoSource respondsToSelector:@selector(photoGallery:loadThumbnailFromLocalAtIndex:)])
        return [_photoSource photoGallery:self loadThumbnailFromLocalAtIndex:photo.tag];
    return nil;
}

- (void)galleryPhoto:(IRGalleryPhoto *)photo willLoadThumbnailFromPath:(NSString *)path {

}

- (void)galleryPhoto:(IRGalleryPhoto *)photo willLoadThumbnailFromUrl:(NSString *)url {

}

- (void)galleryPhoto:(IRGalleryPhoto *)photo didLoadThumbnail:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
}

- (void)galleryPhoto:(IRGalleryPhoto *)photo didLoadFullsize:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
}

- (void)galleryPhoto:(IRGalleryPhoto *)photo loadingThumbnail:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
}

- (void)galleryPhoto:(IRGalleryPhoto *)photo loadingFullsize:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
}

#pragma mark - UIScrollView Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _isScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if( !decelerate ) {
        [self scrollingHasEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollingHasEnded];
}

#pragma mark - Memory Management Methods
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    
    NSLog(@"[OfflineIRGalleryViewController] didReceiveMemoryWarning! clearing out cached images...");
    // unload fullsize and thumbnail images for all our images except at the current index.
    NSArray *keys = [_photoLoaders allKeys];
    NSUInteger i, count = [keys count];
    if (_isThumbViewShowing==YES) {

    } else {
        for (i = 0; i < count; i++)
        {
            IRGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%ld", i]];
            if( i != _currentIndex )
            {
                if(photo){
                    NSLog(@"Disable Progressive and unload");
                    photo.enableProgressive = NO;
                    [photo unloadFullsize];
                    [photo unloadThumbnail];
                }
            }else{
                NSLog(@"Disable Progressive");
                photo.enableProgressive = NO;
            }
        }
    }
}

- (void)dealloc {
    // Cancel all photo loaders in progress
    NSArray *keys = [_photoLoaders allKeys];
    NSUInteger i, count = [keys count];
    for (i = 0; i < count; i++) {
        IRGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
        photo.delegate = nil;
        [photo unloadThumbnail];
        [photo unloadFullsize];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//        [self->_collectionView.collectionViewLayout invalidateLayout];
        [self layoutViews];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//        IRGalleryViewController *galleryController = (IRGalleryViewController*)self.visibleViewController;
//            [galleryController resetImageViewZoomLevels];
        
//        [self updateItemSize];
//        [self->_collectionView.collectionViewLayout invalidateLayout];
    }];
}

#pragma mark - UIDocumentInteractionController
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)controller {
    return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)controller {
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)controller {
    return self.view.frame;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    
}

- (void)documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *)controller {
    
}

@end
