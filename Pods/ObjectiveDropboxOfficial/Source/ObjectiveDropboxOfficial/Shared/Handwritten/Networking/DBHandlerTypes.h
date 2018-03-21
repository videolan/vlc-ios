///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Public handler types.
///

#import <Foundation/Foundation.h>

@class DBASYNCPollError;
@class DBFILESUploadSessionFinishBatchJobStatus;
@class DBFILESUploadSessionFinishBatchResultEntry;
@class DBRequestError;

NS_ASSUME_NONNULL_BEGIN

/// The progress block to be executed in the event of a request update. The first argument is the number of bytes
/// downloaded. The second argument is the number of total bytes downloaded. And the third argument is the number of
/// total bytes expected to be downloaded.
typedef void (^DBProgressBlock)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

/// Special custom response block for batch upload. The first argument is a mapping of client-side NSURLs to batch
/// upload result entries (each of which indicates the success / failure of the upload for the corresponding file). This
/// object will be nonnull if the final call to `/upload_session/finish_batch/check` is successful. The second argument
/// is the route-specific error from `/upload_session/finish_batch/check`, which is generally not able to be handled at
/// runtime, but instead should be used for debugging purposes. This object will be nonnull if there is a route-specific
/// error from the call to `/upload_session/finish_batch/check`. The third argument is the general request error from
/// `/upload_session/finish_batch/check`. This object will be nonnull if there is a request error from the call to
/// `/upload_session/finish_batch/check`. The fourth argument is a mapping of client-side NSURLs to general request
/// errors, which occured during the upload of the corresponding file.
typedef void (^DBBatchUploadResponseBlock)(
    NSDictionary<NSURL *, DBFILESUploadSessionFinishBatchResultEntry *> *_Nullable fileUrlsToBatchResultEntries,
    DBASYNCPollError *_Nullable finishBatchRouteError, DBRequestError *_Nullable finishBatchRequestError,
    NSDictionary<NSURL *, DBRequestError *> *fileUrlsToRequestErrors);

/// Special custom response block for performing SDK token migration between API v1 tokens and API v2 tokens. First
/// argument indicates whether the migration should be attempted again (primarily when there was no active network
/// connection). The second argument indicates whether the supplied app key and / or secret is invalid for some or
/// all tokens. The third argument is a list of token data for each token that was unsuccessfully migrated. Each
/// element in the list is a list of length 4, where the first element is the Dropbox user ID, the second element
/// is the OAuth 1 access token, the third element is the OAuth 1 access token secret, and the fourth element
/// is the consumer app key that was stored with the token.
typedef void (^DBTokenMigrationResponseBlock)(BOOL shouldRetry, BOOL invalidAppKeyOrSecret,
                                              NSArray<NSArray<NSString *> *> *unsuccessfullyMigratedTokenData);

NS_ASSUME_NONNULL_END
