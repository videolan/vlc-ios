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
#import "VLC-Swift.h"

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
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AboutTitle"]];
    [self.navigationItem.titleView setTintColor:PresentationTheme.current.colors.navigationbarTextColor];
    
    UIBarButtonItem *contributeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CONTRIBUTE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(openContributePage:)];
    contributeButton.accessibilityIdentifier = VLCAccessibilityIdentifier.contribute;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done;
    
    self.navigationItem.leftBarButtonItem = contributeButton;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    [self loadWebContent];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadWebContent
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *textColor = PresentationTheme.current.colors.cellTextColor.toHex;
    NSString *backgroundColor = PresentationTheme.current.colors.background.toHex;
    NSString *version = [NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT", nil), [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *versionBuildNumberAndCodeName = [version stringByAppendingFormat:@" (%@)<br /><i>%@</i>", [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"], kVLCVersionCodename];
    NSString *vlcLibraryVersion = [NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT", nil), [[VLCLibrary sharedLibrary] version]];
    NSString *htmlFilePath = [mainBundle pathForResource:@"About Contents" ofType:@"html"];

    NSMutableString *htmlContent = [NSMutableString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil];

    NSRange rangeOfLastStringToReplace = [htmlContent rangeOfString:@"MOBILEVLCKITVERSION"];
    NSUInteger lengthOfStringToSearch = rangeOfLastStringToReplace.location + rangeOfLastStringToReplace.length + versionBuildNumberAndCodeName.length + textColor.length + backgroundColor.length + vlcLibraryVersion.length;
    NSRange searchRange = NSMakeRange(0, lengthOfStringToSearch);
    [htmlContent replaceOccurrencesOfString:@"VLCFORIOSVERSION" withString:versionBuildNumberAndCodeName options:NSLiteralSearch range:searchRange];
    [htmlContent replaceOccurrencesOfString:@"TEXTCOLOR" withString:textColor options:NSLiteralSearch range:searchRange];
    [htmlContent replaceOccurrencesOfString:@"BACKGROUNDCOLOR" withString:backgroundColor options:NSLiteralSearch range:searchRange];
    [htmlContent replaceOccurrencesOfString:@"MOBILEVLCKITVERSION" withString:vlcLibraryVersion options:NSLiteralSearch range:searchRange];

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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

@end
