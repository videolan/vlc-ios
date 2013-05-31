//
//  VLCAboutViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 07.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCAboutViewController.h"

@interface VLCAboutViewController () {
    UIBarButtonItem *_dismissButton;
}

@end

@implementation VLCAboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil] baseURL:nil];
    self.webView.delegate = self;
    self.aspenVersion.text = [[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT",@""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] stringByAppendingFormat:@" %@", kVLCVersionCodename];
    self.vlckitVersion.text = [NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT",@""),[[VLCLibrary sharedLibrary] version]];

    _dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", @"")
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self action:@selector(dismiss)];
    [_dismissButton setBackgroundImage:[UIImage imageNamed:@"doneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [_dismissButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    self.navigationItem.rightBarButtonItem = _dismissButton;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return ![[UIApplication sharedApplication] openURL:request.URL];
}

- (void)dismiss
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
