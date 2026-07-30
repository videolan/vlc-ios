/*****************************************************************************
 * GTLRDrive_File+VLCShortcut.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Rex Technology
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <GoogleAPIClientForREST/GTLRDrive.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A Drive shortcut is a file of its own that points at another item. Browsing
 * should behave as though the target were listed in its place, so every
 * decision based on type or identity goes through this category.
 */
@interface GTLRDrive_File (VLCShortcut)

@property (nonatomic, readonly) BOOL vlc_isShortcut;

/* YES for folders and for shortcuts pointing at one */
@property (nonatomic, readonly) BOOL vlc_isDirectory;

/* the target's mime type for resolvable shortcuts, this item's own otherwise */
@property (nonatomic, readonly, copy, nullable) NSString *vlc_effectiveMimeType;

/* the identifier to browse, stream, download or favourite */
@property (nonatomic, readonly, copy, nullable) NSString *vlc_targetIdentifier;

@end

NS_ASSUME_NONNULL_END
