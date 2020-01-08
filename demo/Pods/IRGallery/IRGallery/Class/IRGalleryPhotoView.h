//
//  IRGalleryPhotoView.h
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IRGalleryPhotoViewDelegate;

//@interface IRGalleryPhotoView : UIImageView {
@interface IRGalleryPhotoView : UIScrollView <UIScrollViewDelegate> {
    UIView *mainView;
    BOOL _isZoomed;
    NSTimer *_tapTimer;
}

- (void)killActivityIndicator;

// inits this view to have a button over the image
- (id)initWithFrame:(CGRect)frame target:(id)target action:(SEL)action;

@property (nonatomic,assign)  id<IRGalleryPhotoViewDelegate> photoDelegate;
@property (nonatomic,readonly) UIImageView *imageView;
@property (nonatomic,readonly) UIButton *button;
@property (nonatomic,readonly) UIActivityIndicatorView *activity;
@property (nonatomic,readonly) UIImageView *thumbView;
@end

@protocol IRGalleryPhotoViewDelegate<NSObject>

// indicates single touch and allows controller repsond and go toggle fullscreen
- (void)didTapPhotoView:(IRGalleryPhotoView*)photoView;

@end

NS_ASSUME_NONNULL_END
