/*****************************************************************************
 * VLCAboutViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAboutViewController.h"
#import "VLCAppDelegate.h"
#import "UIBarButtonItem+Theme.h"

@implementation VLCAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title"]];

    UIBarButtonItem *contributeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CONTRIBUTE",@"") style:UIBarButtonItemStyleBordered target:self action:@selector(openContributePage:)];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        contributeButton.tintColor = [UIColor whiteColor];
    else {
        [contributeButton setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [contributeButton setBackgroundImage:[UIImage imageNamed:@"buttonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    }

    self.navigationItem.rightBarButtonItem = contributeButton;
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];

    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.webView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    NSMutableString *htmlContent = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [htmlContent replaceOccurrencesOfString:@"VLCFORIOSVERSION" withString:[[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT",@""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] stringByAppendingFormat:@"<br /><i>%@</i>", kVLCVersionCodename] options:NSLiteralSearch range:NSMakeRange(800, 1000)];
    [htmlContent replaceOccurrencesOfString:@"MOBILEVLCKITVERSION" withString:[NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT",@""),[[VLCLibrary sharedLibrary] version]] options:NSLiteralSearch range:NSMakeRange(800, 1100)];
    [self.webView loadHTMLString:[NSString stringWithString:htmlContent] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    htmlContent = nil;
    self.webView.delegate = self;
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
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
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

    [UIView animateWithDuration:.3 animations:animationBlock completion:completionBlock];
}

- (IBAction)openContributePage:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videolan.org/contribute.html"]];
}

@end
