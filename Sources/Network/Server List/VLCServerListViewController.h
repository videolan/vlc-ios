/*****************************************************************************
 * VLCServerListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class MediaLibraryService;

NS_SWIFT_NAME(VLCServerListViewController)
@interface VLCServerListViewController : UIViewController

- (instancetype)initWithMedialibraryService:(MediaLibraryService *)medialibraryService;

@end
