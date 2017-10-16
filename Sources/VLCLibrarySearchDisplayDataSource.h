/*****************************************************************************
 * VLCLibrarySearchDisplayDataSource.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCLibrarySearchDisplayDataSource : NSObject<UITableViewDataSource>

- (NSManagedObject *)objectAtIndex:(NSUInteger)index;
- (void)shouldReloadTableForSearchString:(NSString *)searchString searchableFiles:(NSArray *)files;

@end
