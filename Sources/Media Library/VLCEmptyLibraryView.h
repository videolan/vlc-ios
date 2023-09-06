/*****************************************************************************
 * VLCEmptyLibraryView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, VLCEmptyLibraryViewContentType)
{
    VLCEmptyLibraryViewContentTypeVideo,
    VLCEmptyLibraryViewContentTypeAudio,
    VLCEmptyLibraryViewContentTypePlaylist,
    VLCEmptyLibraryViewContentTypeNoPlaylists,
    VLCEmptyLibraryViewContentTypeNoHistory
};

@interface VLCEmptyLibraryView: UIView

@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLabel;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLongDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIButton *learnMoreButton;
@property (nonatomic, strong) IBOutlet UIImageView *iconView;
@property (nonatomic) VLCEmptyLibraryViewContentType contentType;

- (IBAction)learnMore:(id)sender;

@end
