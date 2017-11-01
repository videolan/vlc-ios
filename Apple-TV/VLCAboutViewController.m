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
    CADisplayLink *displayLink;
    NSTimer *startAnimationTimer;
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

    NSMutableAttributedString *aboutContents = [[NSMutableAttributedString alloc] initWithData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle]
                                                                                                                                    pathForResource:@"About Contents" ofType:@"html"]
                                                                                                                          encoding:NSUTF8StringEncoding
                                                                                                                             error:nil]
                                                                                                dataUsingEncoding:NSUTF8StringEncoding]
                                                                                       options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                                 NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                            documentAttributes:nil error:nil];
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        [aboutContents addAttribute:NSForegroundColorAttributeName value:[UIColor VLCLightTextColor] range:NSMakeRange(0., aboutContents.length)];
    }

    UITextView *textView = self.blablaTextView;
    textView.attributedText = aboutContents;
    textView.scrollEnabled = YES;
    textView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
    [textView.panGestureRecognizer addTarget:self action:@selector(scrollViewPan:)];
    textView.userInteractionEnabled = YES;
    textView.showsVerticalScrollIndicator = YES;

    UITapGestureRecognizer *tapUpArrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTop)];
    tapUpArrowRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];
    [textView addGestureRecognizer:tapUpArrowRecognizer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startAnimationTimer];
}
- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopAnimation];
}

- (UIView *)preferredFocusedView
{
    return self.blablaTextView;
}

- (void)scrollToTop
{
    [self stopAnimation];
    [self.blablaTextView setContentOffset:CGPointZero animated:YES];
    [self startAnimationTimer];
}

- (void)scrollViewPan:(UIPanGestureRecognizer *)recognizer
{
    switch(recognizer.state) {
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
            [self startAnimationTimer];
            break;
        default:
            [self stopAnimation];
            break;
    }
}

- (void)startAnimationTimer
{
    [startAnimationTimer invalidate];
    startAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(startAnimation) userInfo:nil repeats:NO];
}

- (void)stopAnimation
{
    [startAnimationTimer invalidate];
    startAnimationTimer = nil;
    [displayLink invalidate];
    displayLink = nil;
}
- (void)startAnimation
{
    [displayLink invalidate];
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTriggered:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)displayLinkTriggered:(CADisplayLink*)link
{
    UIScrollView *scrollView = self.blablaTextView;
    CGFloat viewHeight = CGRectGetHeight(scrollView.frame);
    CGFloat maxOffsetY = scrollView.contentSize.height - viewHeight;

    CFTimeInterval secondsPerPage = 5.0;
    CGFloat offset = link.duration/secondsPerPage * viewHeight;

    CGFloat newYOffset = scrollView.contentOffset.y + offset;

    if (newYOffset > maxOffsetY+viewHeight) {
        scrollView.contentOffset = CGPointMake(0, -viewHeight);
    } else {
        scrollView.contentOffset = CGPointMake(0, newYOffset);
    }
}

@end
