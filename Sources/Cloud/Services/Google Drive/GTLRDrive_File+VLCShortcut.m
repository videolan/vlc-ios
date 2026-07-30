/*****************************************************************************
 * GTLRDrive_File+VLCShortcut.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Rex Technology
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "GTLRDrive_File+VLCShortcut.h"
#import "VLCGoogleDriveConstants.h"

@implementation GTLRDrive_File (VLCShortcut)

- (BOOL)vlc_isShortcut
{
    return [self.mimeType isEqualToString:kVLCGoogleDriveShortcutMimeType];
}

- (NSString *)vlc_effectiveMimeType
{
    NSString *targetMimeType = self.shortcutDetails.targetMimeType;
    if (self.vlc_isShortcut && targetMimeType.length > 0) {
        return targetMimeType;
    }

    return self.mimeType;
}

- (NSString *)vlc_targetIdentifier
{
    NSString *targetIdentifier = self.shortcutDetails.targetId;
    if (self.vlc_isShortcut && targetIdentifier.length > 0) {
        return targetIdentifier;
    }

    return self.identifier;
}

- (BOOL)vlc_isDirectory
{
    return [self.vlc_effectiveMimeType isEqualToString:kVLCGoogleDriveFolderMimeType];
}

@end
