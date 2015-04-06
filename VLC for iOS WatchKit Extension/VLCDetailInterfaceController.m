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
@property (nonatomic, weak) MLFile *file;
@end

@implementation VLCDetailInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.playNowButton setTitle:NSLocalizedString(@"Play now", nil)];
        [self setTitle:NSLocalizedString(@"DETAIL", nil)];
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    if ([context isKindOfClass:[MLFile class]]) {
        [self configureWithFile:context];
    }
}

- (void)willActivate {
    [self.playNowButton setTitle:NSLocalizedString(@"PLAY_NOW", nil)];
    [self setTitle:NSLocalizedString(@"DETAIL", nil)];
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)configureWithFile:(MLFile *)file {
    self.file = file;

    [self.titleLabel setText:file.title];
    self.durationLabel.text = [VLCTime timeWithNumber:file.duration].stringValue;
    BOOL playEnabled = file != nil;
    self.playNowButton.enabled = playEnabled;
    UIImage *thumbnail = [VLCThumbnailsCache thumbnailForMediaFile:file];
    self.imageView.hidden = thumbnail == nil;
    if (thumbnail) {
        self.imageView.image = thumbnail;
    }
}

- (IBAction)playNow {
    NSDictionary *dict = @{@"name":@"playFile",
                           @"userInfo":@{
                                   @"URIRepresentation": self.file.objectID.URIRepresentation.absoluteString,
                                   }
                           };
    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        [self showNowPlaying:nil];
    }];
}
@end



