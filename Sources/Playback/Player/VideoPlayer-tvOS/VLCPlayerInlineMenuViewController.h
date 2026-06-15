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
    VLCPlayerMenuKindSecondarySubtitles,
    VLCPlayerMenuKindChapters,
    VLCPlayerMenuKindSpeed,
};

typedef NS_ENUM(NSInteger, VLCPlayerStepperUnit) {
    VLCPlayerStepperUnitMilliseconds,
    VLCPlayerStepperUnitRate,
};

@interface VLCPlayerMenuItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic) BOOL selected;
@property (nonatomic, nullable) NSNumber *value; // when set, the stepper selects the item matching its value

+ (instancetype)itemWithTitle:(NSString *)title selected:(BOOL)selected;

@end

@class VLCPlayerInlineMenuViewController;

@protocol VLCPlayerInlineMenuDelegate <NSObject>
- (void)inlineMenu:(VLCPlayerInlineMenuViewController *)menu
didSelectItemAtIndex:(NSInteger)index;
@optional
- (void)inlineMenu:(VLCPlayerInlineMenuViewController *)menu
       didSetValue:(float)value;
@end

@interface VLCPlayerPanelViewController : UIViewController

- (instancetype)initWithTitle:(nullable NSString *)title;
- (void)presentFromButton:(UIButton *)button
         inViewController:(UIViewController *)presenter;

@end

/* A selectable list of options. */
@interface VLCPlayerInlineMenuViewController : VLCPlayerPanelViewController

@property (nonatomic) VLCPlayerMenuKind kind;
@property (nonatomic, weak, nullable) id<VLCPlayerInlineMenuDelegate> delegate;

/* When set, a value stepper is shown beneath the list. Configure before presenting. */
@property (nonatomic) BOOL showsStepperControl;
@property (nonatomic, copy, nullable) NSString *stepperTitle;
@property (nonatomic) float currentValue;
@property (nonatomic) float stepperStep;
@property (nonatomic) float minimumValue;
@property (nonatomic) float maximumValue;
@property (nonatomic) float defaultValue; // applied by the reset button
@property (nonatomic) VLCPlayerStepperUnit stepperUnit;

- (instancetype)initWithTitle:(nullable NSString *)title
                        items:(NSArray<VLCPlayerMenuItem *> *)items;

@end

@interface VLCPlayerInfoPanelViewController : VLCPlayerPanelViewController

- (instancetype)initWithTitle:(nullable NSString *)title
                     infoText:(NSString *)infoText;

@end

/* The playback queue: a selectable list of the queued media with shuffle and
 * repeat toggles in a footer row. Selecting an item plays it. */
@interface VLCPlayerQueuePanelViewController : VLCPlayerPanelViewController

@end

NS_ASSUME_NONNULL_END
