#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "IRGalleryPhoto.h"
#import "IRGalleryPhotoView.h"
#import "IRGalleryViewController.h"
#import "UIImage+Bundle.h"
#import "Utility.h"
#import "IRGallery.h"

FOUNDATION_EXPORT double IRGalleryVersionNumber;
FOUNDATION_EXPORT const unsigned char IRGalleryVersionString[];

