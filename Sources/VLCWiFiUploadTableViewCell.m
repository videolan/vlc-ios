/*****************************************************************************
 * VLCWiFiUploadTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCWiFiUploadTableViewCell.h"
#import "Reachability.h"
#import "VLCHTTPUploaderController.h"

@interface VLCWiFiUploadTableViewCell()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *uploadAddressLabel;
@property (nonatomic, strong) UIButton *serverOnButton;
@property (nonatomic, strong) Reachability *reachability;

@end

@implementation VLCWiFiUploadTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupCell];
        [self setupConstraints];
        [self updateHTTPServerAddress];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self.reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupCell
{
    self.reachability = [Reachability reachabilityForLocalWiFi];
    [self.reachability startNotifier];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];
    self.titleLabel.text = NSLocalizedString(@"WEBINTF_TITLE", nil);
    self.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.titleLabel.shadowColor = [UIColor VLCDarkTextShadowColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:16.0];
    self.titleLabel.superview.backgroundColor = [UIColor colorWithRed:(43.0f/255.0f) green:(43.0f/255.0f) blue:(43.0f/255.0f) alpha:1.0f];
    [self.titleLabel sizeToFit];

    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle =  UITableViewCellSelectionStyleNone;

    self.uploadAddressLabel = [UILabel new];
    self.uploadAddressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.uploadAddressLabel.numberOfLines = 0;
    [self.contentView addSubview:self.uploadAddressLabel];
    self.uploadAddressLabel.text = NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", nil);
    self.uploadAddressLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.uploadAddressLabel.shadowColor = [UIColor VLCDarkTextShadowColor];
    self.uploadAddressLabel.textColor = [UIColor whiteColor];
    self.uploadAddressLabel.font = [UIFont systemFontOfSize:12.0];
    [self.uploadAddressLabel sizeToFit];

    self.serverOnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.serverOnButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.serverOnButton addTarget:self action:@selector(toggleHTTPServer) forControlEvents:UIControlEventTouchUpInside];
    [self.serverOnButton setImage:[UIImage imageNamed:@"WiFiUp"] forState:UIControlStateDisabled];
    [self.contentView addSubview:self.serverOnButton];
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
    topLine.backgroundColor = [UIColor colorWithRed:(16.0f/255.0f) green:(16.0f/255.0f) blue:(16.0f/255.0f) alpha:1.0f];
    [self.contentView addSubview:topLine];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 50.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(23.0f/255.0f) green:(23.0f/255.0f) blue:(23.0f/255.0f) alpha:1.0f];
    [self.contentView addSubview:bottomLine];
}

- (void)setupConstraints
{
    NSDictionary *dict = NSDictionaryOfVariableBindings(_titleLabel, _uploadAddressLabel, _serverOnButton);
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_serverOnButton(50)][_titleLabel]" options:0 metrics:0 views:dict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_serverOnButton(50)][_uploadAddressLabel]" options:0 metrics:0 views:dict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_serverOnButton(50)]|" options:0 metrics:0 views:dict]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_uploadAddressLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

- (void)netReachabilityChanged
{
    [self updateHTTPServerAddress];
}

- (void)updateHTTPServerAddress
{
    [self.serverOnButton setImage:[UIImage imageNamed:@"WifiUp"] forState:UIControlStateNormal];
    
    BOOL connectedViaWifi = self.reachability.currentReachabilityStatus == ReachableViaWiFi;
    self.serverOnButton.enabled = connectedViaWifi;
    NSString *uploadText = connectedViaWifi ? [[VLCHTTPUploaderController sharedInstance] httpStatus] : NSLocalizedString(@"HTTP_UPLOAD_NO_CONNECTIVITY", nil);
    self.uploadAddressLabel.text = uploadText;
    if (connectedViaWifi && [VLCHTTPUploaderController sharedInstance].isServerRunning) {
        [self.serverOnButton setImage:[UIImage imageNamed:@"WifiUpOn"] forState:UIControlStateNormal];
    }
}

- (void)toggleHTTPServer
{
    BOOL futureHTTPServerState = ![VLCHTTPUploaderController sharedInstance].isServerRunning ;
    [[NSUserDefaults standardUserDefaults] setBool:futureHTTPServerState forKey:kVLCSettingSaveHTTPUploadServerStatus];
    [[VLCHTTPUploaderController sharedInstance] changeHTTPServerState:futureHTTPServerState];
    [self updateHTTPServerAddress];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
