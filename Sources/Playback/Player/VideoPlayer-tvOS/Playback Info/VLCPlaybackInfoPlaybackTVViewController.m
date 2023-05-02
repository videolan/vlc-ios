/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *        Felix Paul Kühne <fkuehne # videolan.org>
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
    CGFloat height = _rateControl.frame.size.height + _repeatControl.frame.size.height + _shuffleControl.frame.size.height + (3 * CONTENT_INSET);

    if (height < MINIMAL_CONTENT_SIZE) {
        height = MINIMAL_CONTENT_SIZE;
    }

    return CGSizeMake(CGRectGetWidth(self.view.bounds), height);
}

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackService *)vpc
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

    UISegmentedControl *shuffleControl = self.shuffleControl;
    [shuffleControl removeAllSegments];
    [shuffleControl insertSegmentWithTitle:NSLocalizedString(@"OFF", nil)
                                  atIndex:0 animated:NO];
    [shuffleControl insertSegmentWithTitle:NSLocalizedString(@"ON", nil)
                                  atIndex:1 animated:NO];
    self.shuffleLabel.text = NSLocalizedString(@"SHUFFLE", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRateControl];
    [self updateRepeatControl];
    [self updateShuffleControl];
}

- (void)updateRateControl
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
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
    [VLCPlaybackService sharedInstance].playbackRate = newRate;
}

- (void)updateRepeatControl
{
    NSUInteger selectedIndex;
    VLCRepeatMode repeatMode = [VLCPlaybackService sharedInstance].repeatMode;
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

- (IBAction)repeatControlChanged:(UISegmentedControl *)sender
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

    [VLCPlaybackService sharedInstance].repeatMode = repeatMode;
}

- (void)updateShuffleControl
{
    self.shuffleControl.selectedSegmentIndex = [VLCPlaybackService sharedInstance].shuffleMode;
}

- (IBAction)shuffleControlChanged:(UISegmentedControl *)sender
{
    [VLCPlaybackService sharedInstance].shuffleMode = sender.selectedSegmentIndex == 1;
}

@end
