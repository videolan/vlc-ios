/*****************************************************************************
 * VLCBrowseSharingCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBrowseSharingCell.h"
#import "VLCHTTPUploaderController.h"
#import "VLCAppCoordinator.h"
#import "Reachability.h"

#import "VLC-Swift.h"

static CGFloat const kVLCBrowseSharingCornerRadius = 14.0;

@implementation VLCBrowseSharingCell
{
    UISwitch *_serverSwitch;
    UILabel *_titleLabel;
    Reachability *_reachability;
    VLCHTTPUploaderController *_httpUploaderController;
    NSUserActivity *_userActivity;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCBrowseSharingCell";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _httpUploaderController = [[VLCAppCoordinator sharedInstance] httpUploaderController];
        _reachability = [Reachability reachabilityForLocalWiFi];
        [_reachability startNotifier];

        [self setupViews];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateState)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [_reachability stopNotifier];
}

- (void)setupViews
{
    [self.contentView roundCornersWithRadius:kVLCBrowseSharingCornerRadius];

    _serverSwitch = [[UISwitch alloc] init];
    _serverSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [_serverSwitch addTarget:self action:@selector(toggleSharing) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_serverSwitch];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _titleLabel.numberOfLines = 2;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.8;
    [self.contentView addSubview:_titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_serverSwitch.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:6.0],
        [_serverSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

        [_titleLabel.leadingAnchor constraintEqualToAnchor:_serverSwitch.trailingAnchor constant:10.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12.0],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_titleLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [_titleLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-6.0]
    ]];
}

- (BOOL)isSharingEnabled
{
    return _httpUploaderController.isReachable && _httpUploaderController.isServerRunning;
}

- (void)configureJoinedToBand:(BOOL)joined
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    self.contentView.backgroundColor = themeColors.accentTint;
    _serverSwitch.onTintColor = themeColors.orangeUI;
    _titleLabel.textColor = themeColors.cellTextColor;

    CACornerMask maskedCorners = joined ? kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner
                                        : kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                                          kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.contentView roundCornersWithRadius:kVLCBrowseSharingCornerRadius maskedCorners:maskedCorners];

    [self updateState];
}

- (void)updateState
{
    BOOL reachable = _httpUploaderController.isReachable;
    _serverSwitch.enabled = reachable;
    _serverSwitch.on = reachable && _httpUploaderController.isServerRunning;

    _titleLabel.text = _httpUploaderController.isUsingEthernet ? NSLocalizedString(@"WEBINTF_ETHERNET", nil)
                                                               : NSLocalizedString(@"BROWSE_WIFI_SHARING", nil);

    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityLabel = _titleLabel.text;

    _serverSwitch.on ? [self startHandoff] : [self stopHandoff];
}

- (void)toggleSharing
{
    if (!_httpUploaderController.isReachable) {
        return;
    }

    BOOL futureHTTPServerState = !_httpUploaderController.isServerRunning;
    [[NSUserDefaults standardUserDefaults] setBool:futureHTTPServerState forKey:kVLCSettingSaveHTTPUploadServerStatus];
    [_httpUploaderController changeHTTPServerState:futureHTTPServerState];

    [self updateState];
    [self.delegate sharingCellDidChangeState:self];
}

- (void)startHandoff
{
    NSString *address = [_httpUploaderController addressToCopy];
    if (address.length == 0) {
        return;
    }

    _userActivity = [[NSUserActivity alloc] initWithActivityType:[[NSBundle mainBundle] bundleIdentifier]];
    _userActivity.webpageURL = [NSURL URLWithString:address];
    _userActivity.eligibleForSearch = YES;
    _userActivity.eligibleForPublicIndexing = YES;
    _userActivity.eligibleForHandoff = YES;
    [_userActivity becomeCurrent];
}

- (void)stopHandoff
{
    [_userActivity invalidate];
    _userActivity = nil;
}

@end
