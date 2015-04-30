/*****************************************************************************
 * NSManagedObjectContext+refreshAll.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "NSManagedObjectContext+refreshAll.h"

@implementation NSManagedObjectContext (refreshAll)
- (void)vlc_refreshAllObjectsMerge:(BOOL)mergeChanges
{
    for (NSManagedObject *object in self.registeredObjects) {
        [self refreshObject:object mergeChanges:mergeChanges];
    }
}
@end
