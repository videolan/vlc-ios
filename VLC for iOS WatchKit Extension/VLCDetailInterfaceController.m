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
#import "VLCTime.h"
#import "VLCThumbnailsCache.h"
#import "WKInterfaceObject+VLCProgress.h"
#import "VLCWatchMessage.h"

@interface VLCDetailInterfaceController ()
@property (nonatomic, weak) NSManagedObject *managedObject;
@end

@implementation VLCDetailInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.title = NSLocalizedString(@"DETAIL", nil);
    self.playNowButton.accessibilityLabel = NSLocalizedString(@"PLAY_NOW", nil);
    self.titleLabel.accessibilityLabel = NSLocalizedString(@"TITLE", nil);
    self.durationLabel.accessibilityLabel = NSLocalizedString(@"DURATION", nil);

    [self addNowPlayingMenu];
    [self configureWithFile:context];
}

- (void)updateData {
    [super updateData];
    NSManagedObject *managedObject = self.managedObject;
    [managedObject.managedObjectContext refreshObject:managedObject mergeChanges:NO];
    [self configureWithFile:managedObject];
}

- (void)configureWithFile:(NSManagedObject *)managedObject {
    self.managedObject = managedObject;

    NSString *title = nil;
    NSString *durationString = nil;

    float playbackProgress = 0.0;
    if ([managedObject isKindOfClass:[MLShowEpisode class]]) {
        title = ((MLShowEpisode *)managedObject).name;
    } else if ([managedObject isKindOfClass:[MLFile class]]) {
        MLFile *file = (MLFile *)managedObject;
        durationString =  [VLCTime timeWithNumber:file.duration].stringValue;
        playbackProgress = file.lastPosition.floatValue;
        title = ((MLFile *)file).title;
    } else if ([managedObject isKindOfClass:[MLAlbumTrack class]]) {
        title = ((MLAlbumTrack *)managedObject).title;
    } else {
        NSAssert(NO, @"check what filetype we try to show here and add it above");
    }

    BOOL playEnabled = managedObject != nil;
    self.playNowButton.enabled = playEnabled;

    self.mediaTitle = title;
    self.mediaDuration = durationString;
    self.playbackProgress = playbackProgress;

    /* do not block the main thread */
    [self performSelectorInBackground:@selector(loadThumbnailForManagedObject:) withObject:managedObject];
}

- (void)loadThumbnailForManagedObject:(NSManagedObject *)managedObject
{
    UIImage *thumbnail = [VLCThumbnailsCache thumbnailForManagedObject:managedObject];
    if (thumbnail) {
        [self.group performSelectorOnMainThread:@selector(setBackgroundImage:) withObject:thumbnail waitUntilDone:NO];
    }
}

- (IBAction)playNow {

    id payload = self.managedObject.objectID.URIRepresentation.absoluteString;
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:@"playFile"
                                                           payload:payload];
    [self updateUserActivity:@"org.videolan.vlc-ios.playing" userInfo:@{@"playingmedia":self.managedObject.objectID.URIRepresentation} webpageURL:nil];

    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        [self showNowPlaying:nil];
    }];
}

- (void)setMediaTitle:(NSString *)mediaTitle {
    if (![_mediaTitle isEqualToString:mediaTitle]) {
        _mediaTitle = [mediaTitle copy];
        self.titleLabel.text = mediaTitle;
        self.titleLabel.accessibilityValue = mediaTitle;
        self.titleLabel.hidden = mediaTitle.length == 0;
    }
}

- (void)setMediaDuration:(NSString *)mediaDuration {
    if (![_mediaDuration isEqualToString:mediaDuration]) {
        _mediaDuration = [mediaDuration copy];
        self.durationLabel.text = mediaDuration;
        self.durationLabel.hidden = mediaDuration.length == 0;
        self.durationLabel.accessibilityValue = mediaDuration;
    }
}

- (void)setPlaybackProgress:(CGFloat)playbackProgress {
    if (_playbackProgress != playbackProgress) {
        _playbackProgress = playbackProgress;
        [self.progressObject vlc_setProgress:playbackProgress hideForNoProgress:YES];
    }
}

@end



