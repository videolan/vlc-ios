/*****************************************************************************
 * VLCTrackSelectorView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFrostedGlasView.h"

@interface VLCTrackSelectorView : VLCFrostedGlasView

@property (nonatomic, assign) BOOL switchingTracksNotChapters;
@property(nonatomic, copy) void (^completionHandler)(BOOL finished);

- (void)updateView;
@end
