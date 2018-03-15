/*****************************************************************************
 * VLCMediaDiscoverer.h: VLCKit.framework VLCMediaDiscoverer header
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2015 Felix Paul Kühne
 * Copyright (C) 2007, 2015 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
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
#import "VLCMediaList.h"

@class VLCLibrary;
@class VLCMediaList;
@class VLCMediaDiscoverer;


typedef NS_ENUM(unsigned, VLCMediaDiscovererCategoryType)
{
    VLCMediaDiscovererCategoryTypeDevices = 0,
    VLCMediaDiscovererCategoryTypeLAN,
    VLCMediaDiscovererCategoryTypePodcasts,
    VLCMediaDiscovererCategoryTypeLocalDirectories
};

/* discoverer keys */
extern NSString *const VLCMediaDiscovererName;
extern NSString *const VLCMediaDiscovererLongName;
extern NSString *const VLCMediaDiscovererCategory;

/**
 * VLCMediaDiscoverer
 */

@interface VLCMediaDiscoverer : NSObject

/**
 * The library instance used by the discoverers
 * \note unless for debug, you are wrong if you want to use this selector
 */
@property (nonatomic, readonly) VLCLibrary *libraryInstance;

/**
 * The full list of available media discoverers
 * \return returns an empty array for binary compatibility, will be removed in subsequent releases
 * \deprecated use availableMediaDiscovererForCategoryType instead
 */
+ (NSArray *)availableMediaDiscoverer __attribute__((deprecated));

/**
 * \param categoryType VLCMediaDiscovererCategory you are looking for
 * \return an array of dictionaries describing the available discoverers for the requested type
 */
+ (NSArray *)availableMediaDiscovererForCategoryType:(VLCMediaDiscovererCategoryType)categoryType;

/* Initializers */
/**
 * Initializes new object with specified name.
 * \param aServiceName Name of the service for this VLCMediaDiscoverer object.
 * \returns Newly created media discoverer.
 * \note with VLCKit 3.0 and above, you need to start the discoverer explicitly after creation
 */
- (instancetype)initWithName:(NSString *)aServiceName;

/**
 * same as above but with a custom VLCLibrary instance
 * \note Using this mode can lead to a significant performance impact - use only if you know what you are doing
 */
- (instancetype)initWithName:(NSString *)aServiceName libraryInstance:(VLCLibrary *)libraryInstance;

/**
 * start media discovery
 * \returns -1 if start failed, otherwise 0
 */
- (int)startDiscoverer;

/**
 * stop media discovery
 */
- (void)stopDiscoverer;

/**
 * a read-only property to retrieve the list of discovered media items
 */
@property (weak, readonly) VLCMediaList *discoveredMedia;

/**
 * localized name of the discovery module if available, otherwise in US English
 * \deprecated Will be removed in the next major release, may return an empty string for binary compatibility
 */
@property (readonly, copy) NSString *localizedName __attribute__((deprecated));

/**
 * read-only property to check if the discovery service is active
 * \return boolean value
 */
@property (readonly) BOOL isRunning;
@end
