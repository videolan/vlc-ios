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
#import "VLCAppDelegate.h"
#import "UIBarButtonItem+Theme.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"

@interface VLCPlexMediaInformationViewController ()
{
    NSMutableArray *_mutableMediaInformation;
    NSString *_PlexServerAddress;
    NSString *_PlexServerPort;
    NSString *_PlexServerPath;
    VLCPlexParser *_PlexParser;
}
@end

@implementation VLCPlexMediaInformationViewController

- (id)initPlexMediaInformation:(NSMutableArray *)mediaInformation serverAddress:(NSString *)serverAddress portNumber:(NSString *)portNumber atPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _mutableMediaInformation = [[NSMutableArray alloc] init];
        [_mutableMediaInformation addObjectsFromArray:mediaInformation];
        _PlexServerAddress = serverAddress;
        _PlexServerPort = portNumber;
        _PlexServerPath = path;
        _PlexParser = [[VLCPlexParser alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor VLCDarkBackgroundColor]];
    [self.summary setBackgroundColor:[UIColor VLCDarkBackgroundColor]];
    self.automaticallyAdjustsScrollViewInsets = NO;

    NSString *title = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"title"];
    NSString *thumbPath = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"thumb"];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:thumbPath]]];
    NSInteger size = [[[_mutableMediaInformation objectAtIndex:0] objectForKey:@"size"] integerValue];
    NSString *mediaSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
    NSString *durationInSeconds = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"duration"];
    NSString *displaySize = [NSString stringWithFormat:@"%@ (%@)", mediaSize, durationInSeconds];
    NSString *tag = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"state"];
    NSString *displaySummary = [NSString stringWithFormat:@"%@", [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"summary"]];

    NSString *audioCodec = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"audioCodec"];
    if (!audioCodec)
        audioCodec = @"no track";

    NSString *videoCodec = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"videoCodec"];
    if (!videoCodec)
        videoCodec = @"no track";

    NSString *displayCodec = [NSString stringWithFormat:@"audio(%@) video(%@)", audioCodec, videoCodec];

    NSString *grandparentTitle = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"grandparentTitle"];
    if (grandparentTitle)
        self.title = grandparentTitle;

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Specifics

- (void)_playMediaItem:(NSMutableArray *)mutableMediaObject
{
    NSString *newPath = nil;
    NSString *keyValue = [[mutableMediaObject objectAtIndex:0] objectForKey:@"key"];

    if ([keyValue rangeOfString:@"library"].location == NSNotFound)
        newPath = [_PlexServerPath stringByAppendingPathComponent:keyValue];
    else
        newPath = keyValue;

    if ([[[mutableMediaObject objectAtIndex:0] objectForKey:@"container"] isEqualToString:@"item"]) {
        [mutableMediaObject removeAllObjects];
        mutableMediaObject = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:newPath];
        NSString *URLofSubtitle = nil;
        if ([[mutableMediaObject objectAtIndex:0] objectForKey:@"keySubtitle"])
            URLofSubtitle = [_PlexParser getFileSubtitleFromPlexServer:mutableMediaObject modeStream:YES];

        NSURL *itemURL = [NSURL URLWithString:[[mutableMediaObject objectAtIndex:0] objectForKey:@"keyMedia"]];
        if (itemURL) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate openMovieWithExternalSubtitleFromURL:itemURL externalSubURL:URLofSubtitle];
        }
    }
}

- (void)_download:(NSMutableArray *)mutableMediaObject
{
    NSString *path = [[mutableMediaObject objectAtIndex:0] objectForKey:@"key"];
    [mutableMediaObject removeAllObjects];
    mutableMediaObject = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:path];

    NSInteger size = [[[mutableMediaObject objectAtIndex:0] objectForKey:@"size"] integerValue];
    if (size  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        if ([[mutableMediaObject objectAtIndex:0] objectForKey:@"keySubtitle"])
            [_PlexParser getFileSubtitleFromPlexServer:mutableMediaObject modeStream:NO];

        [self _downloadFileFromMediaItem:mutableMediaObject];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [[mutableMediaObject objectAtIndex:0] objectForKey:@"title"], [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)_downloadFileFromMediaItem:(NSMutableArray *)mutableMediaObject
{
    NSURL *itemURL = [NSURL URLWithString:[[mutableMediaObject objectAtIndex:0] objectForKey:@"keyMedia"]];

    if (![[itemURL absoluteString] isSupportedFormat]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [itemURL absoluteString]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
        [alert show];
    } else if (itemURL) {
        NSString *fileName = [[mutableMediaObject objectAtIndex:0] objectForKey:@"namefile"];
        [[(VLCAppDelegate *)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:itemURL fileNameOfMedia:fileName];
    }
}

#pragma mark - Action

- (IBAction)play:(id)sender
{
    [self _playMediaItem:_mutableMediaInformation];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)download:(id)sender
{
    [self _download:_mutableMediaInformation];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)markMedia:(id)sender
{
    NSString *ratingKey = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"ratingKey"];
    NSString *tag = [[_mutableMediaInformation objectAtIndex:0] objectForKey:@"state"];

    NSInteger status = [_PlexParser MarkWatchedUnwatchedMedia:_PlexServerAddress port:_PlexServerPort videoRatingKey:ratingKey state:tag];
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

    [[_mutableMediaInformation objectAtIndex:0] setObject:tag forKey:@"state"];
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