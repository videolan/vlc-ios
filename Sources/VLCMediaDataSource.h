//
//  VLCMediaDatasource.h
//  VLC
//
//  Created by Carola Nitz on 8/15/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VLCMediaDataSource : NSObject

- (NSManagedObject *)currentSelection;

- (void)updateContentsForSelection:(NSManagedObject *)selection;
- (NSUInteger)numberOfFiles;
- (NSManagedObject *)objectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(NSManagedObject *)object;

- (void)insertObject:(NSManagedObject *)object atIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)moveObjectFromIndex:(NSUInteger)fromIdx toIndex:(NSUInteger)toIdx;

//this always creates a copy that might not be good
- (NSArray *)allObjects;

- (void)addAlbumsInAllAlbumMode:(BOOL)isAllAlbumMode;
- (void)addAllShows;
- (void)addAllFolders;
- (void)addRemainingFiles;

- (void)removeMediaObject:(NSManagedObject *)managedObject;
- (void)removeMediaObjectFromFolder:(NSManagedObject *)managedObject;
@end
