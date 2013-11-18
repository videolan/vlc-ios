//
//  VLCThumbnailsCache.h
//  VLC for iOS
//
//  Created by Gleb on 9/13/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <Foundation/Foundation.h>

@interface VLCThumbnailsCache : NSObject

+ (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile;

@end
