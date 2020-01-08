//
//  IRGalleryPhotoView.m
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGalleryPhotoView.h"

@interface IRGalleryPhotoView (Private)

- (void)killActivityIndicator;
- (void)startTapTimer;
- (void)stopTapTimer;

@end

@implementation IRGalleryPhotoView {
    NSLayoutConstraint *widthConstraint, *heightConstraint, *thumbwidthConstraint, *thumbheightConstraint;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;
    self.delegate = self;
    self.contentMode = UIViewContentModeCenter;
    self.maximumZoomScale = 3.0;
    self.minimumZoomScale = 1.0;
    self.decelerationRate = .85;
    self.contentSize = CGSizeMake(frame.size.width, frame.size.height);
    
    // create the image view
    mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    mainView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:mainView];
    _thumbView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    _thumbView.contentMode = UIViewContentModeScaleAspectFit;
    [mainView addSubview:_thumbView];
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [mainView addSubview:_imageView];
    
    // create an activity inidicator
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [_activity setCenter:CGPointMake(frame.size.width * .5, frame.size.height * .5)];
    [self addSubview:_activity];
    
    [self setupConstraintWithView:mainView];
    [self setupConstraintWithView:_thumbView];
    [self setupConstraintWithView:_imageView];
//    [self setupConstraintWithView:_activity];
    
    widthConstraint = [NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:frame.size.width];
    heightConstraint = [NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:frame.size.height];
    widthConstraint.active = YES;
    heightConstraint.active = YES;

    thumbwidthConstraint = [NSLayoutConstraint constraintWithItem:_thumbView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:frame.size.width];
    thumbheightConstraint = [NSLayoutConstraint constraintWithItem:_thumbView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:frame.size.height];
    thumbwidthConstraint.active = YES;
    thumbheightConstraint.active = YES;
    
    return self;
}

- (void)setupConstraintWithView:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = false;
    
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    NSLayoutConstraint * bottomConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    bottomConstraint.active = YES;
    topConstraint.active = YES;
    leadingConstraint.active = YES;
    trailingConstraint.active = YES;
}

- (id)initWithFrame:(CGRect)frame target:(id)target action:(SEL)action {
    self = [self initWithFrame:frame];
    
    // fit them images!
    _thumbView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    mainView.contentMode = UIViewContentModeScaleAspectFill;
    
    // disable zooming
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 1.0;
    
    // allow buttons to be clicked
    [self setUserInteractionEnabled:YES];
    
    // but don't allow zooming/panning
    self.scrollEnabled = NO;
    
    // create button
    _button = [[UIButton alloc] initWithFrame:CGRectZero];
    [_button setBackgroundColor:[UIColor clearColor]];
    [_button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_button];
    
    // create outline
    [self.layer setBorderWidth:1.0];
    [self.layer setBorderColor:[[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:.25] CGColor]];
    
    return self;
}

- (void)setFrame:(CGRect)theFrame {
    // store position of the view if we're scaled or panned so we can stay at that point
    [super setFrame:theFrame];
    
    thumbwidthConstraint.constant = widthConstraint.constant = theFrame.size.width;
    thumbheightConstraint.constant = heightConstraint.constant = theFrame.size.height;
    [_thumbView setNeedsUpdateConstraints];
    [self setNeedsUpdateConstraints];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    
    if (touch.tapCount == 2) {
        [self stopTapTimer];
        
        if( _isZoomed )
        {
            _isZoomed = NO;
            [self setZoomScale:self.minimumZoomScale animated:YES];
        }
        else {
            
            _isZoomed = YES;
            
            // define a rect to zoom to.
            CGPoint touchCenter = [touch locationInView:self];
            CGSize zoomRectSize = CGSizeMake(self.frame.size.width / self.maximumZoomScale, self.frame.size.height / self.maximumZoomScale );
            CGRect zoomRect = CGRectMake( touchCenter.x - zoomRectSize.width * .5, touchCenter.y - zoomRectSize.height * .5, zoomRectSize.width, zoomRectSize.height );
            
            // correct too far left
            if( zoomRect.origin.x < 0 )
                zoomRect = CGRectMake(0, zoomRect.origin.y, zoomRect.size.width, zoomRect.size.height );
            
            // correct too far up
            if( zoomRect.origin.y < 0 )
                zoomRect = CGRectMake(zoomRect.origin.x, 0, zoomRect.size.width, zoomRect.size.height );
            
            // correct too far right
            if( zoomRect.origin.x + zoomRect.size.width > self.frame.size.width )
                zoomRect = CGRectMake(self.frame.size.width - zoomRect.size.width, zoomRect.origin.y, zoomRect.size.width, zoomRect.size.height );
            
            // correct too far down
            if( zoomRect.origin.y + zoomRect.size.height > self.frame.size.height )
                zoomRect = CGRectMake( zoomRect.origin.x, self.frame.size.height - zoomRect.size.height, zoomRect.size.width, zoomRect.size.height );
            
            // zoom to it.
            [self zoomToRect:zoomRect animated:YES];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if([[event allTouches] count] == 1 ) {
        UITouch *touch = [[event allTouches] anyObject];
        if( touch.tapCount == 1 ) {
            
            if(_tapTimer ) [self stopTapTimer];
            [self startTapTimer];
        }
    }
}

- (void)startTapTimer {
    _tapTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:.5] interval:.5 target:self selector:@selector(handleTap) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_tapTimer forMode:NSDefaultRunLoopMode];
    
}

- (void)stopTapTimer {
    if([_tapTimer isValid])
        [_tapTimer invalidate];
    
    _tapTimer = nil;
}

- (void)handleTap {
    // tell the controller
    if([_photoDelegate respondsToSelector:@selector(didTapPhotoView:)])
        [_photoDelegate didTapPhotoView:self];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return mainView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if( self.zoomScale == self.minimumZoomScale ) _isZoomed = NO;
    else _isZoomed = YES;
}

- (void)killActivityIndicator {
    [_activity stopAnimating];
    [_activity removeFromSuperview];
    _activity = nil;
}

- (void)dealloc {
    [self stopTapTimer];
    [self killActivityIndicator];
}

@end

