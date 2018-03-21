//
//  BoxFilesResourceManager.h
//  BoxSDK
//
//  Created on 3/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BoxAPIResourceManager.h"
#import "BoxAPIJSONOperation.h" // imported for BoxAPIJSONFailureBlock typedef
#import "BoxAPIMultipartToJSONOperation.h"
#import "BoxAPIDataOperation.h"

@class BoxFile, BoxItem;
@class BoxFilesRequestBuilder;

typedef void (^BoxFileBlock)(BoxFile *file);

typedef enum {
    BoxThumbnailSize32  = 32,
    BoxThumbnailSize64  = 64,
    BoxThumbnailSize128 = 128,
    BoxThumbnailSize256 = 256
} BoxThumbnailSize;

/**
 * BoxFilesResourceManager allows you to access and manipulate files via the Box API. This class is
 * a concrete subclass of BoxAPIResourceManager. This class allows you to manipulate [BoxFiles]([BoxFile])
 * referred to by their `modelID`, which is an `NSString`.
 *
 * This class enables the following operations:
 *
 * - [Get a file's information](http://developers.box.com/docs/#files-get)
 * - [Edit a file's information](http://developers.box.com/docs/#files-update-a-files-information)
 * - [Copy a file](http://developers.box.com/docs/#files-copy-a-file)
 * - [Delete a file](http://developers.box.com/docs/#files-delete-a-file)
 * - [Upload a file](http://developers.box.com/docs/#files-upload-a-file)
 * - [Upload a new version of a file (overwrite)](http://developers.box.com/docs/#files-upload-a-new-version-of-a-file)
 * - [Download a file](http://developers.box.com/docs/#files-download-a-file)
 *
 * Callbacks and typedefs
 * ======================
 * This class defines the `BoxFileBlock` type for successful API calls that return a BoxFile object:
 *
 * <pre><code>typedef void (^BoxFileBlock)(BoxFile *file);</code></pre>
 *
 */
@interface BoxFilesResourceManager : BoxAPIResourceManager

/** @name Upload helpers */

/**
 * API uploads use a different base URL than other API calls.
 *
 * See [the official documentation](http://developers.box.com/docs/#files-upload-a-file)
 */
@property (nonatomic, readwrite, strong) NSString *uploadBaseURL;

/**
 * Uploads may use a different version of the API than other API operations.
 */
@property (nonatomic, readwrite, strong) NSString *uploadAPIVersion;

/**
 * Returns a canonical URL for an API upload request given its components.
 * Box API upload URLs are made up of three components.
 * This helper uses uploadBaseURL and uploadAPIVersion to construct the URL.
 *
 * An upload URL containing all components looks like the following:
 *
 * <pre><code>https://upload.box.com/api/2.1/files/12345/content</code></pre>
 *
 * The components are:
 *
 * - resource: `files`
 * - ID: `12345`
 * - subresource: `content`
 *
 * A new file upload only makes use of the resource and ID parameters and looks like
 * the following:
 *
 * <pre><code>https://upload.box.com/api/2.1/files/content</code></pre>
 *
 * @param resource The resource component of the URL.
 * @param ID The ID component of the URL. May be nil.
 * @param subresource The subresource component of the URL. May be nil.
 *
 * @return The canonical URL of an upload request given the components.
 */
- (NSURL *)uploadURLWithResource:(NSString *)resource ID:(NSString *)ID subresource:(NSString *)subresource;

/** @name API calls */

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch a file's information.
 *
 * See the Box documentation for [getting a file's information](http://developers.box.com/docs/#files-get).
 *
 * @param fileID The `modelID` of a BoxFile you wish to fetch information for.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)fileInfoWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to edit a file's properties.
 *
 * See the Box documentation for [editing a file's information](http://developers.box.com/docs/#files-update-a-files-information).
 *
 * @param fileID The `modelID` of a BoxFile you wish to fetch information for.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)editFileWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to copy a file on Box.
 *
 * See the Box documentation for [copying a file](http://developers.box.com/docs/#files-copy-a-file).
 *
 * @param fileID The `modelID` of a BoxFile you wish to fetch information for.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)copyFileWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to delete a file on Box.
 *
 * See the Box documentation for [deleting a file](http://developers.box.com/docs/#files-delete-a-file).
 *
 * @param fileID The `modelID` of a BoxFile you wish to fetch information for.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `DELETE` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)deleteFileWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

#pragma mark - uploadFileAtPath
/**
 * Returns and enqueues an upload operation for the file located at the given path.
 *
 *
 * @param path The location of the file to upload.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   Must include the `name` property, which is used as the name of the uploaded file.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully written to the underlying `NSURLConnection`.
 *
 * @return A configured upload operation.
 */
- (BoxAPIMultipartToJSONOperation *)uploadFileAtPath:(NSString *)path requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock;


#pragma mark - uploadFileWithData:
/** @name Uploading a new file */


/**
 * Returns and enqueues an upload operation for the given data.
 *
 * @warning Because NSData objects are fully buffered in memory, only use this method for small files. Prefer to use
 *   an NSInputStream whenever possible.
 *
 * @see uploadFileWithInputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 *
 * @param data The file to upload as an NSData.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   Must include the `name` property, which is used as the name of the uploaded file.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully written to the underlying `NSURLConnection`.
 *
 * @return A configured upload operation.
 * @see uploadFileWithData:MIMEType:requestBuilder:success:failure:progress:
 */
- (BoxAPIMultipartToJSONOperation *)uploadFileWithData:(NSData *)data requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock;

/**
 * Returns and enqueues an upload operation for the given data.
 *
 * @warning Because NSData objects are fully buffered in memory, only use this method for small files. Prefer to use
 *   an NSInputStream whenever possible.
 *
 * @see uploadFileWithInputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 *
 * @param data The file to upload as an NSData.
 * @param MIMEType The MIME type of the file being uploaded. This parameter is optional and may be nil.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   Must include the `name` property, which is used as the name of the uploaded file.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully written to the underlying `NSURLConnection`.
 *
 * @return A configured upload operation.
 */
- (BoxAPIMultipartToJSONOperation *)uploadFileWithData:(NSData *)data MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock;

#pragma mark - uploadFileWithInputStream:

/**
 * Returns and enqueues an upload operation for the given stream.
 *
 * To stream an upload from disk, create an input stream as follows:
 *
 * <pre><code>NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];</code></pre>
 *
 * @param inputStream The file to upload as an NSInputStream.
 * @param contentLength The length in bytes of the data served by inputStream.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   Must include the `name` property, which is used as the name of the uploaded file.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A configured upload operation.
 *
 * @see uploadFileWithInputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 */
- (BoxAPIMultipartToJSONOperation *)uploadFileWithInputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Returns and enqueues an upload operation for the given stream.
 *
 * To stream an upload from disk, create an input stream as follows:
 *
 * <pre><code>NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];</code></pre>
 *
 * @param inputStream The file to upload as an NSInputStream.
 * @param contentLength The length in bytes of the data served by inputStream.
 * @param MIMEType The MIME type of the file being uploaded. This parameter is optional and may be nil.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   Must include the `name` property, which is used as the name of the uploaded file.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully written to the underlying `NSURLConnection`.
 *
 * @return A configured upload operation.
 */
- (BoxAPIMultipartToJSONOperation *)uploadFileWithInputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock;

#pragma mark - overwriteFileWithID:data:
/** @name Upload a new version of a file (overwrite) */

/**
 * Returns and enqueues an overwrite operation for the given data.
 *
 * @warning Because NSData objects are fully buffered in memory, only use this method for small files. Prefer to use
 *   an NSInputStream whenever possible.
 *
 * @see overwriteFileWithID:inputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 *
 * @param fileID The modelID of the file to overwrite.
 * @param data The file to upload as an NSData.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A configured overwrite operation.
 *
 * @see overwriteFileWithID:data:MIMEType:requestBuilder:success:failure:progress:
*/
- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID data:(NSData *)data requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Returns and enqueues an overwrite operation for the given data.
 *
 * @warning Because NSData objects are fully buffered in memory, only use this method for small files. Prefer to use
 *   an NSInputStream whenever possible.
 *
 * @see overwriteFileWithID:inputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 *
 * @param fileID The modelID of the file to overwrite.
 * @param data The file to upload as an NSData.
 * @param MIMEType The MIME type of the file being uploaded. This parameter is optional and may be nil.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully written to the underlying `NSURLConnection`.
 *
 * @return A configured overwrite operation.
 * @see overwriteFileWithID:inputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 */
- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID data:(NSData *)data MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock;

#pragma mark - overwriteFileWithID:inputStream:

/**
 * Returns and enqueues an overwrite operation for the given stream.
 *
 * To stream an upload from disk, create an input stream as follows:
 *
 * <pre><code>NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];</code></pre>
 *
 * @param fileID The modelID of the file to overwrite.
 * @param inputStream The file to upload as an NSInputStream.
 * @param contentLength The length in bytes of the data served by inputStream.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A configured overwrite operation.
 * @see overwriteFileWithID:inputStream:contentLength:MIMEType:requestBuilder:success:failure:progress:
 */
- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID inputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Returns and enqueues an overwrite operation for the given stream.
 *
 * To stream an upload from disk, create an input stream as follows:
 *
 * <pre><code>NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];</code></pre>
 *
 * @param fileID The modelID of the file to overwrite.
 * @param inputStream The file to upload as an NSInputStream.
 * @param contentLength The length in bytes of the data served by inputStream.
 * @param MIMEType The MIME type of the file being uploaded. This parameter is optional and may be nil.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: The builder will convert body data to multipart POST parameters.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully written to the underlying `NSURLConnection`.
 *
 * @return A configured overwrite operation.
 */
- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID inputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock;

#pragma mark - downloadFileWithID:
/** @name Download a file */

/**
 * Return and enqueue an operation to download a file to a specific path.
 *
 * @param file the file to download
 * @param destinationPath  The path where the file content will be downloaded to.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock  A callback that is triggered when data is successfully received from the underlying `NSURLConnection`.
 *
 * @return An operation to download a file.
 *
 * @see downloadFileWithID:outputStream:requestBuilder:success:failure:progress:
 */
- (BoxAPIDataOperation *)downloadFile:(BoxFile *)file destinationPath:(NSString *)destinationPath success:(BoxDownloadSuccessBlock)successBlock failure:(BoxDownloadFailureBlock)failureBlock progress:(BoxAPIDataProgressBlock)progressBlock;

/**
 * Return and enqueue an operation to download a file.
 *
 * To stream a download to disk, create an output stream as follows:
 *
 * <pre><code>NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];</code></pre>
 *
 * @param fileID The modelID of the file to download.
 * @param outputStream The output stream of to write the download to.
 * @param builder A BoxFilesRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 * @param progressBlock A callback that is triggered when data is successfully received from the underlying `NSURLConnection`.
 *
 * @return An operation to download a file.
 */
- (BoxAPIDataOperation *)downloadFileWithID:(NSString *)fileID outputStream:(NSOutputStream *)outputStream requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxDownloadSuccessBlock)successBlock failure:(BoxDownloadFailureBlock)failureBlock progress:(BoxAPIDataProgressBlock)progressBlock;

/**
 * Return and enqueue an operation to download a file's thumbnail. Currently
 * thumbnails are only available in .png format and will only be generated for
 * [image file formats](http://en.wikipedia.org/wiki/Image_file_formats).
 *
 * To stream a download to disk, create an output stream as follows:
 *
 * <pre><code>NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];</code></pre>
 *
 * @param fileID The modelID of the file to download.
 * @param outputStream The output stream of to write the download to.
 * @param thumbnailSize The minimum size of thumbnail in pixels.
 *   One of:
 *   
 *   - BoxThumbnailSize32
 *   - BoxThumbnailSize64
 *   - BoxThumbnailSize128
 *   - BoxThumbnailSize256
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return An operation to download a file.
 */
- (BoxAPIDataOperation *)thumbnailForFileWithID:(NSString *)fileID outputStream:(NSOutputStream *)outputStream thumbnailSize:(BoxThumbnailSize)thumbnailSize success:(BoxDownloadSuccessBlock)successBlock failure:(BoxDownloadFailureBlock)failureBlock;


#pragma mark - createSharedLinkForItem:

/** @name Share a file */
/**
 * Return and enqueue an operation to share a file.
 *
 * @param item The BOXItem to share.
 * @param builder A BOXFilesRequestBuilder instance that containts query parameter for the request.
 *  **Note** : Since this is a share request, the 'sharedLink' property is required for the share to succeeed.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *
 * @return An operation to share a file.
 */
- (BoxAPIJSONOperation *)createSharedLinkForItem:(BoxItem *)item withBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

@end
