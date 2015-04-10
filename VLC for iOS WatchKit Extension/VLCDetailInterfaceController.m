/*****************************************************************************
 * VLCDetailInterfaceController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDetailInterfaceController.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import <MobileVLCKit/MobileVLCKit.h>
#import "VLCThumbnailsCache.h"

@interface VLCDetailInterfaceController ()
@property (nonatomic, weak) NSManagedObject *managedObject;
@end

@implementation VLCDetailInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTitle:NSLocalizedString(@"DETAIL", nil)];
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [self addNowPlayingMenu];
    [self configureWithFile:context];
}

- (void)willActivate {
    [self setTitle:NSLocalizedString(@"DETAIL", nil)];
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)configureWithFile:(NSManagedObject *)managedObject {
    self.managedObject = managedObject;

    float playbackProgress = 0.0;
    if ([managedObject isKindOfClass:[MLShowEpisode class]]) {
        [self.titleLabel setText:((MLShowEpisode *)managedObject).name];
    } else if ([managedObject isKindOfClass:[MLFile class]]) {
        MLFile *file = (MLFile *)managedObject;
        self.durationLabel.text = [VLCTime timeWithNumber:file.duration].stringValue;
        playbackProgress = file.lastPosition.floatValue;
        [self.titleLabel setText:((MLFile *)file).title];
    } else if ([managedObject isKindOfClass:[MLAlbumTrack class]]) {
        [self.titleLabel setText:((MLAlbumTrack *)managedObject).title];
    } else {
        NSAssert(NO, @"check what filetype we try to show here and add it above");
    }
    BOOL playEnabled = managedObject != nil;
    self.playNowButton.enabled = playEnabled;

    BOOL noProgress = (playbackProgress == 0.0 || playbackProgress == 1.0);
    self.progressSeparator.hidden = noProgress;
    self.progressSeparator.width = floor(playbackProgress * CGRectGetWidth([WKInterfaceDevice currentDevice].screenBounds));

    /* do not block the main thread */
    [self performSelectorInBackground:@selector(loadThumbnailForManagedObject:) withObject:managedObject];
}

- (void)loadThumbnailForManagedObject:(NSManagedObject *)managedObject
{
    UIImage *thumbnail = [VLCThumbnailsCache thumbnailForManagedObject:managedObject];
    if (thumbnail) {
        [self.group setBackgroundImage:thumbnail];
    }
}

- (IBAction)playNow {
    NSDictionary *dict = @{@"name":@"playFile",
                           @"userInfo":@{
                                   @"URIRepresentation": self.managedObject.objectID.URIRepresentation.absoluteString,
                                   }
                           };
    [self updateUserActivity:@"org.videolan.vlc-ios.playing" userInfo:@{@"playingmedia":self.managedObject.objectID.URIRepresentation} webpageURL:nil];
    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        [self showNowPlaying:nil];
    }];
}
@end



