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


#import <UIKit/UIKit.h>

@interface VLCNetworkImageView : UIImageView
+ (NSCache *)sharedImageCache;
+ (void)setSharedImageCache:(NSCache *)sharedCache;
@property (nonatomic) NSURLSessionDataTask *downloadTask;
- (void)setImageWithURL:(NSURL *)url;
- (void)cancelLoading;

@end
