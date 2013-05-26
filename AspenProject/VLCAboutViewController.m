//
//  VLCAboutViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 07.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCAboutViewController.h"

@interface VLCAboutViewController ()

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

    self.dismissButton.title = NSLocalizedString(@"BUTTON_DONE", @"");
    self.dismissButton.style = UIBarButtonItemStyleDone;
    self.textContents.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    self.aspenVersion.text = [[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT",@""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] stringByAppendingFormat:@" %@", kVLCVersionCodename];
    self.vlckitVersion.text = [NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT",@""),[[VLCLibrary sharedLibrary] version]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillDisappear:animated];
}

- (IBAction)dismiss:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
