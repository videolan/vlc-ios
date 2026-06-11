/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VLCPlayerMenuKind) {
    VLCPlayerMenuKindAudio,
    VLCPlayerMenuKindSubtitles,
    VLCPlayerMenuKindChapters,
    VLCPlayerMenuKindSpeed,
};

@interface VLCPlayerMenuItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic) BOOL selected;

+ (instancetype)itemWithTitle:(NSString *)title selected:(BOOL)selected;

@end

@class VLCPlayerInlineMenuViewController;

@protocol VLCPlayerInlineMenuDelegate <NSObject>
- (void)inlineMenu:(VLCPlayerInlineMenuViewController *)menu
didSelectItemAtIndex:(NSInteger)index;
@end

/* A frosted-glass panel anchored above a button. Shared chrome for the
 * concrete panels below. */
@interface VLCPlayerPanelViewController : UIViewController

- (instancetype)initWithTitle:(nullable NSString *)title;
- (void)presentFromButton:(UIButton *)button
         inViewController:(UIViewController *)presenter;

@end

/* A selectable list of options. */
@interface VLCPlayerInlineMenuViewController : VLCPlayerPanelViewController

@property (nonatomic) VLCPlayerMenuKind kind;
@property (nonatomic, weak, nullable) id<VLCPlayerInlineMenuDelegate> delegate;

- (instancetype)initWithTitle:(nullable NSString *)title
                        items:(NSArray<VLCPlayerMenuItem *> *)items;

@end

/* A read-only information card. */
@interface VLCPlayerInfoPanelViewController : VLCPlayerPanelViewController

- (instancetype)initWithTitle:(nullable NSString *)title
                     infoText:(NSString *)infoText;

@end

NS_ASSUME_NONNULL_END
