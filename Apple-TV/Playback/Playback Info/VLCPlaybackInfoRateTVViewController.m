/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoRateTVViewController.h"
@interface VLCPlaybackInfoRateTVViewController ()
@property (nonatomic) NSArray<NSNumber*> *possibleRates;
@end

@implementation VLCPlaybackInfoRateTVViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"PLAYBACK_SPEED", nil);
    }
    return self;
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 100);
}

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackController *)vpc
{
    return vpc.mediaPlayer.isSeekable;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.possibleRates = @[@(0.25),
                           @(0.50),
                           @(0.75),
                           @(1.00),
                           @(1.25),
                           @(1.50),
                           @(2.00),
                           @(4.00),
                           ];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 2;
    formatter.minimumFractionDigits = 2;

    UISegmentedControl *segmentedControl = self.segmentedControl;
    [segmentedControl removeAllSegments];

    [self.possibleRates enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = [formatter stringFromNumber:obj];
        [segmentedControl insertSegmentWithTitle:title atIndex:idx animated:NO];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateSegmentedControl];
}

- (void)updateSegmentedControl
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    float currentRate = vpc.playbackRate;

    NSInteger currentIndex = [self.possibleRates indexOfObjectPassingTest:^BOOL(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return ABS(obj.floatValue-currentRate)<0.2;
    }];
    self.segmentedControl.selectedSegmentIndex = currentIndex;

    self.segmentedControl.enabled = vpc.mediaPlayer.isSeekable;
}

- (IBAction)segmentedControlChanged:(UISegmentedControl *)sender
{
    float newRate = self.possibleRates[sender.selectedSegmentIndex].floatValue;
    [VLCPlaybackController sharedInstance].playbackRate = newRate;
}
@end
