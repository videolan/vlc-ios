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
#import "VLCTime.h"
#import "VLCThumbnailsCache.h"
#import "WKInterfaceObject+VLCProgress.h"
#import "VLCWatchMessage.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface VLCDetailInterfaceController ()
@property (nonatomic, weak) NSManagedObjectContext *moc;
@property (nonatomic, strong) NSManagedObjectID *objectID;
@end

@implementation VLCDetailInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.title = NSLocalizedString(@"DETAIL", nil);
    self.playNowButton.accessibilityLabel = NSLocalizedString(@"PLAY_NOW", nil);
    self.titleLabel.accessibilityLabel = NSLocalizedString(@"TITLE", nil);
    self.durationLabel.accessibilityLabel = NSLocalizedString(@"DURATION", nil);

    [self addNowPlayingMenu];

    NSManagedObject *managedObject = context;
    [self configureWithFile:managedObject];

    self.objectID = managedObject.objectID;
    self.moc = managedObject.managedObjectContext;
}

- (void)updateData {
    [super updateData];
    [self.moc performBlock:^{
        [self configureWithFile:[self.moc objectWithID:self.objectID]];
    }];
}

- (void)configureWithFile:(NSManagedObject *)managedObject {

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

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.playNowButton.enabled = playEnabled;

        self.mediaTitle = title;
        self.mediaDuration = durationString;
        self.playbackProgress = playbackProgress;
    }];

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

    NSURL *currentObjectURI = self.objectID.URIRepresentation;
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:@"playFile"
                                                           payload:currentObjectURI.absoluteString];
    [self updateUserActivity:@"org.videolan.vlc-ios.playing" userInfo:@{@"playingmedia":currentObjectURI} webpageURL:nil];

    [self vlc_performBlockIfSessionReachable:^{
        [[WCSession defaultSession] sendMessage:dict replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            [self showNowPlaying:nil];
        } errorHandler:nil];
    } showUnreachableAlert:YES];
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



