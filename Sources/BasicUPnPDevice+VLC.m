/*****************************************************************************
 * BasicUPnPDevice+VLC.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Marc Etcheverry <marc # taplightsoftware com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "BasicUPnPDevice+VLC.h"

@implementation BasicUPnPDevice (VLC)

/// Note that we check if it is a media server as well as being an HDHomeRun device
- (BOOL)VLC_isHDHomeRunMediaServer
{
    /*
     * This is a sample UPnP broadcast of a HDHomeRun HDTC-2US device:
     *
     * Type: urn:schemas-upnp-org:device:MediaServer:1
     * UPnP Version: 1.0
     * DLNA Device Class: DMS-1.50
     * Friendly Name: HDHomeRun DLNA Tuner XXXXXXXX
     * Manufacturer: Silicondust
     * Manufacturer URL: http://www.silicondust.com
     * Model Description: HDTC-2US HDHomeRun PLUS Tuner
     * Model Name: HDHomeRun PLUS Tuner
     * Model Number HDTC-2US
     * Model URL: http://www.silicondust.com
     * Serial Nuymber: XXXXXXXX
     * Presentation URL: /
     *
     */

    // Let us do a case insensitive search to be safer. Silicondust's logo has is stylized as "SiliconDust", but the UPnP broadcast is "Silicondust"
    if ([[self urn] rangeOfString:@"urn:schemas-upnp-org:device:MediaServer" options:NSCaseInsensitiveSearch].location != NSNotFound &&
        [[self manufacturer] rangeOfString:@"Silicondust" options:NSCaseInsensitiveSearch].location != NSNotFound &&
        [[self modelName] rangeOfString:@"HDHomeRun" options:NSCaseInsensitiveSearch].location != NSNotFound &&
        [[self modelDescription] rangeOfString:@"HDHomeRun" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return YES;
    }

    return NO;
}

@end
