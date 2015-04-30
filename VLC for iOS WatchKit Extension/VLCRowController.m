/*****************************************************************************
 * VLCRowController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRowController.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "WKInterfaceObject+VLCProgress.h"
#import "VLCThumbnailsCache.h"

@interface VLCRowController()
@property (nonatomic, weak, readwrite) id mediaLibraryObject;
@property (nonatomic, readonly) CGRect thumbnailSize;
@property (nonatomic, readonly) CGFloat rowWidth;

@end

@implementation VLCRowController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self calculateThumbnailSizeAndRowWidth];
    }
    return self;
}

- (void)calculateThumbnailSizeAndRowWidth
{
    WKInterfaceDevice *currentDevice = WKInterfaceDevice.currentDevice;
    CGRect screenRect = currentDevice.screenBounds;
    CGFloat screenScale = currentDevice.screenScale;
    _thumbnailSize =  CGRectMake(0,
                                       0,
                                       screenRect.size.width * screenScale,
                                       120. * screenScale
                                       );
    _rowWidth = screenRect.size.width * screenScale;
}

- (void)configureWithMediaLibraryObject:(id)storageObject
{
    float playbackProgress = 0.0;
    if ([storageObject isKindOfClass:[MLShow class]]) {
        self.titleLabel.text = ((MLAlbum *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLShowEpisode class]]) {
        self.titleLabel.text = ((MLShowEpisode *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLLabel class]]) {
        self.titleLabel.text = ((MLLabel *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLAlbum class]]) {
        self.titleLabel.text = ((MLAlbum *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLAlbumTrack class]]) {
        self.titleLabel.text = ((MLAlbumTrack *)storageObject).title;
    } else if ([storageObject isKindOfClass:[MLFile class]]){
        MLFile *file = (MLFile *)storageObject;
        self.titleLabel.text = [file title];
        playbackProgress = file.lastPosition.floatValue;
    }

    [self.progressObject vlc_setProgress:playbackProgress hideForNoProgress:YES];

    /* FIXME: add placeholder image once designed */

    if (storageObject != self.mediaLibraryObject) {
        self.group.backgroundImage = [UIImage imageNamed:@"tableview-gradient"];
    }

    NSArray *array = @[self.group, storageObject];
    [self performSelectorInBackground:@selector(backgroundThumbnailSetter:) withObject:array];

    self.mediaLibraryObject = storageObject;
}

- (void)backgroundThumbnailSetter:(NSArray *)array
{
    UIImage *backgroundImage = [VLCThumbnailsCache thumbnailForManagedObject:array[1] toFitRect:_thumbnailSize shouldReplaceCache:YES];
    UIImage *gradient = [UIImage imageNamed:@"tableview-gradient"];

    CGSize newSize = backgroundImage ? backgroundImage.size : CGSizeMake(_rowWidth, 120.);
    UIGraphicsBeginImageContext(newSize);

    if (backgroundImage)
        [backgroundImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    else {
        [[UIColor darkGrayColor] set];
        UIRectFill(CGRectMake(.0, .0, newSize.width, newSize.height));
    }

    [gradient drawInRect:CGRectMake(.0, newSize.height / 2., newSize.width, newSize.height / 2.) blendMode:kCGBlendModeNormal alpha:1.];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    [array.firstObject performSelectorOnMainThread:@selector(setBackgroundImage:) withObject:newImage waitUntilDone:NO];
}
@end
