/*****************************************************************************
 * VLCEmptyLibraryView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCEmptyLibraryView.h"
#import "VLCFirstStepsViewController.h"
#import "VLC-Swift.h"

@implementation VLCEmptyLibraryView

- (void)awakeFromNib
{
    _emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    _emptyLibraryLongDescriptionLabel.text = NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
    [_learnMoreButton setTitle:NSLocalizedString(@"BUTTON_LEARN_MORE", nil) forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
    [self themeDidChange];
    [super awakeFromNib];
}

- (IBAction)learnMore:(id)sender
{
      UIViewController *firstStepsVC = [[VLCFirstStepsViewController alloc] initWithNibName:nil bundle:nil];
      UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:firstStepsVC];
      navCon.modalPresentationStyle = UIModalPresentationFormSheet;
      [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)themeDidChange
{
    ColorPalette *colors = PresentationTheme.current.colors;
    _emptyLibraryLabel.textColor = colors.cellTextColor;
    _emptyLibraryLabel.backgroundColor = colors.background;
    _emptyLibraryLongDescriptionLabel.textColor = colors.lightTextColor;
    _emptyLibraryLongDescriptionLabel.backgroundColor = colors.background;
}

- (void)setContentType:(VLCEmptyLibraryViewContentType)contentType
{
    _contentType = contentType;

    NSString *title;
    NSString *description;

    switch (contentType) {
        case VLCEmptyLibraryViewContentTypeVideo:
        case VLCEmptyLibraryViewContentTypeAudio:
            title = NSLocalizedString(@"EMPTY_LIBRARY", nil);
            description = NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
            _learnMoreButton.hidden = NO;
            break;
        case VLCEmptyLibraryViewContentTypePlaylist:
            title = NSLocalizedString(@"EMPTY_PLAYLIST", nil);
            description = NSLocalizedString(@"EMPTY_PLAYLIST_DESCRIPTION",
                                            nil);
            _learnMoreButton.hidden = YES;
            break;
        case VLCEmptyLibraryViewContentTypeNoHistory:
            title = NSLocalizedString(@"EMPTY_HISTORY", nil);
            description = NSLocalizedString(@"EMPTY_HISTORY_DESCRIPTION", nil);
            _learnMoreButton.hidden = YES;
            break;
        case VLCEmptyLibraryViewContentTypeNoPlaylists:
            title = NSLocalizedString(@"EMPTY_NO_PLAYLISTS", nil);
            description = NSLocalizedString(@"EMPTY_NO_PLAYLISTS_DESCRIPTION",
                                            nil);
            _learnMoreButton.hidden = YES;
            break;
    }
    _emptyLibraryLabel.text = title;
    _emptyLibraryLongDescriptionLabel.text = description;
}

@end
