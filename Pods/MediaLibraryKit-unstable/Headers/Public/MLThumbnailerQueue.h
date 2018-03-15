/*****************************************************************************
 * MLThumbnailerQueue.h
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
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

@class MLFile;

@interface MLThumbnailerQueue : NSObject

+ (MLThumbnailerQueue *)sharedThumbnailerQueue;

- (void)addFile:(MLFile *)file;
- (void)setHighPriorityForFile:(MLFile *)file;
- (void)setDefaultPriorityForFile:(MLFile *)file;

- (void)stop;
- (void)resume;

@property (nonatomic, strong) NSOperationQueue *queue;
@end
