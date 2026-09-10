/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#if TARGET_OS_TV
#import "VLC-Swift.h"
#endif

#import "VLCNetworkImageView.h"
#import "VLCThumbnailsCache.h"

@implementation VLCNetworkImageView
{
    NSURL *_localImageURL;
}

static NSCache *sharedImageCache = nil;

+ (void)setSharedImageCache:(NSCache *)sharedCache {
    sharedImageCache = sharedCache;
}

+ (NSCache *)sharedImageCache {
    if (!sharedImageCache) {
        sharedImageCache = [[NSCache alloc] init];
        [sharedImageCache setCountLimit:50];
    }
    return sharedImageCache;
}

+ (UIImage *)cachedImageForURL:(NSURL *)url {
    if (url == nil) {
        return nil;
    }

    return [[self sharedImageCache] objectForKey:url];
}

- (void)cancelLoading {
    [self.downloadTask cancel];
    self.downloadTask = nil;
    _localImageURL = nil;
}

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url maxPixelSize:0.];
}

- (void)setImageWithURL:(NSURL *)url maxPixelSize:(CGFloat)maxPixelSize {
    if (url == nil) {
        return;
    }

    [self cancelLoading];
    if (url.isFileURL) {
        [self loadLocalImageWithURL:url maxPixelSize:maxPixelSize];
        return;
    }

    id cacheKey = maxPixelSize > 0. ? [NSString stringWithFormat:@"%@|%.0f", url.absoluteString, maxPixelSize] : url;
    UIImage *cachedImage = [[self.class sharedImageCache] objectForKey:cacheKey];
    if (cachedImage) {
        self.image = cachedImage;
    } else {
        [self downloadImageWithURL:url maxPixelSize:maxPixelSize cacheKey:cacheKey];
    }
}

- (void)loadLocalImageWithURL:(NSURL *)url maxPixelSize:(CGFloat)maxPixelSize {
    _localImageURL = url;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImage *image = maxPixelSize > 0. ? [VLCThumbnailsCache thumbnailForURL:url maxPixelSize:maxPixelSize]
                                           : [VLCThumbnailsCache thumbnailForURL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image && [self->_localImageURL isEqual:url]) {
                self.image = image;
                self->_localImageURL = nil;
            }
        });
    });
}

- (void)downloadImageWithURL:(NSURL *)url maxPixelSize:(CGFloat)maxPixelSize cacheKey:(id)cacheKey {
    __weak typeof(self) weakSelf = self;
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    self.downloadTask = [sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) {
            return;
        }
        UIImage *image = maxPixelSize > 0. ? [VLCThumbnailsCache downsampledImageFromData:data maxPixelSize:maxPixelSize]
                                           : [VLCThumbnailsCache downsampledImageFromData:data];
        if (!image) { return; }
        [[[weakSelf class] sharedImageCache] setObject:image forKey:cacheKey];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([strongSelf.downloadTask.originalRequest.URL isEqual:url]) {
                if (strongSelf.animateImageSetting) {
                    [UIView animateWithDuration:.3 animations:^{
                        strongSelf.image = image;
                    }];
                } else {
                    strongSelf.image = image;
                }
                strongSelf.downloadTask = nil;
            }
        }];
    }];
    [self.downloadTask resume];
}

#if TARGET_OS_TV
-(void)requestCachedThumbnail:(VLCMLMedia *)media
{
    UIImage *cachedImage = [media thumbnailImage];
    if (cachedImage) {
        self.image = cachedImage;
    } else {
        _mediaLibraryService = [[VLCAppCoordinator sharedInstance] mediaLibraryService];
        [_mediaLibraryService requestThumbnailFor:media];
        if (media.type == VLCMLMediaTypeVideo) {
            [self setImage:[UIImage imageNamed:@"movie"]];
        } else {
            [self setImage:[UIImage imageNamed:@"audio"]];
        }
    }
}
#endif

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    [self setNeedsUpdateConstraints];
    [self invalidateIntrinsicContentSize];
}

- (void)updateConstraints {
    [super updateConstraints];
    CGSize size = self.image.size;
    if (self.aspectRatioConstraint && size.height && size.width) {
        NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:size.width / size.height
                                                                          constant:0];
        [self removeConstraint:self.aspectRatioConstraint];
        [self addConstraint:newConstraint];
        self.aspectRatioConstraint = newConstraint;
    }
}

@end

