/*****************************************************************************
 * MLMediaLibrary+Migration.h
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "MLMediaLibrary.h"

@interface MLMediaLibrary (Migration)

- (void)_setupLibraryPathPriorToMigration;

- (BOOL)_libraryMigrationNeeded;
- (void)_migrateLibrary;

@end
