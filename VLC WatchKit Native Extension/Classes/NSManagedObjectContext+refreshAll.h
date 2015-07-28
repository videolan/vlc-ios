/*****************************************************************************
 * NSManagedObjectContext+refreshAll.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (refreshAll)
// mergeChanges has same sematics as - (void)refreshObject:(NSManagedObject *)object mergeChanges:(BOOL)flag;
- (void)vlc_refreshAllObjectsMerge:(BOOL)mergeChanges;
@end
