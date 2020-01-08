//
//  IRGalleryPhoto.m
//  IRGallery
//
//  Created by Phil on 2019/11/20.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGalleryPhoto.h"
#import <ImageIO/ImageIO.h>
#import <CommonCrypto/CommonDigest.h>

#define IRDefaultCacheTimeValue 604800.0f // 7 days
#define IRDefaultTimeoutValue 60.0f


@interface IRGalleryPhoto (Private)<NSURLConnectionDelegate>

// delegate notifying methods
- (void)willLoadThumbFromUrl;
- (void)willLoadFullsizeFromUrl;
- (void)willLoadThumbFromPath;
- (void)willLoadFullsizeFromPath;
- (void)didLoadThumbnail;
- (void)didLoadFullsize;

// loading local images with threading
- (void)loadFullsizeInThread;
- (void)loadThumbnailInThread;

// cleanup
- (void)killThumbnailLoadObjects;
- (void)killFullsizeLoadObjects;

@end

@implementation IRGalleryPhoto {
    CGImageSourceRef _imageSource;
    // Width of the downloaded image
    int _imageWidth;
    // Height of the downloaded image
    int _imageHeight;
    // Expected image size
    long long _expectedSize;
    // Connection queue
    dispatch_queue_t _queue;
}

- (id)initWithThumbnailUrl:(NSString *)thumb fullsizeUrl:(NSString *)fullsize delegate:(NSObject<IRGalleryPhotoDelegate> *)delegate {
    self = [self init];
    _useNetwork = YES;
    _thumbUrl = thumb;
    _fullsizeUrl = fullsize;
    _delegate = delegate;
    return self;
}

- (id)initWithThumbnailPath:(NSString *)thumb fullsizePath:(NSString *)fullsize delegate:(NSObject<IRGalleryPhotoDelegate> *)delegate {
    self = [self init];
    
    _useNetwork = NO;
    _thumbUrl = thumb;
    _fullsizeUrl = fullsize;
    _delegate = delegate;
    return self;
}

- (id)init {
    if (self = [super init])
    {
        [self initializeAttributes];
    }
    return self;
}

- (void)loadThumbnail {
    if( _isThumbLoading || _hasThumbLoaded ) return;
    
    // load from network
    if( _useNetwork ) {
        // notify delegate
        [self willLoadThumbFromUrl];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if([self->_delegate respondsToSelector:@selector(galleryPhotoLoadThumbnailFromLocal:)])
                self->_thumbnail = [self->_delegate galleryPhotoLoadThumbnailFromLocal:self];
            
            if(!self->_thumbnail)
                [self loadImageAtURL:[NSURL URLWithString:self->_thumbUrl] isThumbSize:YES];
            else
                [self didLoadThumbnail];
        });

    } else { // load from disk
        // notify delegate
        [self willLoadThumbFromPath];
        
        _isThumbLoading = YES;
        
        // spawn a new thread to load from disk
        [NSThread detachNewThreadSelector:@selector(loadThumbnailInThread) toTarget:self withObject:nil];
    }
}

- (void)loadFullsize {
    if( _isFullsizeLoading || _hasFullsizeLoaded ) return;
    
    if( _useNetwork ) {
        // notify delegate
        [self willLoadFullsizeFromUrl];
        
        self.enableProgressive = YES;
        
        [self loadImageAtURL:[NSURL URLWithString:_fullsizeUrl] isThumbSize:NO];
    } else {
        [self willLoadFullsizeFromPath];
        
        _isFullsizeLoading = YES;
        
        // spawn a new thread to load from disk
        [NSThread detachNewThreadSelector:@selector(loadFullsizeInThread) toTarget:self withObject:nil];
    }
}

- (void)loadFullsizeInThread {
    _fullsize = [UIImage imageWithContentsOfFile:_fullsizeUrl];
    
    _hasFullsizeLoaded = YES;
    _isFullsizeLoading = NO;

    [self performSelectorOnMainThread:@selector(didLoadFullsize) withObject:nil waitUntilDone:YES];
}

- (void)loadThumbnailInThread {
    _thumbnail = [UIImage imageWithContentsOfFile:_thumbUrl];
    
    _hasThumbLoaded = YES;
    _isThumbLoading = NO;
    
    [self performSelectorOnMainThread:@selector(didLoadThumbnail) withObject:nil waitUntilDone:YES];
}

- (void)unloadFullsize {
    @synchronized (self) {
        NSLog(@"unloadFullsize");
        [_fullsizeConnection cancel];
        NSLog(@"cancel");
        [self killFullsizeLoadObjects];
        
        _isFullsizeLoading = NO;
        _hasFullsizeLoaded = NO;
        
        _fullsize = nil;
    }
}

- (void)unloadThumbnail {
    @synchronized (self) {
        [_thumbConnection cancel];
        [self killThumbnailLoadObjects];
        
        _isThumbLoading = NO;
        _hasThumbLoaded = NO;
        
        _thumbnail = nil;
    }
}

#pragma mark - Public
- (void)loadImageAtURL:(NSURL *)url isThumbSize:(BOOL)isThumbSize {
    if (isThumbSize ? _isThumbLoading : _isFullsizeLoading)
        return;
    
    if (_caching) {
        NSFileManager* fileManager = [[NSFileManager alloc] init];
        
        // check if file exists on cache
        NSString* cacheDir = [IRGalleryPhoto cacheDirectoryAddress];
        NSString* cachedImagePath = [cacheDir stringByAppendingPathComponent:[self cachedImageSystemNameByUrl:url]];
        if ([fileManager fileExistsAtPath:cachedImagePath]) {
            NSDate* mofificationDate = [[fileManager attributesOfItemAtPath:cachedImagePath error:nil] objectForKey:NSFileModificationDate];
            
            // check modification date
            if (-[mofificationDate timeIntervalSinceNow] > _cacheTime) {
                // Removes old cache file...
                [self resetCacheByUrl:url];
            } else {
                // Loads image from cache without networking
                UIImage* localImage = [[UIImage alloc] initWithContentsOfFile:cachedImagePath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(isThumbSize){
                        NSLog(@"Thumb load from cache");
                        self->_thumbnail = localImage;
                        [self didLoadThumbnail];
                    }else{
                        NSLog(@"Full load from cache");
                        self->_fullsize = localImage;
                        [self didLoadFullsize];
                    }
                });
                
                return;
            }
        }
    }
    
    dispatch_async(_queue, ^{
        NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:IRDefaultTimeoutValue];
        if(isThumbSize){
            self->_isThumbLoading = YES;
            self->_thumbConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
            [self->_thumbConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            self->_thumbData = [[NSMutableData alloc] init];
            [self->_thumbConnection start];
        }else{
            self->_isFullsizeLoading = YES;
            self->_fullsizeConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
            [self->_fullsizeConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            self->_fullsizeData = [[NSMutableData alloc] init];
            [self->_fullsizeConnection start];
        }
        
        CFRunLoopRun();
    });
}

+ (NSUInteger)getCacheSize {
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[IRGalleryPhoto cacheDirectoryAddress]];
    
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [[IRGalleryPhoto cacheDirectoryAddress] stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

+ (void)resetImageCache {
    [[NSFileManager defaultManager] removeItemAtPath:[IRGalleryPhoto cacheDirectoryAddress] error:nil];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(__unused NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    @synchronized (self) {
        if( connection == _fullsizeConnection ){
            _imageSource = CGImageSourceCreateIncremental(NULL);
            _imageWidth = _imageHeight = -1;
            _expectedSize = [response expectedContentLength];
        }
    }
}

-(void)connection:(__unused NSURLConnection*)connection didReceiveData:(NSData*)data {
    @synchronized (self) {

    NSLog(@"didReceiveData");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    
    if( connection == _thumbConnection ){
        [_thumbData appendData:data];
    }else if( connection == _fullsizeConnection ){
        [_fullsizeData appendData:data];
    }
    
    if(!self.enableProgressive || connection == _thumbConnection)
        return;
    
//    if( connection == _thumbConnection ){
//        const long long len = (long long)[_thumbData length];
//        CGImageSourceUpdateData(_thumbImageSource, (__bridge CFDataRef)_thumbData, (len == _expectedSize) ? true : false);
//    }else if( connection == _fullsizeConnection ){
        const long long len = (long long)[_fullsizeData length];
        CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)_fullsizeData, (len == _expectedSize) ? true : false);
//    }
    
    if (_imageHeight > 0 && _imageWidth > 0)
    {
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        if (cgImage)
        {
            const size_t partialHeight = CGImageGetHeight(cgImage);
            CGImageAlphaInfo alpha = CGImageGetAlphaInfo(cgImage);
            BOOL hasAlpha = (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
            CGImageAlphaInfo alphaInfo = (hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst);
            CGContextRef bmContext = CGBitmapContextCreate(NULL, (size_t)_imageWidth, (size_t)_imageHeight, 8/*Bits per component*/, (size_t)_imageWidth * 4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault | alphaInfo);
            CGImageRef imgTmp = NULL;
            if (bmContext){
                CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = _imageWidth, .size.height = partialHeight}, cgImage);
                imgTmp = CGBitmapContextCreateImage(bmContext);
                CGContextRelease(bmContext);
                bmContext = NULL;
            }
            
            if (imgTmp)
            {
                __block UIImage* img = [[UIImage alloc] initWithCGImage:imgTmp scale:1.0f orientation:_imageOrientation];
                CGImageRelease(imgTmp);
                imgTmp = NULL;
                
                if( connection == _thumbConnection ){
                    _thumbnail = img;
                    
                    img = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self loadingThumbnail];
                    });
                }else if( connection == _fullsizeConnection ){
                    _fullsize = img;
                    
                    img = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self loadingFullsize];
                    });
                }
                
            }

            CGImageRelease(cgImage);
            cgImage = NULL;
        }
    }
    else
    {
        CFDictionaryRef dic = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (dic)
        {
            CFTypeRef val = CFDictionaryGetValue(dic, kCGImagePropertyPixelHeight);
            if (val)
                CFNumberGetValue(val, kCFNumberIntType, &_imageHeight);
            val = CFDictionaryGetValue(dic, kCGImagePropertyPixelWidth);
            if (val)
                CFNumberGetValue(val, kCFNumberIntType, &_imageWidth);
            
            val = CFDictionaryGetValue(dic, kCGImagePropertyOrientation);
            if (val)
            {
                int orientation; // Note: This is an EXIF int for orientation, a number between 1 and 8
                CFNumberGetValue(val, kCFNumberIntType, &orientation);
                _imageOrientation = [IRGalleryPhoto exifOrientationToiOSOrientation:orientation];
                NSLog(@"UIImageOrientation:%ld", (long)_imageOrientation);
            }
            else{
                _imageOrientation = UIImageOrientationUp;
                NSLog(@"UIImageOrientationUp");
            }
            CFRelease(dic);
        }
    }
        
    }
}

-(void)connectionDidFinishLoading:(__unused NSURLConnection*)connection
{
    NSLog(@"load Finish");
    
    NSMutableData *_dataTemp = nil;
    if( connection == _thumbConnection ){
        _dataTemp = _thumbData;
    }else if( connection == _fullsizeConnection ){
        _dataTemp = _fullsizeData;
    }
    
    if (_dataTemp)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            UIImage* img = [[UIImage alloc] initWithData:_dataTemp];
            
            if (_caching)
            {
                // Create cache directory if it doesn't exist
                BOOL isDir = YES;
                
                NSFileManager* fileManager = [[NSFileManager alloc] init];
                
                NSString* cacheDir = [IRGalleryPhoto cacheDirectoryAddress];
                if (![fileManager fileExistsAtPath:cacheDir isDirectory:&isDir])
                    [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:nil];
                
                NSURL *url = nil;
                if( connection == _thumbConnection ){
                    url = [NSURL URLWithString:_thumbUrl];
                }else if( connection == _fullsizeConnection ){
                    url = [NSURL URLWithString:_fullsizeUrl];
                }
                
                NSString* path = [cacheDir stringByAppendingPathComponent:[self cachedImageSystemNameByUrl:url]];
                [_dataTemp writeToFile:path options:NSDataWritingAtomic error:nil];
            }
            
            if( connection == _thumbConnection ){
                _thumbnail = img;
                _isThumbLoading = NO;
                _hasThumbLoaded = YES;
                
                // cleanup
                [self killThumbnailLoadObjects];
                
                if( _delegate )
                    [self didLoadThumbnail];
                
            }else if( connection == _fullsizeConnection ){
                _fullsize = img;
                _isFullsizeLoading = NO;
                _hasFullsizeLoaded = YES;
                
                // cleanup
                [self killFullsizeLoadObjects];
                
                if( _delegate )
                    [self didLoadFullsize];
            }
        });
        
        _dataTemp = nil;
    }
    
    if( connection == _thumbConnection ){
        _isThumbLoading = NO;
        
        // cleanup
        [self killThumbnailLoadObjects];
        
    }else if( connection == _fullsizeConnection ){
        _isFullsizeLoading = NO;
        
        // cleanup
        [self killFullsizeLoadObjects];
    }
    
    // turn off data indicator
    if( !_isFullsizeLoading && !_isThumbLoading )
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
        
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"load fail");
    
    if( connection == _thumbConnection ){
        _isThumbLoading = NO;
        
        // cleanup
        [self killThumbnailLoadObjects];
    }else if( connection == _fullsizeConnection ){
        _isFullsizeLoading = NO;
        
        // cleanup
        [self killFullsizeLoadObjects];
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());

    // turn off data indicator
    if( !_isFullsizeLoading && !_isThumbLoading )
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
}

#pragma mark - Private
- (void)initializeAttributes {
    _cacheTime = IRDefaultCacheTimeValue;
    _caching = YES;
    _imageOrientation = UIImageOrientationUp;
    _imageSource = NULL;
    
    if(!_queue){
        _queue = dispatch_queue_create("com.irons.IRGalleryPhoto", DISPATCH_QUEUE_SERIAL);
    }
}

+ (NSString *)cacheDirectoryAddress {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectoryPath = [paths objectAtIndex:0];
    return [documentsDirectoryPath stringByAppendingPathComponent:@"NYXProgressiveImageViewCache"];
}

- (NSString *)cachedImageSystemNameByUrl:(NSURL *)_url {
    const char* concat_str = [[_url absoluteString] UTF8String];
    if (!concat_str)
        return @"";
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, (CC_LONG)strlen(concat_str), result);
    
    NSMutableString* hash = [[NSMutableString alloc] init];
    for (unsigned int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hash appendFormat:@"%02X", result[i]];
    
    return [hash lowercaseString];
}

- (void)resetCacheByUrl:(NSURL *)_url {
    [[[NSFileManager alloc] init] removeItemAtPath:[[IRGalleryPhoto cacheDirectoryAddress] stringByAppendingPathComponent:[self cachedImageSystemNameByUrl:_url]] error:nil];
}

+ (UIImageOrientation)exifOrientationToiOSOrientation:(int)exifOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (exifOrientation)
    {
        case 1:
            orientation = UIImageOrientationUp;
            break;
        case 3:
            orientation = UIImageOrientationDown;
            break;
        case 8:
            orientation = UIImageOrientationLeft;
            break;
        case 6:
            orientation = UIImageOrientationRight;
            break;
        case 2:
            orientation = UIImageOrientationUpMirrored;
            break;
        case 4:
            orientation = UIImageOrientationDownMirrored;
            break;
        case 5:
            orientation = UIImageOrientationLeftMirrored;
            break;
        case 7:
            orientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return orientation;
}

#pragma mark Delegate Notification Methods
- (void)willLoadThumbFromUrl {
    if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadThumbnailFromUrl:)])
        [_delegate galleryPhoto:self willLoadThumbnailFromUrl:_thumbUrl];
}

- (void)willLoadFullsizeFromUrl {
    if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadFullsizeFromUrl:)])
        [_delegate galleryPhoto:self willLoadFullsizeFromUrl:_fullsizeUrl];
}

- (void)willLoadThumbFromPath {
    if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadThumbnailFromPath:)])
        [_delegate galleryPhoto:self willLoadThumbnailFromPath:_thumbUrl];
}

- (void)willLoadFullsizeFromPath {
    if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadFullsizeFromPath:)])
        [_delegate galleryPhoto:self willLoadFullsizeFromPath:_fullsizeUrl];
}

- (void)didLoadThumbnail {
    if([_delegate respondsToSelector:@selector(galleryPhoto:didLoadThumbnail:)])
        [_delegate galleryPhoto:self didLoadThumbnail:_thumbnail];
}

- (void)didLoadFullsize {
    if([_delegate respondsToSelector:@selector(galleryPhoto:didLoadFullsize:)])
        [_delegate galleryPhoto:self didLoadFullsize:_fullsize];
}

- (void)loadingThumbnail {
    if([_delegate respondsToSelector:@selector(galleryPhoto:loadingThumbnail:)])
        [_delegate galleryPhoto:self loadingThumbnail:_thumbnail];
}

- (void)loadingFullsize {
    if([_delegate respondsToSelector:@selector(galleryPhoto:loadingFullsize:)])
        [_delegate galleryPhoto:self loadingFullsize:_fullsize];
}

- (void)showThumbnail:(BOOL)show {
    if([_delegate respondsToSelector:@selector(galleryPhoto:showThumbnail:)])
        [_delegate galleryPhoto:self showThumbnail:show];
}

#pragma mark Memory Management
- (void)releaseFullsizeImageSource {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}

- (void)killThumbnailLoadObjects {
    _thumbConnection = nil;
    _thumbData = nil;
}

- (void)killFullsizeLoadObjects {
    _fullsizeConnection = nil;
    _fullsizeData = nil;
    [self releaseFullsizeImageSource];
}

- (void)dealloc {
    [_fullsizeConnection cancel];
    [_thumbConnection cancel];
    [self killFullsizeLoadObjects];
    [self killThumbnailLoadObjects];
}

@end

