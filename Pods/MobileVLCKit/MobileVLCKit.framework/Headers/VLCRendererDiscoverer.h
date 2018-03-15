/*****************************************************************************
 * VLCRendererDiscoverer.h
 *****************************************************************************
 * Copyright © 2018 VLC authors, VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee<bubu@mikan.io>
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

@class VLCRendererItem;
@class VLCRendererDiscoverer;

/**
 * Renderer Discoverer delegate protocol
 * Allows to be notified upon discovery/changes of an renderer item
 */
@protocol VLCRendererDiscovererDelegate <NSObject>

- (void)rendererDiscovererItemAdded:(VLCRendererDiscoverer * _Nonnull)rendererDiscoverer
                               item:(VLCRendererItem * _Nonnull)item;
- (void)rendererDiscovererItemDeleted:(VLCRendererDiscoverer * _Nonnull)rendererDiscoverer
                               item:(VLCRendererItem * _Nonnull)item;

@end

/**
 * Renderer Discoverer description
 */
@interface VLCRendererDiscovererDescription : NSObject

/**
 * Name of the renderer discoverer
 */
@property (nonatomic, readonly, copy) NSString * _Nonnull name;

/**
 * Long name of the renderer discoverer
 */
@property (nonatomic, readonly, copy) NSString * _Nonnull longName;

/**
 * Instanciates an object that holds information about a renderer discoverer
 * \param name Name of the renderer discoverer
 * \param longName Long name of the renderer discoverer
 * \return A new `VLCRendererDiscovererDescription` object, only if there were no errors
 */
- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name longName:(NSString *_Nonnull)longName;

@end

/**
 * Renderer Discoverer
 */
@interface VLCRendererDiscoverer : NSObject

/**
 * Receiver's delegate
 */
@property (nonatomic, weak) id <VLCRendererDiscovererDelegate> _Nullable delegate;

- (instancetype _Nullable)init NS_UNAVAILABLE;

/**
 * Instanciates a `VLCRendererDiscoverer`
 * \param name Name of the renderer discoverer
 * \return A new `VLCRendererDiscoverer` object, only if there were no errors
 */
- (instancetype _Nullable)initWithName:(NSString * _Nonnull)name;

/**
 * Start the renderer discoverer
 * \return `YES` if successful, `NO` otherwise
 */
- (BOOL)start;

/**
 * Stops the renderer discoverer
 * \note This cannot fail
 */
- (void)stop;

/**
 * Returns an `NSArray` of `VLCRendererDiscovererDescription`
 * \note Call this method to retreive information in order to instanciate a `
 * `VLCRendererDiscoverer`
 * \return An `NSArray` of `VLCRendererDiscovererDescription`
 */
+ (NSArray<VLCRendererDiscovererDescription *> * _Nullable)list;

@end
