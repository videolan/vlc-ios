/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoMediaInfoTVViewController.h"
#import "VLCMetadata.h"

@interface VLCPlaybackInfoMediaInfoTVViewController ()

@end

@implementation VLCPlaybackInfoMediaInfoTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"MEDIA_INFO", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = nil;
    self.metaDataLabel.text = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateMediaTitle)
                                                 name:VLCPlaybackControllerPlaybackMetadataDidChange
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        UIColor *lightColor = [UIColor VLCLightTextColor];
        self.titleLabel.textColor = lightColor;
        self.metaDataLabel.textColor = lightColor;
    } else {
        UIColor *darkColor = [UIColor VLCDarkTextColor];
        self.titleLabel.textColor = darkColor;
        self.metaDataLabel.textColor = darkColor;
    }

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    self.titleLabel.text = vpc.metadata.title;

    VLCMedia *media = [vpc currentlyPlayingMedia];

    NSArray *mediaTrackData = media.tracksInformation;
    NSUInteger trackDataCount = mediaTrackData.count;
    NSUInteger videoWidth = 0, videoHeight = 0;
    NSString *videoCodec;
    NSString *audioCodecs;
    NSString *spuCodecs;
    for (NSUInteger x = 0; x < trackDataCount; x++) {
        NSDictionary *trackItem = mediaTrackData[x];
        NSString *trackType = trackItem[VLCMediaTracksInformationType];
        if ([trackType isEqualToString:VLCMediaTracksInformationTypeVideo]) {
            videoWidth = [trackItem[VLCMediaTracksInformationVideoWidth] unsignedIntegerValue];
            videoHeight = [trackItem[VLCMediaTracksInformationVideoHeight] unsignedIntegerValue];
            videoCodec = [VLCMedia codecNameForFourCC:[trackItem[VLCMediaTracksInformationCodec] unsignedIntValue]
                                            trackType:VLCMediaTracksInformationTypeVideo];
        } else if ([trackType isEqualToString:VLCMediaTracksInformationTypeAudio]) {
            NSString *language = trackItem[VLCMediaTracksInformationLanguage];
            NSString *codec = [VLCMedia codecNameForFourCC:[trackItem[VLCMediaTracksInformationCodec] unsignedIntValue]
                                                 trackType:VLCMediaTracksInformationTypeAudio];
            if (audioCodecs) {
                if (language)
                    audioCodecs = [audioCodecs stringByAppendingFormat:@", %@ — %@", language, codec];
                else
                    audioCodecs = [audioCodecs stringByAppendingFormat:@", %@", codec];
            } else {
                if (language)
                    audioCodecs = [NSString stringWithFormat:@"%@ — %@", language, codec];
                else
                    audioCodecs = codec;
            }
        } else if ([trackType isEqualToString:VLCMediaTracksInformationTypeText]) {
            NSString *language = trackItem[VLCMediaTracksInformationLanguage];
            NSString *codec = [VLCMedia codecNameForFourCC:[trackItem[VLCMediaTracksInformationCodec] unsignedIntValue]
                                                 trackType:VLCMediaTracksInformationTypeText];
            if (spuCodecs) {
                if (language)
                    spuCodecs = [spuCodecs stringByAppendingFormat:@", %@ — %@", language, codec];
                else
                    spuCodecs = [spuCodecs stringByAppendingFormat:@", %@", codec];
            } else {
                if (language)
                    spuCodecs = [NSString stringWithFormat:@"%@ — %@", language, codec];
                else
                    spuCodecs = codec;
            }
        }
    }

    NSString *metaDataString = @"";
    if (media.length.intValue > 0) {
        metaDataString = [NSString stringWithFormat:@"%@: %@\n",
         NSLocalizedString(@"DURATION", nil),
         media.length.verboseStringValue];
    }
    if (!vpc.metadata.isAudioOnly) {
        metaDataString = [metaDataString stringByAppendingFormat:@"%@: %@ (%@)\n",
                          NSLocalizedString(@"VIDEO_DIMENSIONS", nil),
                          [NSString stringWithFormat:NSLocalizedString(@"FORMAT_VIDEO_DIMENSIONS", nil),
                          videoWidth, videoHeight],
                          videoCodec];
    }
    NSInteger audioTrackCount = [vpc numberOfAudioTracks] -1; // minus fake disable track
    if (audioTrackCount > 0) {
        if (audioTrackCount > 1) {
            metaDataString = [metaDataString stringByAppendingFormat:NSLocalizedString(@"FORMAT_AUDIO_TRACKS", nil),
                              audioTrackCount];
        } else {
            metaDataString = [metaDataString stringByAppendingString:NSLocalizedString(@"ONE_AUDIO_TRACK", nil)];
        }
        metaDataString = [metaDataString stringByAppendingFormat:@" (%@)\n", audioCodecs];
    }
    NSInteger spuTrackCount = [vpc numberOfVideoSubtitlesIndexes] - 1; // minus fake disable track
    if (spuTrackCount > 0) {
        if (spuTrackCount > 1) {
            metaDataString = [metaDataString stringByAppendingFormat:NSLocalizedString(@"FORMAT_SPU_TRACKS", nil),
                              spuTrackCount];
        } else {
            metaDataString = [metaDataString stringByAppendingString:NSLocalizedString(@"ONE_SPU_TRACK", nil)];
        }
        metaDataString = [metaDataString stringByAppendingFormat:@" (%@)\n", spuCodecs];
    }
    self.metaDataLabel.text = metaDataString;
    [self.metaDataLabel sizeToFit];

    [super viewWillAppear:animated];
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 31. + self.titleLabel.frame.size.height + 8. + self.metaDataLabel.frame.size.height + 82.);
}

- (void)updateMediaTitle
{
    self.titleLabel.text = [VLCPlaybackController sharedInstance].metadata.title;
}

@end
