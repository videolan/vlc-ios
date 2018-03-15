//
//  BoxItemPickerHelper.h
//  BoxSDK
//
//  Created on 5/1/13.
//  Copyright (c) 2013 Box Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BoxSDK;
@class BoxItem;
@class BoxFile;

typedef void (^BoxThumbnailDownloadBlock)(UIImage *image);
typedef void (^BoxNeedsAPICallCompletionBlock)(BOOL needsAPICall, UIImage *cachedImage);

/**
 * A helper class for manipulating thumbnails and SDK model objects.
 *
 * Typedefs
 * ========
 * <pre><code>typedef void (^BoxThumbnailDownloadBlock)(UIImage *image);
 * typedef void (^BoxNeedsAPICallCompletionBlock)(BOOL needsAPICall, UIImage *cachedImage);</code></pre>
 */
@interface BoxItemPickerHelper : NSObject

@property (nonatomic, readwrite, weak) BoxSDK *SDK;

- (id)initWithSDK:(BoxSDK *)SDK;

/**
 * Returns a readable string of the last update date of the item.
 *
 * @param item The item to calculate a date string for.
 */
- (NSString *)dateStringForItem:(BoxItem *)item;

/**
 * Downloads the thumbnail of the specified path.
  * @param item The thumbnail's corresponding item.
  * @param cachePath The path where to look for and cache the thumbnail.
  * @param refreshed Callback returning the refreshed cached image, retrieved via the API.
 */
- (void)thumbnailForItem:(BoxItem *)item 
                    cachePath:(NSString *)cachePath
               refreshed:(BoxThumbnailDownloadBlock)refreshed;

/**
 * Requests any cached thumbnail available. Provides an icon to display in case there is no cached thumbnail
 * @param item The thumbnail's corresponding item.
 * @param cachePath The path where to look for and cache the thumbnail.
 * @param completionBlock Callback returning the image to display, and wether
 *   an API call is needed to retrieve the thumbnail.
 */
- (void)itemNeedsAPICall:(BoxItem *)item cachePath:(NSString *)cachePath completion:(BoxNeedsAPICallCompletionBlock)completionBlock;

/**
 * Returns whether the file needs to get a thumbnail, according its file type.
 *
 * @param item The item for which to find out if a thumbnail should be displayed.
 */
- (BOOL)shouldDiplayThumbnailForItem:(BoxItem *)item;

/**
 * Cancels all occuring thumbnail download operations.
 */
- (void)cancelThumbnailOperations;

/**
 * Purges the dictionnary containing the in-memory thumbnail images. No op if the user uses cached files on disk.
 */
- (void)purgeInMemoryCache;

/**
 * Return the in memory cached thumbnail for an item.
 *
 * @param item The item to return the cached thumbnail for.
 */
- (UIImage *)inMemoryCachedThumbnailForItem:(BoxItem *)item;

/**
 * Requeues all operations that failed after token expiration.
 */
- (void)retryOperationsAfterTokenRefresh;

@end
