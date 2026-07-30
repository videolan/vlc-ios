/*****************************************************************************
 * VLCGoogleDriveConstants.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#define kVLCGoogleDriveClientID @""
#define kVLCGoogleRedirectURI @""
#define kVLCGoogleDriveClientSecret @""
#define kVLCGoogleDrivePrivateKey @""

#define kVLCGoogleDriveFolderMimeType @"application/vnd.google-apps.folder"
#define kVLCGoogleDriveShortcutMimeType @"application/vnd.google-apps.shortcut"

/* a page can be filtered down to nothing, so keep paging until at least this
 * many items are worth showing */
#define kVLCGoogleDriveMinimumItemsPerBatch 10
