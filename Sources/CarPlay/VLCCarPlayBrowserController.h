/*****************************************************************************
 * VLCCarPlayBrowserController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <CarPlay/CarPlay.h>

@class VLCMLAlbum, VLCMLMedia;

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCCarPlayBrowserController : NSObject

@property (readwrite) CPInterfaceController *interfaceController;

+ (NSUInteger)maximumItemCount;
+ (CGSize)listItemIconSize;
+ (nullable UIImage *)placeholderForSymbol:(NSString *)symbol;

- (CPListTemplate *)tabTemplateWithTitle:(NSString *)title
                                  symbol:(NSString *)symbol
                                sections:(NSArray<CPListSection *> *)sections;
- (void)pushListWithTitle:(NSString *)title items:(NSArray<CPListItem *> *)items;

- (NSArray<CPListItem *> *)albumItems:(NSArray<VLCMLAlbum *> *)albums;
- (NSArray<CPListItem *> *)trackItemsForAlbum:(VLCMLAlbum *)album;
- (NSArray<CPListItem *> *)trackItems:(NSArray<VLCMLMedia *> *)tracks
                           showArtist:(BOOL)showArtist
                    placeholderSymbol:(NSString *)symbol;

@end

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
