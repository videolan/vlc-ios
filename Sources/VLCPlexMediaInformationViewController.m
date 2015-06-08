/*****************************************************************************
 * VLCPlexMediaInformationViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlexMediaInformationViewController.h"
#import "VLCPlexParser.h"
#import "VLCPlexWebAPI.h"
#import "VLCAppDelegate.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"

@interface VLCPlexMediaInformationViewController ()
{
    NSDictionary *_mediaObject;
    NSString *_PlexServerAddress;
    NSString *_PlexServerPort;
    NSString *_PlexServerPath;
    NSString *_PlexAuthentification;
    VLCPlexParser *_PlexParser;
    VLCPlexWebAPI *_PlexWebAPI;
}
@end

@implementation VLCPlexMediaInformationViewController

- (id)initPlexMediaInformation:(NSDictionary *)mediaInformation
                 serverAddress:(NSString *)serverAddress
                    portNumber:(NSString *)portNumber
                        atPath:(NSString *)path
              authentification:(NSString *)auth
{
    self = [super init];
    if (self) {
        _mediaObject = mediaInformation;
        _PlexServerAddress = serverAddress;
        _PlexServerPort = portNumber;
        _PlexServerPath = path;
        _PlexAuthentification = auth;
        _PlexParser = [[VLCPlexParser alloc] init];
        _PlexWebAPI = [[VLCPlexWebAPI alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor VLCDarkBackgroundColor]];
    [self.summary setBackgroundColor:[UIColor VLCDarkBackgroundColor]];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;

    NSString *title = _mediaObject[@"title"];
    NSString *thumbPath = [_PlexWebAPI urlAuth:_mediaObject[@"thumb"] autentification:_PlexAuthentification];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:thumbPath]]];
    NSInteger size = [_mediaObject[@"size"] integerValue];
    NSString *mediaSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
    NSString *durationInSeconds = _mediaObject[@"duration"];
    NSString *displaySize = [NSString stringWithFormat:@"%@ (%@)", mediaSize, durationInSeconds];
    NSString *tag = _mediaObject[@"state"];
    NSString *displaySummary = [NSString stringWithFormat:@"%@", _mediaObject[@"summary"]];

    NSString *audioCodec = _mediaObject[@"audioCodec"];
    if (!audioCodec)
        audioCodec = @"no track";

    NSString *videoCodec = _mediaObject[@"videoCodec"];
    if (!videoCodec)
        videoCodec = @"no track";

    NSString *displayCodec = [NSString stringWithFormat:@"audio(%@) video(%@)", audioCodec, videoCodec];

    NSString *grandparentTitle = _mediaObject[@"grandparentTitle"];
    if (grandparentTitle)
        self.title = grandparentTitle;
    else
        self.title = title;

    [self.thumb setContentMode:UIViewContentModeScaleAspectFit];
    [self.thumb setImage:image];
    [self.mediaTitle setText:title];
    [self.codec setText:displayCodec];
    [self.size setText:displaySize];
    [self.summary setText:displaySummary];

    if ([tag isEqualToString:@"watched"]) {
        [self.badgeUnread setHidden:YES];
        [self.markMediaButton setTitle:NSLocalizedString(@"PLEX_UNWATCHED", nil)];
    } else if ([tag isEqualToString:@"unwatched"]) {
        [self.badgeUnread setHidden:NO];
        [self.markMediaButton setTitle:NSLocalizedString(@"PLEX_WATCHED", nil)];
    } else {
        [self.badgeUnread setHidden:NO];
        [self.markMediaButton setEnabled:NO];
    }

    [self.badgeUnread setNeedsDisplay];
}

#pragma mark - Specifics

- (void)_playMediaItem
{
    if (_mediaObject == nil)
        return;

    NSString *newPath = nil;
    NSString *keyValue = _mediaObject[@"key"];

    if ([keyValue rangeOfString:@"library"].location == NSNotFound)
        newPath = [_PlexServerPath stringByAppendingPathComponent:keyValue];
    else
        newPath = keyValue;

    if ([_mediaObject[@"container"] isEqualToString:@"item"]) {
        NSArray *mediaList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:newPath authentification:@""];
        NSString *URLofSubtitle = nil;
        NSDictionary *firstObject = [mediaList firstObject];
        if (!firstObject)
            return;

        if (firstObject[@"keySubtitle"])
            URLofSubtitle = [_PlexWebAPI getFileSubtitleFromPlexServer:firstObject modeStream:YES];

        NSURL *itemURL = [NSURL URLWithString:[_PlexWebAPI urlAuth:firstObject[@"keyMedia"] autentification:_PlexAuthentification]];
        if (itemURL) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate openMovieWithExternalSubtitleFromURL:itemURL externalSubURL:URLofSubtitle];
        }
    }
}

- (void)_download
{
    if (_mediaObject == nil)
        return;

    NSString *path = _mediaObject[@"key"];

    NSArray *mediaList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:path authentification:@""];
    NSDictionary *firstObject = [mediaList firstObject];
    if (!firstObject)
        return;

    NSInteger size = [firstObject[@"size"] integerValue];
    if (size  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        if (firstObject[@"keySubtitle"])
            [_PlexWebAPI getFileSubtitleFromPlexServer:firstObject modeStream:NO];



        NSURL *itemURL = [NSURL URLWithString:firstObject[@"keyMedia"]];
        if (![[itemURL absoluteString] isSupportedFormat]) {
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [itemURL absoluteString]]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                    otherButtonTitles:nil];
            [alert show];
        } else if (itemURL) {
            NSString *fileName = [firstObject objectForKey:@"namefile"];
            [[(VLCAppDelegate *)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:itemURL fileNameOfMedia:fileName];
        }
    } else {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), firstObject[@"title"], [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Action

- (IBAction)play:(id)sender
{
    [self _playMediaItem];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)download:(id)sender
{
    [self _download];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)markMedia:(id)sender
{
    NSString *ratingKey = _mediaObject[@"ratingKey"];
    NSString *tag = _mediaObject[@"state"];

    NSInteger status = [_PlexWebAPI MarkWatchedUnwatchedMedia:_PlexServerAddress port:_PlexServerPort videoRatingKey:ratingKey state:tag authentification:_PlexAuthentification];
    if (status == 200) {
        if ([tag isEqualToString:@"watched"]) {
            tag = @"unwatched";
            [self.badgeUnread setHidden:NO];
            [self.markMediaButton setTitle:NSLocalizedString(@"PLEX_WATCHED", nil)];
        } else if ([tag isEqualToString:@"unwatched"]) {
            tag = @"watched";
            [self.badgeUnread setHidden:YES];
            [self.markMediaButton setTitle:NSLocalizedString(@"PLEX_UNWATCHED", nil)];
        }
    } else
        [self.badgeUnread setHidden:YES];

    [self.badgeUnread setNeedsDisplay];

    NSMutableDictionary *mutableMediaObject = [NSMutableDictionary dictionaryWithDictionary:_mediaObject];
    [mutableMediaObject setObject:tag forKey:@"state"];
    _mediaObject = [NSDictionary dictionaryWithDictionary:mutableMediaObject];
}

#pragma mark - UI interaction

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

@end