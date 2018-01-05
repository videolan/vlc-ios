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
#import "VLC_iOS-Swift.h"

@interface VLCAboutViewController ()
{
    UIWebView *_webView;
}

@end

@implementation VLCAboutViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    _webView.clipsToBounds = YES;
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_webView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title"]];

    UIBarButtonItem *contributeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CONTRIBUTE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(openContributePage:)];
    contributeButton.tintColor = [UIColor whiteColor];

    self.navigationItem.rightBarButtonItem = contributeButton;
    [self loadWebContent];
}

- (void)loadWebContent
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *textColor = PresentationTheme.current.colors.cellTextColor.toHex;
    NSString *backgroundColor = PresentationTheme.current.colors.background.toHex;
    NSString *version = [NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT", nil), [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *versionBuildNumberAndCodeName = [version stringByAppendingFormat:@" (%@)<br /><i>%@</i>", [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"], kVLCVersionCodename];
    NSString *vlcLibraryVersion = [NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT", nil),[[VLCLibrary sharedLibrary] version]];
    NSString *htmlFilePath = [mainBundle pathForResource:@"About Contents" ofType:@"html"];
    NSMutableString *htmlContent = [NSMutableString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil];
    [htmlContent replaceOccurrencesOfString:@"VLCFORIOSVERSION" withString:versionBuildNumberAndCodeName options:NSLiteralSearch range:NSMakeRange(0, [htmlContent length])];
    [htmlContent replaceOccurrencesOfString:@"TEXTCOLOR" withString:textColor options:NSLiteralSearch range:NSMakeRange(0, [htmlContent length])];
    [htmlContent replaceOccurrencesOfString:@"BACKGROUNDCOLOR" withString:backgroundColor options:NSLiteralSearch range:NSMakeRange(0, [htmlContent length])];
    [htmlContent replaceOccurrencesOfString:@"MOBILEVLCKITVERSION" withString:vlcLibraryVersion options:NSLiteralSearch range:NSMakeRange(0, [htmlContent length])];
    [_webView loadHTMLString:htmlContent baseURL:[NSURL fileURLWithPath:[mainBundle bundlePath]]];
}

- (void)themeDidChange
{
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    _webView.backgroundColor = PresentationTheme.current.colors.background;
    [self loadWebContent];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
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
    _webView.backgroundColor = PresentationTheme.current.colors.background;
    _webView.opaque = YES;
}

- (IBAction)openContributePage:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videolan.org/contribute.html"]];
}

@end
