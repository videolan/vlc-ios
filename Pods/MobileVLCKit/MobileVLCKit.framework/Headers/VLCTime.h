/*****************************************************************************
 * VLCTime.h: VLCKit.framework VLCTime header
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2007-2016 VLC authors and VideoLAN
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

/**
 * Provides an object to define VLCMedia's time.
 */
@interface VLCTime : NSObject

/**
 * factorize an empty time object
 * \return the VLCTime object
 */
+ (VLCTime *)nullTime;
/**
 * factorize a time object with a given number object
 * \param aNumber the NSNumber object with a time in milliseconds
 * \return the VLCTime object
 */
+ (VLCTime *)timeWithNumber:(NSNumber *)aNumber;
/**
 * factorize a time object with a given integer
 * \param aInt the int with a time in milliseconds
 * \return the VLCTime object
 */
+ (VLCTime *)timeWithInt:(int)aInt;

/**
 * init a time object with a given number object
 * \param aNumber the NSNumber object with a time in milliseconds
 * \return the VLCTime object
 */
- (instancetype)initWithNumber:(NSNumber *)aNumber;
/**
 * init a time object with a given integer
 * \param aInt the int with a time in milliseconds
 * \return the VLCTime object
 */
- (instancetype)initWithInt:(int)aInt;

/* Properties */
/**
 * the current time value as NSNumber
 * \return the NSNumber object
 */
@property (nonatomic, readonly) NSNumber * value;    ///< Holds, in milliseconds, the VLCTime value
/**
 * the current time value as NSNumber
 * \return the NSNumber object
 * \deprecated use value instead
 */
@property (readonly) NSNumber * numberValue __attribute__((deprecated));	    // here for backwards compatibility

/**
 * the current time value as string value localized for the current environment
 * \return the NSString object
 */
@property (readonly) NSString * stringValue;
/**
 * the current time value as verbose string value localized for the current environment
 * \return the NSString object
 */
@property (readonly) NSString * verboseStringValue;
/**
 * the current time value as string value localized for the current environment representing the time in minutes
 * \return the NSString object
 */
@property (readonly) NSString * minuteStringValue;
/**
 * the current time value as int value
 * \return the int
 */
@property (readonly) int intValue;

/* Comparators */
/**
 * compare the current VLCTime instance against another instance
 * \param aTime the VLCTime instance to compare against
 * \return a NSComparisonResult
 */
- (NSComparisonResult)compare:(VLCTime *)aTime;
/**
 * compare the current VLCTime instance against another instance
 * \param object the VLCTime instance to compare against
 * \return a BOOL whether the instances are equal or not
 */
- (BOOL)isEqual:(id)object;
/**
 * Calculcate a unique hash for the current time instance
 * \return a hash value
 */
- (NSUInteger)hash;

@end
