//
//  BoxAPIResourceManager.h
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BoxSDKConstants.h" // imported for BoxAPIHTTPMethod typedef
#import "BoxAPIJSONOperation.h" // imported for BoxAPIJSONSuccessBlock typedef

@class BoxAPIQueueManager, BoxCollection, BoxOAuth2Session;

typedef void (^BoxSuccessfulDeleteBlock)(NSString *ID);
typedef void (^BoxCollectionBlock)(BoxCollection *collection);

/**
 * BoxAPIResourceManager is an abstract base class representing a Box API resource and
 * the API calls you can make on that resource. In the Box API, a resource is the first
 * of the API URL after the version number. For example, `https://api.box.com/2.0/files/12345`
 * represents an operation on the [files resource](BoxFilesResourceManager). Because this is
 * an abstract class, you should not instantiate it directly. Instead, instantiate one of its
 * concrete subclasses:
 *
 * - BoxFilesResourceManager
 * - BoxFoldersResourceManager
 *
 * Subclasses of BoxAPIResourceManager should only issue authenticated API calls. This means
 * they should only enqueue subclasses of BoxAPIAuthenticatedOperation.
 *
 * This class provides helper methods to aid subclasses in issuing API calls.
 * 
 */
@interface BoxAPIResourceManager : NSObject

/** @name API properties */

/**
 * The base URL for all API calls. This should be set on initialization.
 *
 * In normal usage, this is `https://api.box.com`.
 *
 * @see [BoxSDK sharedSDK]
 */
@property (nonatomic, readwrite, strong) NSString *APIBaseURL;

/**
 * The API version for all API calls. This should be set on initialization.
 *
 * This should always be a 2.x version. This SDK works with the V2 API.
 *
 * @see [BoxSDK sharedSDK]
 */
@property (nonatomic, readwrite, strong) NSString *APIVersion;

/** @name SDK properties */

/**
 * The BoxOAuth2Session to use to sign requests. This session is attached to
 * all operations the resource manager enqueues.
 */
@property (nonatomic, readwrite, weak) BoxOAuth2Session *OAuth2Session;

/**
 * The queue on which to enqueue API operations.
 */
@property (nonatomic, readwrite, weak) BoxAPIQueueManager *queueManager;

/** @name Initialization */

/**
 * Designated initializer.
 *
 * @param baseURL The base URL to use when issuing API calls. Normally this should be `BoxAPIBaseURL`.
 * @param OAuth2Session The BoxOAuth2Session to pass through to BoxAPIAuthenticatedOperation instances to sign requests.
 * @param queueManager The queue on which to schedule API requests.
 *
 * @return An initialized BoxAPIResourceManager.
 */
- (id)initWithAPIBaseURL:(NSString *)baseURL OAuth2Session:(BoxOAuth2Session *)OAuth2Session queueManager:(BoxAPIQueueManager *)queueManager;

/** @name API call helper methods */

/**
 * Returns a canonical URL for an API request given its components. Box API URLs are made up of four components.
 * This helper uses APIBaseURL and APIVersion to construct the URL.
 *
 * A URL containing all components looks like the following:
 *
 * <pre><code>https://api.box.com/files/12345/versions/current</code></pre>
 *
 * The components are:
 *
 * - resource: `files`
 * - ID: `12345`
 * - subresource: `versions`
 * - subID: `current`
 *
 * @param resource The resource component of the URL.
 * @param ID The ID component of the URL. May be nil.
 * @param subresource The subresource component of the URL. May be nil.
 * @param subID The subresource ID component of the URL. May be nil.
 *
 * @return The canonical URL of a request given the components.
 */
- (NSURL *)URLWithResource:(NSString *)resource ID:(NSString *)ID subresource:(NSString *)subresource subID:(NSString *)subID;

/**
 * Return a configured BoxAPIJSONOperation to make an API request with.
 *
 * @param URL The canonical URL of the request.
 * @param HTTPMethod The HTTP method of the request. One of `BoxAPIHTTPMethodGET`, `BoxAPIHTTPMethodPOST`,
 *   `BoxAPIHTTPMethodPUT`, `BoxAPIHTTPMethodDELETE`, `BoxAPIHTTPMethodOPTIONS`.
 * @param queryParameters Key value pairs to URL encode and include as the query string of the request.
 * @param bodyDictionary Key value pairs for the operation to encode and include as the HTTP body.
 * @param successBlock A `BoxAPIJSONSuccessBlock` to execute on a successful API call.
 * @param failureBlock A `BoxAPIJSONFailureBlock` to execute on a failed API call.
 *
 * @return A configured BoxAPIJSONOperation to make an API request with.
 */
- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary JSONSuccessBlock:(BoxAPIJSONSuccessBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Return a configured BoxAPIJSONOperation to make an API request with. This wraps successBlock
 * in a `BoxAPIJSONSuccessBlock` and delegates to
 * JSONOperationWithURL:HTTPMethod:queryStringParameters:bodyDictionary:JSONSuccessBlock:failureBlock:
 *
 * @param URL The canonical URL of the request.
 * @param HTTPMethod The HTTP method of the request. One of `BoxAPIHTTPMethodGET`, `BoxAPIHTTPMethodPOST`,
 *   `BoxAPIHTTPMethodPUT`, `BoxAPIHTTPMethodDELETE`, `BoxAPIHTTPMethodOPTIONS`.
 * @param queryParameters Key value pairs to URL encode and include as the query string of the request.
 * @param bodyDictionary Key value pairs for the operation to encode and include as the HTTP body.
 * @param successBlock A `BoxCollectionBlock` to execute on a successful API call.
 * @param failureBlock A `BoxAPIJSONFailureBlock` to execute on a failed API call.
 *
 * @return A configured BoxAPIJSONOperation to make an API request with.
 *
 * @see JSONOperationWithURL:HTTPMethod:queryStringParameters:bodyDictionary:JSONSuccessBlock:failureBlock:
 */
- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary collectionSuccessBlock:(BoxCollectionBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Return a configured BoxAPIJSONOperation to make an API request with. This wraps successBlock
 * in a `BoxAPIJSONSuccessBlock` and delegates to
 * JSONOperationWithURL:HTTPMethod:queryStringParameters:bodyDictionary:JSONSuccessBlock:failureBlock:
 *
 * @param URL The canonical URL of the request.
 * @param HTTPMethod The HTTP method of the request. One of `BoxAPIHTTPMethodGET`, `BoxAPIHTTPMethodPOST`,
 *   `BoxAPIHTTPMethodPUT`, `BoxAPIHTTPMethodDELETE`, `BoxAPIHTTPMethodOPTIONS`.
 * @param queryParameters Key value pairs to URL encode and include as the query string of the request.
 * @param bodyDictionary Key value pairs for the operation to encode and include as the HTTP body.
 * @param successBlock A `BoxSuccessfulDeleteBlock` to execute on a successful API call.
 * @param failureBlock A `BoxAPIJSONFailureBlock` to execute on a failed API call.
 * @param modelID The ID of the model refered to by this API call. This is passed to successBlock.
 *
 * @return A configured BoxAPIJSONOperation to make an API request with.
 *
 * @see JSONOperationWithURL:HTTPMethod:queryStringParameters:bodyDictionary:JSONSuccessBlock:failureBlock:
 */
- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary deleteSuccessBlock:(BoxSuccessfulDeleteBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock modelID:(NSString *)modelID;

@end
