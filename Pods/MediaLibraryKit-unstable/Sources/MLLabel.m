/*****************************************************************************
 * MLLabel.m
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2015 VLC authors and VideoLAN
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

#import "MLLabel.h"
#import "MLMediaLibrary.h"
#import "MLFile.h"

@implementation MLLabel

+ (NSArray *)allLabels
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return [NSArray array];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Label" inManagedObjectContext:moc];
    [request setEntity:entity];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [request setSortDescriptors:@[descriptor]];

    NSArray *labels = [moc executeFetchRequest:request error:nil];

    return labels;
}

@dynamic name;
@dynamic files;

- (NSArray *)sortedFolderItems
{
    NSArray *folderItems = [[self valueForKey:@"files"] allObjects];

    NSSortDescriptor *folderItemDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"folderTrackNumber"
                                ascending:YES
                                 selector:@selector(compare:)];
    NSArray *items = [folderItems sortedArrayUsingDescriptors:@[folderItemDescriptor]];
    return items;
}

@end
