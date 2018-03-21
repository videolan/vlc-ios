/*****************************************************************************
 * VLCAudio.h: VLCKit.framework VLCAudio header
 *****************************************************************************
 * Copyright (C) 2007 Faustino E. Osuna
 * Copyright (C) 2007, 2014 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Faustino E. Osuna <enrique.osuna # gmail.com>
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

/* Notification Messages */
/**
 * Standard notification messages that are emitted by VLCAudio object.
 */
extern NSString *const VLCMediaPlayerVolumeChanged;

/**
 * basic class to control audio output
 */
@interface VLCAudio : NSObject

/**
 * Property to mute the current audio output
 * \note decoding continues when muted, so consider disabling the audio track if you don't want audio for a long time
 */
@property (getter=isMuted) BOOL muted;

/**
 * control the current audio output volume */
@property (assign) int volume;

/**
 * enable passthrough mode for the current audio device
 * \note There is no warrenty that it succeeds as it depends on the capabilities of the hardware audio decoder / receiver attached by the user */
@property (readwrite) BOOL passthrough;

/**
 * Mute the current audio output.
 * \deprecated This selector will be removed in the next release */
- (void)setMute:(BOOL)value __attribute__((deprecated));

/**
 * lower the current audio output volume */
- (void)volumeDown;

/**
 * higher the current audio output volume */
- (void)volumeUp;

@end
