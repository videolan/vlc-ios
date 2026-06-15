/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlayerControlsBar.h"
#import "VLCPlayerInlineMenuViewController.h"
#import "VLCPlaybackInfoSubtitlesFetcherViewController.h"
#import "VLCMetadata.h"
#import "UIColor+Presets.h"
#import "VLC-Swift.h"

@interface VLCPlayerControlsBar () <VLCPlayerInlineMenuDelegate>
{
    NSArray<UIButton *> *_controlButtons;
    UIButton *_subtitlesButton;
    UIButton *_audioButton;
    UIButton *_chaptersButton;
    UIButton *_speedButton;
    UIButton *_queueButton;
    UIButton *_infoButton;
}
@end

@implementation VLCPlayerControlsBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.axis = UILayoutConstraintAxisHorizontal;
        self.alignment = UIStackViewAlignmentFill;
        self.spacing = 20.0;

        _subtitlesButton = [self makeControlButtonWithImageName:@"captions.bubble" accessibilityLabel:NSLocalizedString(@"SUBTITLES", nil) action:@selector(subtitlesButtonPressed)];
        _audioButton = [self makeControlButtonWithImageName:@"waveform" accessibilityLabel:NSLocalizedString(@"AUDIO", nil) action:@selector(audioButtonPressed)];
        _chaptersButton = [self makeControlButtonWithImageName:@"list.bullet" accessibilityLabel:NSLocalizedString(@"CHAPTER_SELECTION_TITLE", nil) action:@selector(chaptersButtonPressed)];
        _speedButton = [self makeControlButtonWithImageName:@"gauge" accessibilityLabel:NSLocalizedString(@"PLAYBACK_SPEED", nil) action:@selector(speedButtonPressed)];
        _queueButton = [self makeControlButtonWithImageName:@"list.bullet.rectangle" accessibilityLabel:NSLocalizedString(@"QUEUE_LABEL", nil) action:@selector(queueButtonPressed)];
        _infoButton = [self makeControlButtonWithImageName:@"info.circle" accessibilityLabel:NSLocalizedString(@"MEDIA_INFO", nil) action:@selector(infoButtonPressed)];
        _controlButtons = @[_subtitlesButton, _audioButton, _chaptersButton, _speedButton, _queueButton, _infoButton];

        for (UIButton *button in _controlButtons) {
            [self addArrangedSubview:button];
        }

        [self updateContentVisibility];
    }
    return self;
}

- (void)updateContentVisibility
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    _chaptersButton.hidden = [vpc numberOfChaptersForCurrentTitle] <= 1;
    _subtitlesButton.hidden = vpc.metadata.isAudioOnly;
}

- (UIButton *)makeControlButtonWithImageName:(NSString *)imageName
                          accessibilityLabel:(NSString *)label
                                      action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    if (@available(tvOS 26.0, *)) {
        UIButtonConfiguration *glass = [UIButtonConfiguration glassButtonConfiguration];
        glass.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        glass.baseForegroundColor = UIColor.whiteColor;
        button.configuration = glass;
    } else {
        button.tintColor = UIColor.whiteColor;
        button.backgroundColor = UIColor.VLCTransparentDarkBackgroundColor;
        button.layer.cornerRadius = 30.0;
        button.clipsToBounds = YES;
    }

    [self applyImageName:imageName toButton:button];
    button.accessibilityLabel = label;
    [button.widthAnchor constraintEqualToConstant:60.0].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventPrimaryActionTriggered];
    return button;
}

- (void)applyImageName:(NSString *)imageName toButton:(UIButton *)button
{
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:28.0];
    UIImage *image = [UIImage systemImageNamed:imageName withConfiguration:configuration];
    if (@available(tvOS 26.0, *)) {
        UIButtonConfiguration *glass = button.configuration;
        glass.image = image;
        button.configuration = glass;
    } else {
        [button setImage:image forState:UIControlStateNormal];
    }
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    for (UIButton *button in _controlButtons) {
        if (!button.hidden) {
            return @[button];
        }
    }
    return [super preferredFocusEnvironments];
}

#pragma mark - actions

- (void)subtitlesButtonPressed
{
    [self presentMenuOfKind:VLCPlayerMenuKindSubtitles fromButton:_subtitlesButton];
}

- (void)audioButtonPressed
{
    [self presentMenuOfKind:VLCPlayerMenuKindAudio fromButton:_audioButton];
}

- (void)chaptersButtonPressed
{
    [self presentMenuOfKind:VLCPlayerMenuKindChapters fromButton:_chaptersButton];
}

- (void)speedButtonPressed
{
    [self presentMenuOfKind:VLCPlayerMenuKindSpeed fromButton:_speedButton];
}

- (void)queueButtonPressed
{
    VLCPlayerQueuePanelViewController *queue = [[VLCPlayerQueuePanelViewController alloc] initWithTitle:_queueButton.accessibilityLabel];
    [queue presentFromButton:_queueButton inViewController:self.presenter];
}

- (void)infoButtonPressed
{
    VLCPlayerInfoPanelViewController *info = [[VLCPlayerInfoPanelViewController alloc] initWithTitle:_infoButton.accessibilityLabel
                                                                                          infoText:[self mediaInfoString]];
    [info presentFromButton:_infoButton inViewController:self.presenter];
}

- (void)presentMenuOfKind:(VLCPlayerMenuKind)kind fromButton:(UIButton *)button
{
    NSArray<VLCPlayerMenuItem *> *items = nil;
    NSString *title = button.accessibilityLabel;
    switch (kind) {
        case VLCPlayerMenuKindSubtitles:
            items = [self subtitleMenuItems];
            break;
        case VLCPlayerMenuKindSecondarySubtitles:
            items = [self secondarySubtitleMenuItems];
            title = NSLocalizedString(@"SECONDARY_SUBTITLE", nil);
            break;
        case VLCPlayerMenuKindAudio:
            items = [self audioMenuItems];
            break;
        case VLCPlayerMenuKindChapters:
            items = [self chapterMenuItems];
            break;
        case VLCPlayerMenuKindSpeed:
            items = [self speedMenuItems];
            break;
    }

    VLCPlayerInlineMenuViewController *menu = [[VLCPlayerInlineMenuViewController alloc] initWithTitle:title items:items];
    menu.kind = kind;
    menu.delegate = self;
    [self configureStepperForMenu:menu];
    [menu presentFromButton:button inViewController:self.presenter];
}

- (void)configureStepperForMenu:(VLCPlayerInlineMenuViewController *)menu
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (menu.kind) {
        case VLCPlayerMenuKindAudio:
            menu.showsStepperControl = YES;
            menu.stepperTitle = NSLocalizedString(@"AUDIO_DELAY", nil);
            menu.currentValue = vpc.audioDelay;
            menu.stepperStep = [[defaults valueForKey:kVLCSettingsAudioOffsetDelay] floatValue];
            menu.minimumValue = -30000.0;
            menu.maximumValue = 30000.0;
            menu.stepperUnit = VLCPlayerStepperUnitMilliseconds;
            break;
        case VLCPlayerMenuKindSubtitles:
            menu.showsStepperControl = YES;
            menu.stepperTitle = NSLocalizedString(@"SPU_DELAY", nil);
            menu.currentValue = vpc.subtitleDelay;
            menu.stepperStep = [[defaults valueForKey:kVLCSettingsSubtitlesOffsetDelay] floatValue];
            menu.minimumValue = -30000.0;
            menu.maximumValue = 30000.0;
            menu.stepperUnit = VLCPlayerStepperUnitMilliseconds;
            break;
        case VLCPlayerMenuKindSpeed:
            menu.showsStepperControl = YES;
            menu.stepperTitle = NSLocalizedString(@"PLAYBACK_SPEED", nil);
            menu.currentValue = vpc.playbackRate;
            menu.stepperStep = 0.05;
            menu.minimumValue = 0.25;
            menu.maximumValue = 4.0;
            menu.defaultValue = vpc.defaultPlaybackRate;
            menu.stepperUnit = VLCPlayerStepperUnitRate;
            break;
        default:
            break;
    }
}

#pragma mark - menu contents

- (NSArray<VLCPlayerMenuItem *> *)audioMenuItems
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger trackCount = [vpc numberOfAudioTracks] - 2; // real tracks; +2 are the Disable and "from files" rows
    NSInteger current = [vpc indexOfCurrentAudioTrack];
    NSMutableArray<VLCPlayerMenuItem *> *items = [NSMutableArray arrayWithCapacity:trackCount + 1];
    [items addObject:[VLCPlayerMenuItem itemWithTitle:NSLocalizedString(@"DISABLE_LABEL", nil) selected:(current == -1)]];
    for (NSInteger i = 0; i < trackCount; i++) {
        [items addObject:[VLCPlayerMenuItem itemWithTitle:[vpc audioTrackNameAtIndex:i] selected:(i == current)]];
    }
    return items;
}

- (NSArray<VLCPlayerMenuItem *> *)subtitleMenuItems
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger trackCount = [vpc numberOfVideoSubtitlesIndexes] - 3; // real tracks; +3 are Disable, "from files" and download rows
    NSInteger current = [vpc indexOfCurrentPrimaryVideoSubtitleTrack];
    NSMutableArray<VLCPlayerMenuItem *> *items = [NSMutableArray arrayWithCapacity:trackCount + 3];
    [items addObject:[VLCPlayerMenuItem itemWithTitle:NSLocalizedString(@"DISABLE_LABEL", nil) selected:(current == -1)]];
    for (NSInteger i = 0; i < trackCount; i++) {
        [items addObject:[VLCPlayerMenuItem itemWithTitle:[vpc videoSubtitleNameAtIndex:i] selected:(i == current)]];
    }
    [items addObject:[VLCPlayerMenuItem itemWithTitle:NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil) selected:NO]];
    if (trackCount > 0) {
        BOOL secondaryEnabled = [vpc indexOfCurrentSecondaryVideoSubtitleTrack] != -1;
        [items addObject:[VLCPlayerMenuItem itemWithTitle:NSLocalizedString(@"SECONDARY_SUBTITLE", nil) selected:secondaryEnabled]];
    }
    return items;
}

- (NSArray<VLCPlayerMenuItem *> *)secondarySubtitleMenuItems
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger trackCount = [vpc numberOfVideoSubtitlesIndexes] - 3;
    NSInteger current = [vpc indexOfCurrentSecondaryVideoSubtitleTrack];
    NSMutableArray<VLCPlayerMenuItem *> *items = [NSMutableArray arrayWithCapacity:trackCount + 1];
    [items addObject:[VLCPlayerMenuItem itemWithTitle:NSLocalizedString(@"DISABLE_LABEL", nil) selected:(current == -1)]];
    for (NSInteger i = 0; i < trackCount; i++) {
        [items addObject:[VLCPlayerMenuItem itemWithTitle:[vpc videoSubtitleNameAtIndex:i] selected:(i == current)]];
    }
    return items;
}

- (NSArray<VLCPlayerMenuItem *> *)chapterMenuItems
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger count = [vpc numberOfChaptersForCurrentTitle];
    NSInteger current = [vpc indexOfCurrentChapter];
    NSMutableArray<VLCPlayerMenuItem *> *items = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        VLCMediaPlayerChapterDescription *chapter = [vpc chapterDescriptionAtIndex:i];
        NSString *name = chapter.name;
        if (name == nil) {
            name = [NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"CHAPTER", nil), (long)i];
        }
        NSString *itemTitle = [NSString stringWithFormat:@"%@ (%@)", name, [chapter.durationTime stringValue]];
        [items addObject:[VLCPlayerMenuItem itemWithTitle:itemTitle selected:(i == current)]];
    }
    return items;
}

+ (NSArray<NSNumber *> *)speedPresets
{
    return @[@0.5, @0.75, @1.0, @1.25, @1.5, @2.0];
}

- (NSArray<VLCPlayerMenuItem *> *)speedMenuItems
{
    float current = [VLCPlaybackService sharedInstance].playbackRate;
    NSArray<NSNumber *> *presets = [[self class] speedPresets];
    NSMutableArray<VLCPlayerMenuItem *> *items = [NSMutableArray arrayWithCapacity:presets.count];
    for (NSNumber *preset in presets) {
        NSString *itemTitle = [NSString stringWithFormat:@"%.2fx", preset.floatValue];
        BOOL selected = fabsf(preset.floatValue - current) < 0.01f;
        VLCPlayerMenuItem *item = [VLCPlayerMenuItem itemWithTitle:itemTitle selected:selected];
        item.value = preset;
        [items addObject:item];
    }
    return items;
}

- (void)inlineMenu:(VLCPlayerInlineMenuViewController *)menu didSelectItemAtIndex:(NSInteger)index
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    switch (menu.kind) {
        case VLCPlayerMenuKindAudio:
            if (index == 0) {
                [vpc disableAudio];
            } else {
                [vpc selectAudioTrackAtIndex:index - 1];
            }
            break;
        case VLCPlayerMenuKindSubtitles: {
            NSInteger trackCount = [vpc numberOfVideoSubtitlesIndexes] - 3;
            if (index == 0) {
                [vpc disablePrimaryVideoSubtitle];
            } else if (index <= trackCount) {
                [vpc selectPrimaryVideoSubtitleAtIndex:index - 1];
            } else if (index == trackCount + 1) {
                [self presentSubtitleDownloader];
            } else {
                [self presentMenuOfKind:VLCPlayerMenuKindSecondarySubtitles fromButton:_subtitlesButton];
            }
            break;
        }
        case VLCPlayerMenuKindSecondarySubtitles:
            if (index == 0) {
                [vpc disableSecondaryVideoSubtitle];
            } else {
                [vpc selectSecondaryVideoSubtitleAtIndex:index - 1];
            }
            break;
        case VLCPlayerMenuKindChapters:
            [vpc selectChapterAtIndex:index];
            break;
        case VLCPlayerMenuKindSpeed:
            vpc.playbackRate = [[self class] speedPresets][index].floatValue;
            break;
    }
}

- (void)inlineMenu:(VLCPlayerInlineMenuViewController *)menu didSetValue:(float)value
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    switch (menu.kind) {
        case VLCPlayerMenuKindAudio:
            vpc.audioDelay = value;
            break;
        case VLCPlayerMenuKindSubtitles:
            vpc.subtitleDelay = value;
            break;
        case VLCPlayerMenuKindSpeed:
            vpc.playbackRate = value;
            break;
        default:
            break;
    }
}

- (void)presentSubtitleDownloader
{
    VLCPlaybackInfoSubtitlesFetcherViewController *fetcher = [[VLCPlaybackInfoSubtitlesFetcherViewController alloc] initWithNibName:nil bundle:nil];
    fetcher.title = NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    [self.presenter presentViewController:fetcher animated:YES completion:nil];
}

- (NSString *)mediaInfoString
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [vpc currentlyPlayingMedia];

    NSUInteger videoWidth = 0, videoHeight = 0;
    NSString *videoCodec;
    NSString *audioCodecs;
    NSString *spuCodecs;
    VLCMediaTrack *videoTrack = media.videoTracks.firstObject;
    videoWidth = videoTrack.video.width;
    videoHeight = videoTrack.video.height;
    videoCodec = [VLCMedia codecNameForFourCC:videoTrack.codec trackType:VLCMediaTrackTypeVideo];

    NSArray *audioTracks = media.audioTracks;
    for (VLCMediaTrack *track in audioTracks) {
        NSString *codec = [VLCMedia codecNameForFourCC:track.codec
                                             trackType:VLCMediaTrackTypeAudio];
        NSString *language = track.language;
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
    }

    NSArray *textTracks = media.textTracks;
    for (VLCMediaTrack *track in textTracks) {
        NSString *codec = [VLCMedia codecNameForFourCC:track.codec
                                             trackType:VLCMediaTrackTypeText];
        NSString *language = track.language;
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

    NSString *metaDataString = @"";
    if (media.length.intValue > 0) {
        metaDataString = [NSString stringWithFormat:@"%@: %@\n",
                          NSLocalizedString(@"DURATION", nil),
                          media.length.verboseStringValue];
    }
    if (!vpc.metadata.isAudioOnly) {
        metaDataString = [metaDataString stringByAppendingFormat:@"%@: %@\r",
                          NSLocalizedString(@"VIDEO_DIMENSIONS", nil),
                          [NSString stringWithFormat:NSLocalizedString(@"FORMAT_VIDEO_DIMENSIONS", nil),
                           videoWidth, videoHeight]];
        metaDataString = [metaDataString stringByAppendingFormat:@"%@: %@\n", NSLocalizedString(@"VIDEO_CODEC", nil), videoCodec];
    }
    NSInteger audioTrackCount = [vpc numberOfAudioTracks] - 2; // minus the Disable and "from files" rows
    if (audioTrackCount > 0) {
        if (audioTrackCount > 1) {
            metaDataString = [metaDataString stringByAppendingFormat:NSLocalizedString(@"FORMAT_AUDIO_TRACKS", nil),
                              audioTrackCount];
        } else {
            metaDataString = [metaDataString stringByAppendingString:NSLocalizedString(@"ONE_AUDIO_TRACK", nil)];
        }
        metaDataString = [metaDataString stringByAppendingFormat:@" (%@)\n", audioCodecs];
    }
    NSInteger spuTrackCount = [vpc numberOfVideoSubtitlesIndexes] - 3; // minus Disable, "from files" and download rows
    if (spuTrackCount > 0) {
        if (spuTrackCount > 1) {
            metaDataString = [metaDataString stringByAppendingFormat:NSLocalizedString(@"FORMAT_SPU_TRACKS", nil),
                              spuTrackCount];
        } else {
            metaDataString = [metaDataString stringByAppendingString:NSLocalizedString(@"ONE_SPU_TRACK", nil)];
        }
        metaDataString = [metaDataString stringByAppendingFormat:@" (%@)\n", spuCodecs];
    }
    return [metaDataString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
