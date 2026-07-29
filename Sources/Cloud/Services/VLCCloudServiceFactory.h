/*****************************************************************************
 * VLCCloudServiceFactory.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VLCCloudService) {
    VLCCloudServiceNone,
    VLCCloudServiceDropbox,
    VLCCloudServiceGoogleDrive,
    VLCCloudServiceBox,
    VLCCloudServicePCloud
};

/* the cloud browsers mint synthetic file://<service>/<path> URLs to reference their content
 * outside of their own view controllers, so the host names the service */
@interface VLCCloudServiceFactory : NSObject

+ (VLCCloudService)serviceForURL:(nullable NSURL *)url;

+ (nullable UIImage *)iconForService:(VLCCloudService)service;

+ (nullable UIViewController *)browserForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
