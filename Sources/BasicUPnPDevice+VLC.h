/*****************************************************************************
 * BasicUPnPDevice+VLC.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Marc Etcheverry <marc # taplightsoftware com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "BasicUPnPDevice.h"

/// Extension to detect HDHomeRun devices
@interface BasicUPnPDevice (VLC)

- (BOOL)VLC_isHDHomeRunMediaServer;

@end
