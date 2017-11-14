/*****************************************************************************
 * VLCAboutViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAboutViewController.h"

@interface VLCAboutViewController ()
{
    UIWebView *_webView;
}

@end

@implementation VLCAboutViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    _webView.clipsToBounds = YES;
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_webView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title"]];

    UIBarButtonItem *contributeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CONTRIBUTE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(openContributePage:)];
    contributeButton.tintColor = [UIColor whiteColor];

    self.navigationItem.rightBarButtonItem = contributeButton;
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSMutableString *htmlContent = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [htmlContent replaceOccurrencesOfString:@"VLCFORIOSVERSION" withString:[[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT", nil), [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] stringByAppendingFormat:@" (%@)<br /><i>%@</i>", [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"], kVLCVersionCodename] options:NSLiteralSearch range:NSMakeRange(800, 1000)];
    [htmlContent replaceOccurrencesOfString:@"MOBILEVLCKITVERSION" withString:[NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT", nil),[[VLCLibrary sharedLibrary] version]] options:NSLiteralSearch range:NSMakeRange(800, 1100)];
    [_webView loadHTMLString:[NSString stringWithString:htmlContent] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    htmlContent = nil;
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)goBack:(id)sender
{
    [[VLCSidebarController sharedInstance] toggleSidebar];
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
    _webView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _webView.opaque = YES;
}

- (IBAction)openContributePage:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videolan.org/contribute.html"]];
}

@end
