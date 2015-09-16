/*****************************************************************************
 * VLCWatchTableController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCWatchTableController.h"


@interface VLCWatchTableController()

@property (nonatomic, copy, readwrite) NSArray *displayedObjects;
@property (nonatomic, copy, readwrite) NSIndexSet *displayedIndexes;
@property (nonatomic, copy, readwrite) NSArray *rowTypes;

@end

@implementation VLCWatchTableController

- (NSString *)identifierKey {
    if (!_identifierKeyPath) {
        _identifierKeyPath = @"self";
    }
    return _identifierKeyPath;
}

- (void)setObjects:(NSArray *)objects {
    _objects = [objects copy];
    [self updateTable];
}

- (void)updateTable {

    NSUInteger pageSize = self.pageSize;
    NSUInteger currentPage = self.currentPage;
    NSUInteger startIndex = self.currentPage*pageSize;
    NSUInteger objectsCount = self.objects.count;

    /* calculate a valid start index and reset current page if needed */
    while (startIndex > objectsCount) {
        if (startIndex < pageSize) {
            startIndex = 0;
            currentPage = 0;
        } else {
            startIndex -= pageSize;
            currentPage--;
        }
    }

    /* calculate valid end index */
    NSUInteger endIndex = startIndex+pageSize;
    if (endIndex > objectsCount) {
        endIndex = objectsCount;
    }

    /* get new dispayed objects */
    NSRange range = NSMakeRange(startIndex, endIndex-startIndex);
    NSArray *newObjects = [self.objects subarrayWithRange:range];
    NSSet *newSet = [[NSSet alloc] initWithArray:[newObjects valueForKeyPath:self.identifierKeyPath]];

    NSArray *oldObjects = self.displayedObjects;
    NSSet *oldSet = [[NSSet alloc] initWithArray:[oldObjects valueForKeyPath:self.identifierKeyPath]];

    WKInterfaceTable *table = self.table;

    NSMutableSet *addedSet = [NSMutableSet setWithSet:newSet];
    [addedSet minusSet:oldSet];
    NSMutableSet *removedSet = [NSMutableSet setWithSet:oldSet];
    [removedSet minusSet:newSet];

    BOOL differentRowTypes = self.rowTypeForObjectBlock != nil;
    BOOL pageChange = startIndex != self.displayedIndexes.firstIndex;

    NSMutableArray *rowTypes = differentRowTypes ? [NSMutableArray arrayWithCapacity:pageSize] : nil;

    // we changed the page
    if (pageChange) {
        if (differentRowTypes) {
            // TODO add support different rowtypes
            NSAssert(NO,@"TODO add support different rowtypes");
        } else {
            NSUInteger oldCount = oldObjects.count;
            NSUInteger newCount = newObjects.count;
            // remove rows if now on smaller page
            if (oldCount > newCount) {
                NSRange range = NSMakeRange(newCount, oldCount-newCount);
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
                [table removeRowsAtIndexes:indexSet];
            }
            // add rows if now on bigger page
            else if (oldCount < newCount) {
                NSRange range = NSMakeRange(oldCount, newCount-oldCount);
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
                [table insertRowsAtIndexes:indexSet withRowType:self.rowType];
            }
            [newObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self _configureTableCellAtIndex:idx withObject:obj];
            }];
        }
    }
    // update on the same page
    else {
        NSMutableIndexSet *removeRowIndexes = [NSMutableIndexSet new];
        [oldObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([removedSet containsObject:[obj valueForKeyPath:self.identifierKeyPath]]) {
                [removeRowIndexes addIndex:idx];
            }
        }];
        [table removeRowsAtIndexes:removeRowIndexes];

        [newObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([addedSet containsObject:[obj valueForKeyPath:self.identifierKeyPath]]) {
                NSString *rowType = [self _rowTypeForObject:obj];
                [table insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:idx] withRowType:rowType];
            }
            [self _configureTableCellAtIndex:idx withObject:obj];
        }];
    }

    self.rowTypes = rowTypes;
    self.displayedObjects = newObjects;
    self.displayedIndexes = [NSIndexSet indexSetWithIndexesInRange:range];


    /* set state for previous and next buttons */
    self.previousPageButton.hidden = currentPage == 0;
    self.nextPageButton.hidden = endIndex >= objectsCount;

    self.emptyLibraryInterfaceObjects.hidden = newObjects.count != 0;
}

- (void)nextPageButtonPressed {
    NSUInteger nextPageStartIndex = self.pageSize * (self.currentPage+1);
    if (nextPageStartIndex > self.objects.count) {
        return;
    }
    self.currentPage = self.currentPage+1;
    [self updateTable];
    [self.table scrollToRowAtIndex:0];
}

- (void)previousPageButtonPressed {
    if (self.currentPage>0) {
        self.currentPage = self.currentPage-1;
        [self updateTable];
    }
    NSUInteger displayedCount = self.displayedObjects.count;
    if (displayedCount) {
        [self.table scrollToRowAtIndex:displayedCount-1];
    }
}

#pragma mark - internal helper

- (NSString *)_rowTypeForObject:(id)object {
    if (self.rowTypeForObjectBlock) {
        return self.rowTypeForObjectBlock(object);
    }
    NSAssert(self.rowType, @"Either rowTypeForObjectBlock or rowType must be set");
    return self.rowType;
}

- (void)_configureTableCellAtIndex:(NSUInteger)index withObject:(id)object {
    VLCWatchTableControllerConfigureRowControllerWithObjectBlock configureBlock = self.configureRowControllerWithObjectBlock;
    NSAssert(configureBlock, @"configureRowControllerWithObjectBlock must be set");
    if (configureBlock) {
        id rowController = [self.table rowControllerAtIndex:index];
        configureBlock(rowController, object);
    }
}

@end
