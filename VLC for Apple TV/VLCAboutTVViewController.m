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

#import "VLCAboutTVViewController.h"

@interface VLCAboutTVViewController ()
{
    UITextView *_textView;
}

@end

@implementation VLCAboutTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect frame = self.view.frame;
    frame.size.width -= 40.;
    frame.size.height -= 40.;
    frame.origin.x += 20.;
    frame.origin.y += 20.;

    _textView = [[UITextView alloc] initWithFrame:frame];
    _textView.clipsToBounds = YES;
    _textView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _textView.scrollEnabled = YES;

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSMutableString *htmlContent = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [htmlContent replaceOccurrencesOfString:@"VLCFORIOSVERSION" withString:[[NSString stringWithFormat:NSLocalizedString(@"VERSION_FORMAT", nil), [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] stringByAppendingFormat:@" (%@)<br /><i>%@</i>", [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"], kVLCVersionCodename] options:NSLiteralSearch range:NSMakeRange(800, 1000)];
    [htmlContent replaceOccurrencesOfString:@"MOBILEVLCKITVERSION" withString:[NSString stringWithFormat:NSLocalizedString(@"BASED_ON_FORMAT", nil),[[VLCLibrary sharedLibrary] version]] options:NSLiteralSearch range:NSMakeRange(800, 1100)];

    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[htmlContent dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                 documentAttributes:nil error:nil];

    _textView.attributedText = attributedString;
    [self.view addSubview:_textView];
}

- (NSString *)title
{
    return @"About";
}

@end
