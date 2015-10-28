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


#import "VLCNetworkImageView.h"

@implementation VLCNetworkImageView

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

- (UIImage *)cacheImageForURL:(NSURL *)url {

    UIImage *image = [[self.class sharedImageCache] objectForKey:url];
    if ((image != nil) && [image isKindOfClass:[UIImage class]]) {
        return image;
    }
    return nil;
}

- (void)cancelLoading {
    [self.downloadTask cancel];
    self.downloadTask = nil;
}

- (void)setImageWithURL:(NSURL *)url {

    [self cancelLoading];
    UIImage *cachedImage = [self cacheImageForURL:url];
    if (cachedImage) {
        self.image = cachedImage;
    } else {
        __weak typeof(self) weakSelf = self;
        NSURLSession *sharedSession = [NSURLSession sharedSession];
        self.downloadTask = [sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!data) {
                return;
            }
            UIImage *image = [UIImage imageWithData:data];
            if (!image) { return; }
            [[[weakSelf class] sharedImageCache] setObject:image forKey:url];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if ([strongSelf.downloadTask.originalRequest.URL isEqual:url]) {
                    strongSelf.image = image;
                    strongSelf.downloadTask = nil;
                }
            }];
        }];
    }
}
@end
