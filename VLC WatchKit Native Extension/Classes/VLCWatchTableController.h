/*****************************************************************************
 * VLCWatchTableController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>

typedef NSString *(^VLCWatchTableControllerRowTypeForObjectBlock)(id object);
typedef void(^VLCWatchTableControllerConfigureRowControllerWithObjectBlock)(id rowController, id object);

@interface VLCWatchTableController : NSObject
@property (nonatomic, weak) IBOutlet WKInterfaceTable *table;

/* 
 * previous and next buttons are automatically hidden/shown depening on number
 * of objects, page size and the current page
 */
@property (nonatomic, weak) IBOutlet WKInterfaceButton *previousPageButton;
@property (nonatomic, weak) IBOutlet WKInterfaceButton *nextPageButton;


/*
 * Interface object which will be shown when the objects array is empty;
 */
@property (nonatomic, weak) IBOutlet WKInterfaceObject *emptyLibraryInterfaceObjects;

/* 
 * set eigher rowType if every row should have the same rowType or the
 * rowTypeForObjectBlock which returns the matching row type for an object
 */
@property (nonatomic, copy) NSString *rowType;
@property (nonatomic, copy) VLCWatchTableControllerRowTypeForObjectBlock rowTypeForObjectBlock;

@property (nonatomic, copy) VLCWatchTableControllerConfigureRowControllerWithObjectBlock configureRowControllerWithObjectBlock;

@property (nonatomic, copy, readonly) NSArray *displayedObjects;
@property (nonatomic, copy, readonly) NSIndexSet *displayedIndexes;

/* does setting these does not trigger table update call updateTable manually to update table */
@property (nonatomic, assign) NSUInteger pageSize;
@property (nonatomic, assign) NSUInteger currentPage;
/*
 * When the objects array changes it will figure out inserted and removed objects
 * and updates the table accoringly.
 */
@property (nonatomic, copy) NSArray *objects;

/*
 * Set the identifierKeyPath to the key path of a unique identifier of the objects.
 * The identifier at the keyPath is used to determine if a object was added or removed.
 * Default is @"self".
 */
@property (nonatomic, copy) NSString *identifierKeyPath;


/* updates the table with the current configuration (pagesize, page, objects) */
- (void)updateTable;

- (IBAction)previousPageButtonPressed;
- (IBAction)nextPageButtonPressed;


@end
