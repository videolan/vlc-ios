//
//  VLCAboutViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 07.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCAboutViewController.h"
#import "UIBarButtonItem+Theme.h"

@implementation VLCAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"ABOUT_APP", @"");
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil] baseURL:nil];
    self.webView.delegate = self;
    self.aspenVersion.text = [[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT",@""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] stringByAppendingFormat:@" %@", kVLCVersionCodename];
    self.vlckitVersion.text = [NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT",@""),[[VLCLibrary sharedLibrary] version]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *requestURL = request.URL;
    if (![requestURL.scheme isEqualToString:@""])
        return ![[UIApplication sharedApplication] openURL:requestURL];
    else
        return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    webView.alpha = 0.;
    CGFloat alpha = 1.;

    void (^animationBlock)() = ^() {
        webView.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        webView.hidden = NO;
    };

    [UIView animateWithDuration:1. animations:animationBlock completion:completionBlock];
}

@end
