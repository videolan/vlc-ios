/*****************************************************************************
 * MDFSubtitleItem.h
 *****************************************************************************
 * Copyright (C) 2015 Felix Paul Kühne
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
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

@interface MDFSubtitleItem : NSObject

@property (copy, nonatomic) NSString *language;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *format;
@property (copy, nonatomic) NSString *iso639Language;
@property (copy, nonatomic) NSString *downloadAddress;
@property (copy, nonatomic) NSString *rating;

@end

@interface MDFSubtitleLanguage : NSObject

@property (copy, nonatomic) NSString *ID;
@property (copy, nonatomic) NSString *localizedName;
@property (copy, nonatomic) NSString *iso639Language;

@end