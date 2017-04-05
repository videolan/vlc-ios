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

//TODO: Add ClientID
//ClientID formating: @"xyz.apps.googleusercontent.com"
#define kVLCGoogleDriveClientID @""
#define kKeychainItemName @"vlc-ios"
//TODO: Add RedirectURI
//RedirectURI formating: @"com.googleusercontent.apps.xyz:/oauthredirect"
#define kVLCGoogleRedirectURI @""
#warning Google Drive app secret missing, login will fail
#define kVLCGoogleDriveClientSecret @""
//#define kVLCGoogleDriveAppKey @"a60fc6qj9zdg7bw"
#warning Google Drive app private key missing, login will fail
#define kVLCGoogleDrivePrivateKey @""
