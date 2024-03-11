/*****************************************************************************
 * VLCDonationPayPalViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDonationPayPalViewController.h"
#import <WebKit/WebKit.h>

@interface VLCDonationPayPalViewController ()
{
    WKWebView *_webView;
    int _donationAmount;
    NSString *_currencyCode;
}

@end

@implementation VLCDonationPayPalViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:[[WKWebViewConfiguration alloc] init]];
    [self.view addSubview:_webView];

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDonation:)]];
}

- (void)cancelDonation:(id)sender
{
    [_webView stopLoading];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATION_WINDOW_TITLE", nil);
}

- (void)setDonationAmount:(int)donationAmount
{
    _donationAmount = donationAmount;
}

- (void)setCurrencyCode:(NSString *)isoCode
{
    _currencyCode = isoCode;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSURL *url = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";

    NSLocale *currentLocale = [NSLocale currentLocale];

    NSString *formData = @"cmd=_xclick&business=sponsor@videolan.org&item_name=VideoLAN&currency_code=%@&tax=0&lc=%@&no_shipping=1&return=https://www.videolan.org/thank_you.html&amount=%i";
    formData = [NSString stringWithFormat:formData, _currencyCode, [currentLocale objectForKey:NSLocaleLanguageCode], _donationAmount];

    NSData *httpBody = [formData dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:httpBody];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    [_webView loadRequest:request];
}

@end
