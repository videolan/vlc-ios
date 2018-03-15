/*****************************************************************************
 * VLCLibrary.h: VLCKit.framework VLCLibrary header
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2007 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCAudio.h"
#import "VLCMediaList.h"
#import "VLCMedia.h"

@class VLCAudio;

/**
 * The VLCLibrary is the base library of the VLCKit.framework.  This object provides a shared instance that exposes the
 * internal functionalities of libvlc and libvlc-control. The VLCLibrary object is instantiated automatically when
 * VLCKit.framework is loaded into memory.  Also, it is automatically destroyed when the VLCKit.framework is unloaded
 * from memory.
 *
 * Currently, the framework does not support multiple instances of VLCLibrary.  Furthermore, you cannot destroy any
 * instiantiation of VLCLibrary, as previously noted, this is done automatically by the dynamic link loader.
 */
@interface VLCLibrary : NSObject

/* Factories */
/**
 * Returns the library's shared instance.
 * \return The library's shared instance.
 */
+ (VLCLibrary *)sharedLibrary;

/**
 * returns an individual instance which can be customized with options
 * \param options a NSArray with NSString instance containing the options
 * \return the individual library instance
 */
 - (instancetype)initWithOptions:(NSArray*)options;

/**
 * enables/disables debug logging
 * param: debugLogging BOOL value to enable/disable
 * \note we will always log using NSLog
 * \return debug logging state
 */
@property (readwrite, nonatomic) BOOL debugLogging;

/**
 * gets/sets the debug logging level
 * param: debugLoggingLevel set level from 0 (all) to 4 (just error messages)
 * \return int debug level
*/
@property (readwrite, nonatomic) int debugLoggingLevel;

/**
 * Returns the library's version
 * \return The library version example "0.9.0-git Grishenko".
 */

@property (readonly, copy) NSString *version;

/**
 * Returns the compiler used to build the libvlc binary
 * \return The compiler version string.
 */

@property (readonly, copy) NSString *compiler;

/**
 * Returns the library's changeset
 * \return The library version example "adfee99".
 */

@property (readonly, copy) NSString *changeset;

/**
 * sets the application name and HTTP User Agend
 * libvlc will pass it to servers when required by protocol
 * \param readableName human-readable application name, e.g. "FooBar player 1.2.3"
 * \param userAgent HTTP User Agent, e.g. "FooBar/1.2.3 Python/2.6.0"
 */
- (void)setHumanReadableName:(NSString *)readableName withHTTPUserAgent:(NSString *)userAgent;

/**
 * Sets some meta-information about the application.
 *
 * \param identifier Java-style application identifier, e.g. "com.acme.foobar"
 * \param version application version numbers, e.g. "1.2.3"
 * \param icon application icon name, e.g. "foobar"
 */
- (void)setApplicationIdentifier:(NSString *)identifier withVersion:(NSString *)version andApplicationIconName:(NSString *)icon;

/**
 * the libvlc instance wrapped by the VLCLibrary instance
 * \note if you want to use it, you are most likely wrong (or want to add a proper ObjC API)
 */
@property (nonatomic, assign) void *instance;

@end
