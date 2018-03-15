//
//  BoxSDK.h
//  BoxSDK
//
//  Created on 2/19/13.
//  Copyright (c) 2013 Box. All rights reserved.
//
//  NOTE: this file is a mirror of BoxCocoaSDK/BoxCocoaSDK.h. Changes made here should be reflected there.
//

#import <Foundation/Foundation.h>

// constants and logging
#import <BoxSDK/BoxSDKConstants.h>
#import <BoxSDK/BoxLog.h>
#import <BoxSDK/BoxSDKErrors.h>

// OAuth2
#if TARGET_OS_IOS
#import <BoxSDK/BoxAuthorizationViewController.h>
#endif
#import <BoxSDK/BoxOAuth2Session.h>
#import <BoxSDK/BoxSerialOAuth2Session.h>
#import <BoxSDK/BoxParallelOAuth2Session.h>

// API Operation queues
#import <BoxSDK/BoxAPIQueueManager.h>
#import <BoxSDK/BoxSerialAPIQueueManager.h>
#import <BoxSDK/BoxParallelAPIQueueManager.h>

// API Operations
#import <BoxSDK/BoxAPIOperation.h>
#import <BoxSDK/BoxAPIOAuth2ToJSONOperation.h>
#import <BoxSDK/BoxAPIAuthenticatedOperation.h>
#import <BoxSDK/BoxAPIJSONOperation.h>
#import <BoxSDK/BoxAPIMultipartToJSONOperation.h>
#import <BoxSDK/BoxAPIDataOperation.h>

// Request building
#import <BoxSDK/BoxAPIRequestBuilder.h>
#import <BoxSDK/BoxFilesRequestBuilder.h>
#import <BoxSDK/BoxFoldersRequestBuilder.h>
#import <BoxSDK/BoxSharedObjectBuilder.h>
#import <BoxSDK/BoxUsersRequestBuilder.h>
#import <BoxSDK/BoxCommentsRequestBuilder.h>

// API Resource Managers
#import <BoxSDK/BoxAPIResourceManager.h>
#import <BoxSDK/BoxFilesResourceManager.h>
#import <BoxSDK/BoxFoldersResourceManager.h>
#import <BoxSDK/BoxSearchResourceManager.h>
#import <BoxSDK/BoxUsersResourceManager.h>
#import <BoxSDK/BoxCommentsResourceManager.h>
#import <BoxSDK/BoxSearchRequestBuilder.h>

// API models
#import <BoxSDK/BoxModel.h>
#import <BoxSDK/BoxModelComparators.h>
#import <BoxSDK/BoxCollection.h>
#import <BoxSDK/BoxItem.h>
#import <BoxSDK/BoxFile.h>
#import <BoxSDK/BoxFolder.h>
#import <BoxSDK/BoxUser.h>
#import <BoxSDK/BoxWebLink.h>
#import <BoxSDK/BoxComment.h>

// Item Picker
#import <BoxSDK/BoxItemPickerHelper.h>
#if TARGET_OS_IOS
#import <BoxSDK/BoxItemPickerViewController.h>
#import <BoxSDK/BoxItemPickerTableViewController.h>
#endif
#import <BoxSDK/BoxItemPickerNavigationController.h>

@protocol BOXItemPickerDelegate;

extern NSString *const BoxAPIBaseURL;

/**
 * The BoxSDK class is a class that exposes a [Box V2 API Rest Client](http://developers.box.com/docs/).
 *
 * Access to this class and all other components of the BoxSDK can be granted by including `<BoxSDK/BoxSDK.h>`
 * in your source code.
 *
 * This class provides a class method sharedSDK which provides a preconfigured SDK client,
 * including a BoxOAuth2Session and a BoxAPIQueueManager.
 *
 * This class also exposes several BoxAPIResourceManager instances. These include:
 *
 * - BoxFilesResourceManager
 * - BoxFoldersResourceManager
 *
 * This class may be instantiated directly. It is up to the caller to connect the BoxOAuth2Session and
 * BoxAPIQueueManager to the BoxAPIResourceManager instances in this case.
 *
 * Logging and Assertions
 * ======================
 * When compiling a `DEBUG` build of the SDK, logging and assertions are enabled.
 *
 * The Box SDK has fairly verbose logging in `DEBUG` builds that relays internal SDK state,
 * particularly during network activity. These logs are always compiled out in Release builds
 * and they can be disabled in `DEBUG` builds by defining the `BOX_DISABLE_DEBUG_LOGGING`
 * macro when compiling the SDK. See `BoxLog.h`.
 *
 * Assertions are always enabled in `DEBUG` builds; in Release builds, assertions are compiled
 * out. The Box SDK makes assertions about internal invariants, for example, when performing
 * network operations or parsing model classes.
 *
 * @warning If you wish to support multiple BoxOAuth2Session instances (multi-account support),
 * the recommended approach is to instantiate multiple instances of BoxSDK. Each BoxSDK instance's
 * OAuth2Session and queueManager hold references to each other to enable automatic token refresh.
 */
@interface BoxSDK : NSObject

/** @name SDK client objects */

/** The base URL for all API operations including OAuth2. */
@property (nonatomic, readwrite, strong) NSString *APIBaseURL;

/**
 * The BoxSDK's OAuth2 session. This session is shared with the queueManager,
 * filesManager, and foldersManager.
 */
@property (nonatomic, readwrite, strong) BoxOAuth2Session *OAuth2Session;

/**
 * The BoxSDK's queue manager. All API calls are scheduled by this queue manager.
 * The queueManager is shared with the OAuth2Session (for making authorization and refresh
 * calls) and the filesManager and foldersManager (for making API calls).
 */
@property (nonatomic, readwrite, strong) BoxAPIQueueManager *queueManager;

/** @name API resource managers */

/**
 * The filesManager grants the ability to make API calls related to files on Box.
 * These API calls include getting file information, uploading new files, uploading
 * new file versions, and downloading files.
 */
@property (nonatomic, readwrite, strong) BoxFilesResourceManager *filesManager;

/**
 * The foldersManager grants the ability to make API calls related to folders on Box.
 * These API calls include getting file information, listing the contents of a folder,
 * and managing the trash.
 */
@property (nonatomic, readwrite, strong) BoxFoldersResourceManager *foldersManager;

/**
 * The searchManager grants the ability to search a user's Box account.
 */
@property (nonatomic, readwrite, strong) BoxSearchResourceManager *searchManager;

/**
 * The usersManager grants the ability to make API calls related to users on Box.
 * These API calls include getting user information, getting the currently authorized
 * user's information, and admin user management.
 */
@property (nonatomic, readwrite, strong) BoxUsersResourceManager *usersManager;

/**
 * The commentsManager grants the ability to make API calls related to comments on Box.
 * These API calls include getting comment information, creating a comment, and modifying a comment
 */
@property (nonatomic, readwrite, strong) BoxCommentsResourceManager *commentsManager;

#pragma mark - Globally accessible API singleton instance
/** @name Shared SDK client */

/**
 * Returns the BoxSDK's default SDK client
 *
 * This method is guaranteed to only instantiate one sharedSDK over the lifetime of an app.
 *
 * This client must be configured with your client ID and client secret (see the
 * [Box OAuth2 documentation](http://developers.box.com/oauth/)). One possibility is to
 * configure the SDK in your application's App Delegate like so:
 *
 * <pre><code>// somewhere in your application delegate's - (BOOL)application:didFinishLaunchingWithOptions:
 * [BoxSDK sharedSDK].OAuth2Session.clientID = @"your_client_ID";
 * [BoxSDK sharedSDK].OAuth2Session.clientSecret = @"your_client_secret";</pre></code>
 *
 * *Note*: sharedSDK returns a BoxSDK configured with a BoxParallelOAuth2Session and a BoxParallelAPIQueueManager.
 *   These allow for up to 10 parallel uploads and 10 parallel downloads, while still providing threadsafe
 *   OAuth2 tokens.
 * @return a preconfigured SDK client
 */
+ (BoxSDK *)sharedSDK;

#pragma mark - Setters
/** @name Setters */

/**
 * Sets the SDK client API base URL and sets the URL on OAuth2Session and instances of BoxAPIResourceManager
 *
 * @param APIBaseURL An NSString containing the API base URL. The
 *   [Box API V2 documentation](http://developers.box.com/docs/#api-basics) states that this url is
 *   https://api.box.com. This String should not include the API Version
 */
- (void)setAPIBaseURL:(NSString *)APIBaseURL;


#if TARGET_OS_IOS
#pragma mark - Folder Picker
/** @name Folder Picker */

/**
 * Initializes an itemPicker according to the caching options provided as parameters
 *
 * @param rootFolderID The root folder where to start browsing.
 * @param thumbnailsEnabled Enables/disables thumbnail management.
 *   If set to NO, only file icons will be displayed
 * @param cachedThumbnailsPath The absolute path for storing cached thumbnails.
 *   If set to nil, the folder picker will not cache thumbnails, only download them on the fly.
 * @param selectableObjectType The kind of selection the created itemPicker should perform.
 * @return A BoxItemPickerViewController.
 */
- (BoxItemPickerViewController *)itemPickerWithRootFolderID:(NSString *)rootFolderID
                                               thumbnailsEnabled:(BOOL)thumbnailsEnabled
                                           cachedThumbnailsPath:(NSString *)cachedThumbnailsPath
                                           selectableObjectType:(BoxItemPickerObjectType)selectableObjectType;

/**
 * Initializes an itemPicker according to the caching options provided as parameters
 *
 * @param delegate The delegate of the picker we are going to initialize.
 * @param selectableObjectType The kind of selection the created itemPicker should perform.
 * @return A BoxItemPickerViewController.
 */
- (BoxItemPickerViewController *)itemPickerWithDelegate:(id <BOXItemPickerDelegate>)delegate 
                                   selectableObjectType:(BoxItemPickerObjectType)selectableObjectType;
#endif

#pragma mark - Ressources Bundle
/** @name Ressources Bundle */

/**
 * The bundle containing SDK resource assets and icons.
 */
+ (NSBundle *)resourcesBundle;

@end
