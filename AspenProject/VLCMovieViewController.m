//
//  VLCMovieViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCMovieViewController.h"

@interface VLCMovieViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation VLCMovieViewController
@synthesize movieView=_movieView;

- (void)dealloc
{
    [_mediaItem release];
    [_masterPopoverController release];
    [super dealloc];
}

#pragma mark - Managing the media item

- (void)setMediaItem:(id)newMediaItem
{
    if (_mediaItem != newMediaItem) {
        [_mediaItem release];
        _mediaItem = [newMediaItem retain];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [super viewDidLoad];
    _mediaPlayer = [[VLCMediaPlayer alloc] init];
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:self.movieView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.mediaItem) {
        self.title = [self.mediaItem title];

        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.mediaItem.url]]];
        if (self.mediaItem.lastPosition && [self.mediaItem.lastPosition floatValue] < 0.99)
            [_mediaPlayer setPosition:[self.mediaItem.lastPosition floatValue]];
        [_mediaPlayer play];

        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_mediaPlayer pause];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Video Playback";
    }
    return self;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
