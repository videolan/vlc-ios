/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *        Felix Paul Kühne <fkuehne # videolan.org>
 *        Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoPlaybackTVViewController.h"

@interface VLCPlaybackInfoPlaybackTVViewController ()
@property (nonatomic) VLCPlaybackService *playbackService;
@property (nonatomic, readwrite) VLCPlaybackOptionsType currentOption;

@property (nonatomic, readonly) CGFloat increaseDelay;
@property (nonatomic, readonly) CGFloat decreaseDelay;
@property (nonatomic, readonly) CGFloat increaseSpeed;
@property (nonatomic, readonly) CGFloat decreaseSpeed;

@property (nonatomic, readonly) CGFloat defaultDelay;
@property (nonatomic, readonly) CGFloat defaultSpeed;

@property (nonatomic, readwrite) CGFloat currentSubtitlesDelay;
@property (nonatomic, readwrite) CGFloat currentAudioDelay;
@property (nonatomic, readwrite) CGFloat currentSpeed;
@end

@implementation VLCPlaybackInfoPlaybackTVViewController

// MARK: - Init

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"PLAYBACK", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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

    _playbackService = [VLCPlaybackService sharedInstance];
    _currentOption = VLCPlaybackOptionsTypeNone;

    _increaseDelay = 50.0;
    _decreaseDelay = -50.0;
    _increaseSpeed = 0.05;
    _decreaseSpeed = -0.05;

    _defaultDelay = 0.0;
    _defaultSpeed = [[[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackSpeedDefaultValue] doubleValue];

    [_increaseButton setTitle:@"" forState:UIControlStateNormal];
    [_decreaseButton setTitle:@"" forState:UIControlStateNormal];
    [_resetButton setTitle:NSLocalizedString(@"BUTTON_RESET", "") forState:UIControlStateNormal];

    _playbackSpeedButton.accessibilityHint = NSLocalizedString(@"PLAYBACK_SPEED_HINT", "");
    _subtitlesDelayButton.accessibilityHint = NSLocalizedString(@"SUBTITLES_DELAY_HINT", "");
    _audioDelayButton.accessibilityHint = NSLocalizedString(@"AUDIO_DELAY_HINT", "");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRepeatControl];
    [self updateShuffleControl];
    [self updateButtonsText];
    [_subtitlesDelayView setHidden:_playbackService.metadata.isAudioOnly];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _currentOption = VLCPlaybackOptionsTypeNone;
    [_valueSelectorView setHidden:YES];
    [_optionsStackView setHidden:NO];
}

// MARK: - Override methods

- (CGSize)preferredContentSize
{
    CGFloat height = _playbackSpeedButton.frame.size.height + _subtitlesDelayButton.frame.size.height + _audioDelayButton.frame.size.height +
                        _repeatControl.frame.size.height + _shuffleControl.frame.size.height + (5 * CONTENT_INSET);

    if (height < MINIMAL_CONTENT_SIZE) {
        height = MINIMAL_CONTENT_SIZE;
    }

    return CGSizeMake(CGRectGetWidth(self.view.bounds), height);
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    if (!_optionsStackView.isHidden) {
        return @[_playbackSpeedButton];
    }

    return @[_increaseButton];
}

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackService *)vpc
{
    return [vpc isSeekable];
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    // Hide the value selector view if needed when the return button is pressed
    if (((UIPress *)[presses anyObject]).type == UIPressTypeMenu && !_valueSelectorView.isHidden) {
        [self updateButtonsText];
        [_valueSelectorView setHidden:YES];
        [_optionsStackView setHidden:NO];
    } else {
        [super pressesBegan:presses withEvent:event];
    }
}

// MARK: - Helper methods

- (void)updateRepeatControl
{
    NSUInteger selectedIndex;
    VLCRepeatMode repeatMode = _playbackService.repeatMode;
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

- (void)updateShuffleControl
{
    _shuffleControl.selectedSegmentIndex = _playbackService.shuffleMode;
}

- (void)setupAccessibilityWith:(NSString *)increaseHint and:(NSString *)decreaseHint
{
    _increaseButton.accessibilityLabel = NSLocalizedString(@"INCREASE_BUTTON", "");
    _increaseButton.accessibilityHint = increaseHint;

    _decreaseButton.accessibilityLabel = NSLocalizedString(@"DECREASE_BUTTON", "");
    _decreaseButton.accessibilityHint = decreaseHint;
}

- (void)updateButtonsText
{
    [_playbackSpeedButton setTitle:[NSString stringWithFormat:@"%.2fx", _playbackService.playbackRate] forState:UIControlStateNormal];
    [_subtitlesDelayButton setTitle:[NSString stringWithFormat:@"%.0f ms", _playbackService.subtitleDelay] forState:UIControlStateNormal];
    [_audioDelayButton setTitle:[NSString stringWithFormat:@"%.0f ms", _playbackService.audioDelay] forState:UIControlStateNormal];
}

- (CGFloat)computeValueWith:(CGFloat)currentValue offset:(CGFloat)offset lowerBound:(CGFloat)lowerBound upperBound:(CGFloat)upperBound
{
    CGFloat returnValue = currentValue + offset;
    if (returnValue >= lowerBound && returnValue <= upperBound) {
        return returnValue;
    }

    return offset < 0 ? lowerBound : upperBound;
}

- (void)updateValueLabelWith:(CGFloat)value
{
    switch (_currentOption) {
        case VLCPlaybackOptionsTypePlaybackSpeed:
            [_valueLabel setText:[NSString stringWithFormat:@"%.2fx", value]];
            break;
        case VLCPlaybackOptionsTypeSubtitlesDelay:
        case VLCPlaybackOptionsTypeAudioDelay:
            [_valueLabel setText:[NSString stringWithFormat:@"%.0f ms", value]];
            break;
        default:
            break;
    }
}

// MARK: - Sender methods

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

    _playbackService.repeatMode = repeatMode;
}

- (IBAction)shuffleControlChanged:(UISegmentedControl *)sender
{
    _playbackService.shuffleMode = sender.selectedSegmentIndex == 1;
}

- (IBAction)handleIncreaseDecrease:(UIButton *)sender {
    CGFloat speedOffset = (sender.tag == 1) ? _increaseSpeed : _decreaseSpeed;
    CGFloat delayOffset = (sender.tag == 1) ? _increaseDelay : _decreaseDelay;
    CGFloat value = 0.0;

    switch (_currentOption) {
        case VLCPlaybackOptionsTypePlaybackSpeed:
            _currentSpeed = [self computeValueWith:_currentSpeed offset:speedOffset lowerBound:MIN_SPEED upperBound:MAX_SPEED];
            _playbackService.playbackRate = _currentSpeed;
            value = _currentSpeed;
            break;
        case VLCPlaybackOptionsTypeSubtitlesDelay:
            _currentSubtitlesDelay = [self computeValueWith:_currentSubtitlesDelay offset:delayOffset lowerBound:MIN_DELAY upperBound:MAX_DELAY];
            _playbackService.subtitleDelay = _currentSubtitlesDelay;
            value = _currentSubtitlesDelay;
            break;
        case VLCPlaybackOptionsTypeAudioDelay:
            _currentAudioDelay = [self computeValueWith:_currentAudioDelay offset:delayOffset lowerBound:MIN_DELAY upperBound:MAX_DELAY];
            _playbackService.audioDelay = _currentAudioDelay;
            value = _currentAudioDelay;
            break;
        default:
            break;
    }

    [self updateValueLabelWith:value];
}

- (IBAction)handlePlaybackSpeed:(UIButton *)sender {
    _currentSpeed = _playbackService.playbackRate;
    _currentOption = VLCPlaybackOptionsTypePlaybackSpeed;
    [_titleLabel setText:NSLocalizedString(@"PLAYBACK_SPEED", "")];
    [self updateValueLabelWith:_currentSpeed];

    [self setupAccessibilityWith:NSLocalizedString(@"INCREASE_PLAYBACK_SPEED", "")
                             and:NSLocalizedString(@"DECREASE_PLAYBACK_SPEED", "")];

    [_optionsStackView setHidden:YES];
    [_valueSelectorView setHidden:NO];
}

- (IBAction)handleSubtitlesDelay:(UIButton *)sender {
    _currentSubtitlesDelay = _playbackService.subtitleDelay;
    _currentOption = VLCPlaybackOptionsTypeSubtitlesDelay;
    [_titleLabel setText:NSLocalizedString(@"SPU_DELAY", "")];
    [self updateValueLabelWith:_currentSubtitlesDelay];

    [self setupAccessibilityWith:NSLocalizedString(@"INCREASE_SUBTITLES_DELAY", "")
                             and:NSLocalizedString(@"DECREASE_SUBTITLES_DELAY", "")];

    [_optionsStackView setHidden:YES];
    [_valueSelectorView setHidden:NO];
}

- (IBAction)handleAudioDelay:(UIButton *)sender {
    _currentAudioDelay = _playbackService.audioDelay;
    _currentOption = VLCPlaybackOptionsTypeAudioDelay;
    [_titleLabel setText:NSLocalizedString(@"AUDIO_DELAY", "")];
    [self updateValueLabelWith:_currentAudioDelay];

    [self setupAccessibilityWith:NSLocalizedString(@"INCREASE_AUDIO_DELAY", "")
                             and:NSLocalizedString(@"DECREASE_AUDIO_DELAY", "")];

    [_optionsStackView setHidden:YES];
    [_valueSelectorView setHidden:NO];
}

- (IBAction)handleResetButton:(UIButton *)sender {
    CGFloat value = 0.0;

    switch (_currentOption) {
        case VLCPlaybackOptionsTypePlaybackSpeed:
            _currentSpeed = _defaultSpeed;
            _playbackService.playbackRate = _currentSpeed;
            value = _currentSpeed;
            break;
        case VLCPlaybackOptionsTypeSubtitlesDelay:
            _currentSubtitlesDelay = _defaultDelay;
            _playbackService.subtitleDelay = _currentSubtitlesDelay;
            value = _currentSubtitlesDelay;
            break;
        case VLCPlaybackOptionsTypeAudioDelay:
            _currentAudioDelay = _defaultDelay;
            _playbackService.audioDelay = _currentAudioDelay;
            value = _currentAudioDelay;
            break;
        default:
            break;
    }

    [self updateValueLabelWith:value];
}

@end
