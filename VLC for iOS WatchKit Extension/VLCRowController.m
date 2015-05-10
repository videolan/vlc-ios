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

@property (nonatomic) UIImage *rawBackgroundImage;

@end

@implementation VLCRowController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self calculateThumbnailSizeAndRowWidth];
        _playbackProgress = -1;
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
    NSString *title = nil;
    float playbackProgress = 0.0;
    NSString *objectType = nil;
    if ([storageObject isKindOfClass:[MLShow class]]) {
        objectType = NSLocalizedString(@"OBJECT_TYPE_SHOW", nil);
        title = ((MLAlbum *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLShowEpisode class]]) {
        objectType = NSLocalizedString(@"OBJECT_TYPE_SHOW_EPISODE", nil);
        title = ((MLShowEpisode *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLLabel class]]) {
        objectType = NSLocalizedString(@"OBJECT_TYPE_LABEL", nil);
        title = ((MLLabel *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLAlbum class]]) {
        objectType = NSLocalizedString(@"OBJECT_TYPE_ALBUM", nil);
        title = ((MLAlbum *)storageObject).name;
    } else if ([storageObject isKindOfClass:[MLAlbumTrack class]]) {
        objectType = NSLocalizedString(@"OBJECT_TYPE_ALBUM_TRACK", nil);
        title = ((MLAlbumTrack *)storageObject).title;
    } else if ([storageObject isKindOfClass:[MLFile class]]){
        MLFile *file = (MLFile *)storageObject;
        title = [file title];
        playbackProgress = file.lastPosition.floatValue;
        if (file.isSupportedAudioFile) {
            objectType = NSLocalizedString(@"OBJECT_TYPE_FILE_AUDIO", nil);
        } else {
            objectType = NSLocalizedString(@"OBJECT_TYPE_FILE", nil);
        }
    }

    self.titleLabel.accessibilityValue = objectType;
    self.mediaTitle = title;
    self.playbackProgress = playbackProgress;

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

    // don't redo image processing if no necessary
    if ([self.rawBackgroundImage isEqual:backgroundImage]) {
        return;
    }
    self.rawBackgroundImage = backgroundImage;

    UIImage *gradient = [UIImage imageNamed:@"tableview-gradient"];

    CGSize newSize = backgroundImage ? backgroundImage.size : CGSizeMake(_rowWidth, 120.);
    UIGraphicsBeginImageContext(newSize);

    if (backgroundImage)
        [backgroundImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    else {
        [[UIColor darkGrayColor] set];
        UIRectFill(CGRectMake(0., 0., newSize.width, newSize.height));
    }

    [gradient drawInRect:CGRectMake(0., 0., newSize.width, newSize.height / 2.) blendMode:kCGBlendModeNormal alpha:1.];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    [array.firstObject performSelectorOnMainThread:@selector(setBackgroundImage:) withObject:newImage waitUntilDone:NO];
}

- (void)setMediaTitle:(NSString *)mediaTitle {
    if (![_mediaTitle isEqualToString:mediaTitle]) {
        _mediaTitle = [mediaTitle copy];
        self.titleLabel.text = mediaTitle;
        self.accessibilityLabel = mediaTitle;
        self.titleLabel.hidden = mediaTitle.length == 0;
    }
}

- (void)setPlaybackProgress:(CGFloat)playbackProgress {
    if (_playbackProgress != playbackProgress) {
        _playbackProgress = playbackProgress;
        [self.progressObject vlc_setProgress:playbackProgress hideForNoProgress:YES];
    }
}

@end
