//
//  BoxFolder.h
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItem.h"

@class BoxCollection;

/**
 * BoxFolder represents folders on Box.
 */
@interface BoxFolder : BoxItem

/**
 * A dictionary containing information about a folder's upload email.
 */
@property (nonatomic, readonly) NSDictionary *folderUploadEmail;

/**
 * The first 100 children of a folder.
 *
 * @see [BoxFoldersResourceManager folderItemsWithID:requestBuilder:success:failure:]
 */
@property (nonatomic, readonly) BoxCollection *itemCollection;

/**
 * Whether or not this folder is synced using Box Sync.
 */
@property (nonatomic, readonly) NSString *syncState;

@end
