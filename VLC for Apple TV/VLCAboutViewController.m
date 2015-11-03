/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAboutViewController.h"

@interface VLCAboutViewController ()
{
    NSTimer *_scrollTimer;
    NSTimeInterval _startInterval;
    CGPoint _scrollPoint;
}

@end

@implementation VLCAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *mainBundle = [NSBundle mainBundle];
    self.versionLabel.text = [[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT", nil), [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] stringByAppendingFormat:@" (%@)", [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    self.basedOnLabel.text = [[NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT", nil),[[VLCLibrary sharedLibrary] version]] stringByReplacingOccurrencesOfString:@"<br />" withString:@" "];
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.];

    self.blablaTextView.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    self.blablaTextView.scrollEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _scrollPoint = CGPointZero;
    if (!_scrollTimer) {
        _scrollTimer = [NSTimer scheduledTimerWithTimeInterval: 1/6
                                                       target:self
                                                     selector:@selector(scrollABit:)
                                                     userInfo:nil
                                                      repeats:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_scrollTimer) {
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
}

- (void)resetScrolling
{
    _scrollPoint = CGPointZero;
    [self.blablaTextView setContentOffset:_scrollPoint animated:YES];
}

- (void)scrollABit:(NSTimer *)timer
{
    CGFloat maxHeight = self.blablaTextView.contentSize.height;

    if (!_startInterval) {
        _startInterval = [NSDate timeIntervalSinceReferenceDate] + 2.0;
    }

    if ([NSDate timeIntervalSinceReferenceDate] >= _startInterval) {
        if (_scrollPoint.y > maxHeight) {
            [self resetScrolling];
            return;
        }

        _scrollPoint.y++;
        [self.blablaTextView setContentOffset:_scrollPoint animated:NO];
    }
}

@end
