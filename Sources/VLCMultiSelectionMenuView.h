//
//  VLCMultiSelectionMenuView.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 09/03/15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "VLCFrostedGlasView.h"

@protocol VLCMultiSelectionViewDelegate <NSObject>

@required
- (void)toggleUILock;
- (void)toggleEqualizer;
- (void)toggleChapterAndTitleSelector;
- (void)toggleRepeatMode;
- (void)toggleShuffleMode;
- (void)hideMenu;

@end

@interface VLCMultiSelectionMenuView : VLCFrostedGlasView

@property (readwrite, weak) id<VLCMultiSelectionViewDelegate> delegate;

@property (readwrite, assign) BOOL showsEqualizer;
@property (readwrite, assign) BOOL mediaHasChapters;

@property (nonatomic, assign) VLCRepeatMode repeatMode;

- (void)setDisplayLock:(BOOL)displayLock;
- (void)setDisplayShuffle:(BOOL)displayShuffle;
- (CGSize)proposedDisplaySize;

@end
