/*****************************************************************************
 * VLCWiFiUploadTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self.reachability stopNotifier];
}

+ (NSString *)cellIdentifier
{
    return @"VLCWiFiUploadTableViewCell";
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
    self.backgroundColor = [UIColor VLCMenuBackgroundColor];
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

    self.serverOnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.serverOnButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.serverOnButton addTarget:self action:@selector(toggleHTTPServer) forControlEvents:UIControlEventTouchUpInside];
    [self.serverOnButton setImage:[UIImage imageNamed:@"WiFiUp"] forState:UIControlStateDisabled];
    [self.contentView addSubview:self.serverOnButton];
}

- (void)setupConstraints
{
    UIView *spacer1 = [UIView new];
    UIView *spacer2 = [UIView new];
    UIView *spacer3 = [UIView new];
    UIView *spacer4 = [UIView new];
    spacer1.translatesAutoresizingMaskIntoConstraints = NO;
    spacer2.translatesAutoresizingMaskIntoConstraints = NO;
    spacer3.translatesAutoresizingMaskIntoConstraints = NO;
    spacer4.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:spacer1];
    [self.contentView addSubview:spacer2];
    [self.contentView addSubview:spacer3];
    [self.contentView addSubview:spacer4];

    NSDictionary *dict = NSDictionaryOfVariableBindings(_titleLabel, _uploadAddressLabel, _serverOnButton, spacer1, spacer2, spacer3, spacer4);
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_serverOnButton(50)]-==8-[_titleLabel]" options:0 metrics:0 views:dict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_serverOnButton(50)]-==8-[_uploadAddressLabel]" options:0 metrics:0 views:dict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[spacer1][_titleLabel]-==0-[_uploadAddressLabel(>=0)][spacer2(==spacer1)]|" options:0 metrics:0 views:dict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[spacer3][_serverOnButton(50)][spacer4]|" options:0 metrics:0 views:dict]];
}

- (void)netReachabilityChanged
{
    [self updateHTTPServerAddress];
}

- (void)updateHTTPServerAddress
{
    [self.serverOnButton setImage:[UIImage imageNamed:@"WifiUp"] forState:UIControlStateNormal];
    
    BOOL connectedViaWifi = [[VLCHTTPUploaderController sharedInstance] isReachable];
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
