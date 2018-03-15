//
//  BoxItemPickerViewController.h
//  BoxSDK
//
//  Created on 5/1/13.
//  Copyright (c) 2013 Box Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <BoxSDK/BoxItemPickerTableViewController.h>
#if TARGET_OS_IOS
#import <BoxSDK/BoxAuthorizationViewController.h>
#endif

typedef NS_ENUM(NSUInteger, BoxItemPickerObjectType) {
    BoxItemPickerObjectTypeFile,
    BoxItemPickerObjectTypeFolder,
    BoxItemPickerObjectTypeFileAndFolder
};

@class BoxFolder;
@class BoxFile;

/**
 * The BOXItemPickerDelegate protocol allows your application to interact with a
 * BoxItemPickerViewController and respond to the user selecting an item from
 * their Box account.
 *
 * The folder picker returns BoxModel objects to your delegate, which you can then
 * use to make API calls with the SDK.
 */
@protocol BOXItemPickerDelegate <NSObject>

/**
 * The user wants do dismiss the itemPicker
 *
 * @param controller The controller that was cancelled.
 */
- (void)itemPickerControllerDidCancel:(BoxItemPickerViewController *)controller;

@optional

/**
 * The user has selected a file.
 * @param controller The BoxItemPickerViewController used.
 * @param file The file picked by the user. 
 */
- (void)itemPickerController:(BoxItemPickerViewController *)controller didSelectBoxFile:(BoxFile *)file;

/**
 * The user has selected a folder.
 * @param controller The BoxItemPickerViewController used.
 * @param folder The folder picked by the user. 
 */
- (void)itemPickerController:(BoxItemPickerViewController *)controller didSelectBoxFolder:(BoxFolder *)folder;

@end

/**
 * BoxItemPickerViewController is a UI widget that allows quick and easy integration with Box.
 * Displaying a BoxItemPickerViewController provides a file browser and enables users to select
 * a file or folder from their Box account.
 *
 * The BoxItemPickerViewController handles OAuth2 authentication by itself if you do not wish
 * to authenticate users independently.
 *
 * The BoxItemPickerViewController makes extensive use of thumbnail support in the Box V2 API.
 * Additionally, it can display assets from the BoxSDKResources bundle and if you wish to use
 * the folder picker, you should include this bundle in your app.
 *
 * Selection events are handled by the BoxFolderPickerDelegate delegate protocol.
 */
#if TARGET_OS_IOS
@interface BoxItemPickerViewController : UIViewController <BoxItemPickerTableViewControllerDelegate, BoxAuthorizationViewControllerDelegate>
#else
@interface BoxItemPickerViewController : UIViewController <BoxItemPickerTableViewControllerDelegate>
#endif

@property (nonatomic, readwrite, weak) id<BOXItemPickerDelegate> delegate;


/**
 * Allows you to customize the number of items that will be downloaded in a row.
 * Default value in 100.
 */
@property (nonatomic, readwrite, assign) NSUInteger numberOfItemsPerPage;

/**
 * The type of item this itemPicker allows the user to select
 */
@property (nonatomic, readwrite, assign) BoxItemPickerObjectType selectableObjectType;

/**
 * Initializes an itemPicker according to the caching options provided as parameters. This
 * folder picker is bound to one instance of the BoxSDK and thus, one BoxOAuth2Session.
 *
 * @param sdk The SDK which the folder picker uses to perform API calls.
 * @param rootFolderID The root folder where to start browsing.
 * @param thumbnailsEnabled Enables/disables thumbnail management. If set to NO, only file icons will be displayed.
 * @param cachedThumbnailsPath The absolute path where the user wants to store the cached thumbnails.
 *   If set to nil, the folder picker will not cache the thumbnails, only download them on the fly.
 * @param selectableObjectType The type of item the itemPicker should allow the selection for.
 * @return A BoxItemPickerViewController.
 */
- (id)initWithSDK:(BoxSDK *)sdk rootFolderID:(NSString *)rootFolderID thumbnailsEnabled:(BOOL)thumbnailsEnabled cachedThumbnailsPath:(NSString *)cachedThumbnailsPath selectableObjectType:(BoxItemPickerObjectType)selectableObjectType;

/**
 * Purges the cache folder specified in the cachedThumbnailsPath parameter of the
 * initWithFolderID:enableThumbnails:cachedThumbnailsPath: method.
 */
- (void)purgeCache;

@end
