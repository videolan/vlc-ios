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

@implementation VLCAboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.hidden = YES;
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil] baseURL:nil];
    self.webView.delegate = self;
    self.aspenVersion.text = [[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT",@""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] stringByAppendingFormat:@" %@", kVLCVersionCodename];
    self.vlckitVersion.text = [NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT",@""),[[VLCLibrary sharedLibrary] version]];

    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", @"")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(dismiss)];
    [dismissButton setBackgroundImage:[UIImage imageNamed:@"doneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [dismissButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [dismissButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]} forState:UIControlStateNormal];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.navigationItem.rightBarButtonItem = dismissButton;
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
    self.webView.hidden = NO;
}

- (void)dismiss
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
