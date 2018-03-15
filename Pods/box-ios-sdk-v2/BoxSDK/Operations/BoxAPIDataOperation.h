//
//  BoxAPIDataOperation.h
//  BoxSDK
//
//  Created on 2/27/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIAuthenticatedOperation.h"

// expectedTotalBytes may be NSURLResponseUnknownLength if the operation is unable to determine the
// content-length of the download
typedef void (^BoxDownloadSuccessBlock)(NSString *fileID, long long expectedTotalBytes);
typedef void (^BoxDownloadFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error);
// expectedTotalBytes may be NSURLResponseUnknownLength if the operation is unable to determine the
// content-length of the download
typedef void (^BoxAPIDataProgressBlock)(long long expectedTotalBytes, unsigned long long bytesReceived);

/**
 * BoxAPIDataOperation is a concrete subclass of BoxAPIAuthenticatedOperation.
 * This operation receives binary data from the Box API which may be in the form
 * of downloads or thumbnails.
 *
 * API calls to Box may fail with a 202 Accepted with an
 * empty body on Downloads of files and thumbnails.
 * This indicates that a file has successfully been uploaded but
 * is not yet available for download or has not yet been converted
 * to the requested thumbnail representation. In these cases, retry
 * after the period of time suggested in the Retry-After header
 *
 * Callbacks and typedefs
 * ======================
 * This class defines a number of block types for use in callback blocks. These are:
 *
 * <pre><code>typedef void (^BoxDownloadSuccessBlock)(NSString *fileID, long long expectedTotalBytes);
 * typedef void (^BoxDownloadFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error);
 * typedef void (^BoxAPIDataProgressBlock)(long long expectedTotalBytes, unsigned long long bytesReceived);</code></pre>
 *
 * **Note**: expectedTotalBytes may be `NSURLResponseUnknownLength` if the operation is unable to
 * determine the Content-Length of the download.
 *
 * @warning Because BoxAPIDataOperation holds references to `NSStream`s, it cannot be copied. Because it
 * cannot be copied, BoxAPIDataOperation instances cannot be automatically retried by the SDK in the event
 * of an expired OAuth2 access token. In this case, the operation will fail with error code
 * `BoxSDKOAuth2ErrorAccessTokenExpiredOperationCannotBeReenqueued`.
 */
@interface BoxAPIDataOperation : BoxAPIAuthenticatedOperation <NSStreamDelegate>

/** @name Streams */

/**
 * The output stream to write received bytes to. Received data is immediately written
 * to this output stream if possible. Otherwise it is buffered in memory.
 *
 * All received data from the API call is directed to this output stream. This means
 * that this operation does not processing of data once the connection terminates.
 *
 * **Note**: Creating an output stream to a file can be done easily using `NSOutputStream`:
 *
 * <pre><code>NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];</code></pre>
 *
 * @warning If you are manually reading from this output stream (for example with
 * a `CFStreamCreateBoundPair`) do not let data sit in the stream or you risk causing
 * a large file to buffer entirely in memory.
 */
@property (nonatomic, readwrite, strong) NSOutputStream *outputStream;

/** @name Callbacks */

/**
 * Called when the API call completes successfully with a 2xx status code.
 *
 * **Note**: All callbacks are executed on the same queue as the BoxAPIOperation they are associated with.
 * If you wish to interact with the UI in a callback block, dispatch to the main queue in the
 * callback block.
 */
@property (nonatomic, readwrite, strong) BoxDownloadSuccessBlock successBlock;

/**
 * Called when the API call returns an error with a non-2xx status code.
 *
 * **Note**: All callbacks are executed on the same queue as the BoxAPIOperation they are associated with.
 * If you wish to interact with the UI in a callback block, dispatch to the main queue in the
 * callback block.
 */
@property (nonatomic, readwrite, strong) BoxDownloadFailureBlock failureBlock;

/**
 * Called when the API call successfully receives bytes from the `NSURLConnection`.
 *
 * **Note**: All callbacks are executed on the same queue as the BoxAPIOperation they are associated with.
 * If you wish to interact with the UI in a callback block, dispatch to the main queue in the
 * callback block.
 */
@property (nonatomic, readwrite, strong) BoxAPIDataProgressBlock progressBlock;

/**
 * Call success or failure depending on whether or not an error has occurred during the request.
 * @see successBlock
 * @see failureBlock
 */
- (void)performCompletionCallback;

/**
 * When data is successfully received from [self.connection]([BoxAPIOperation connection]),
 * this method is called to trigger progressBlock.
 * @see progressBlock
 */
- (void)performProgressCallback;

/**
 * The fileID associated with this download request. This value is passed to progressBlock.
 * @see progressBlock
 */
@property (nonatomic, readwrite, strong) NSString *fileID;


/** @name Overridden methods */

/**
 * In addition to calling [super]([BoxAPIAuthenticatedOperation prepareAPIRequest]), schedule outputStream
 * in the current run loop and set `outputStream.delegate` to `self`.
 */
- (void)prepareAPIRequest;

/**
 * BoxAPIDataOperation should only ever be GET requests so there should not be a body.
 *
 * @param bodyDictionary This should always be nil
 * @return nil
 */
- (NSData *)encodeBody:(NSDictionary *)bodyDictionary;

/**
 * This method is called with by BoxAPIOperation with the assumption that all
 * data received from the `NSURLConnection` is buffered. This operation
 * streams all received data to its output stream, so do nothing in this method.
 *
 * @param data This data should be empty.
 */
- (void)processResponseData:(NSData *)data;

@end
