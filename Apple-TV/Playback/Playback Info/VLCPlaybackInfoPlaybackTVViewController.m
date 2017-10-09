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

#import "VLCPlaybackInfoPlaybackTVViewController.h"
@interface VLCPlaybackInfoPlaybackTVViewController ()
@property (nonatomic) NSArray<NSNumber*> *possibleRates;
@end

@implementation VLCPlaybackInfoPlaybackTVViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"PLAYBACK", nil);
    }
    return self;
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 200);
}

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackController *)vpc
{
    return [vpc isSeekable];
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

    UISegmentedControl *rateControl = self.rateControl;
    [rateControl removeAllSegments];

    [self.possibleRates enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = [formatter stringFromNumber:obj];
        [rateControl insertSegmentWithTitle:title atIndex:idx animated:NO];
    }];

    self.rateLabel.text = NSLocalizedString(@"PLAYBACK_SPEED", nil);

    UISegmentedControl *repeatControl = self.repeatControl;
    [repeatControl removeAllSegments];
    [repeatControl insertSegmentWithTitle:NSLocalizedString(@"REPEAT_DISABLED", nil)
                                  atIndex:0 animated:NO];
    [repeatControl insertSegmentWithTitle:NSLocalizedString(@"REPEAT_SINGLE", nil)
                                  atIndex:1 animated:NO];
    [repeatControl insertSegmentWithTitle:NSLocalizedString(@"REPEAT_FOLDER", nil)
                                  atIndex:2 animated:NO];

    self.repeatLabel.text = NSLocalizedString(@"REPEAT_MODE", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRateControl];
    [self updateRepeatControl];
}

- (void)updateRateControl
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    float currentRate = vpc.playbackRate;

    NSInteger currentIndex = [self.possibleRates indexOfObjectPassingTest:^BOOL(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return ABS(obj.floatValue-currentRate)<0.2;
    }];
    UISegmentedControl *rateControl = self.rateControl;
    rateControl.selectedSegmentIndex = currentIndex;
    rateControl.enabled = [vpc isSeekable];
}

- (IBAction)rateControlChanged:(UISegmentedControl *)sender
{
    float newRate = self.possibleRates[sender.selectedSegmentIndex].floatValue;
    [VLCPlaybackController sharedInstance].playbackRate = newRate;
}

- (void)updateRepeatControl
{
    NSUInteger selectedIndex;
    VLCRepeatMode repeatMode = [VLCPlaybackController sharedInstance].repeatMode;
    switch (repeatMode) {
        case VLCRepeatCurrentItem:
            selectedIndex = 1;
            break;
        case VLCRepeatAllItems:
            selectedIndex = 2;
            break;
        case VLCDoNotRepeat:
        default:
            selectedIndex = 0;
            break;
    }

    self.repeatControl.selectedSegmentIndex = selectedIndex;
}

-(IBAction)repeatControlChanged:(UISegmentedControl *)sender
{
    VLCRepeatMode repeatMode;
    switch (sender.selectedSegmentIndex) {
        case 1:
            repeatMode = VLCRepeatCurrentItem;
            break;
        case 2:
            repeatMode = VLCRepeatAllItems;
            break;
        case 0:
        default:
            repeatMode = VLCDoNotRepeat;
            break;
    }

    [VLCPlaybackController sharedInstance].repeatMode = repeatMode;
}

@end
