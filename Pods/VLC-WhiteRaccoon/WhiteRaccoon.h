//  WhiteRaccoon
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.



#ifdef DEBUG
#	define InfoLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#	define InfoLog(...)
#endif


#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

@class WRRequest;
@class WRRequestQueue;
@class WRRequestError;
@class WRRequestListDirectory;

#pragma mark - Global Constants, Variables, Structs and Enums

typedef enum {
    kWRUploadRequest,
	kWRDownloadRequest,
    kWRDeleteRequest,
    kWRCreateDirectoryRequest,
	kWRListDirectoryRequest
} WRRequestTypes;


typedef enum {
    kWRFTP
} WRSchemes;


typedef enum {
    kWRDefaultBufferSize = 32768
} WRBufferSizes;


typedef enum {
    kWRDefaultTimeout = 30
} WRTimeouts;


#pragma mark - WRStreamInfo

@interface WRStreamInfo:NSObject
@property (nonatomic, strong) NSOutputStream    *writeStream;
@property (nonatomic, strong) NSInputStream     *readStream;
@property (nonatomic, assign) long long         bytesConsumedThisIteration;
@property (nonatomic, assign) long long         bytesConsumedInTotal;
@property (nonatomic, assign) float             completedPercentage;
@property (nonatomic, assign) long long         maximumSize;
@property (nonatomic, assign) UInt8            *buffer;

@end

#pragma mark - WRRequestDelegate

@protocol WRRequestDelegate  <NSObject>

@required
- (void)requestCompleted:(WRRequest *) request;
- (void)requestFailed:(WRRequest *) request;

@optional
- (void)requestStarted:(WRRequest *)request;
- (BOOL)shouldOverwriteFileWithRequest: (WRRequest *) request;
- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize;

@end


#pragma mark - WRQueueDelegate

@protocol WRQueueDelegate  <WRRequestDelegate>

@required
- (void) queueCompleted:(WRRequestQueue *)queue;


@end
#pragma mark - WRBase
//Abstract class, do not instantiate
@interface WRBase : NSObject {
@protected
    NSString * path;
    NSString * hostname;
}

@property (nonatomic, strong) NSString * username;
@property (nonatomic, assign) WRSchemes schemeId;
@property (weak, nonatomic, readonly) NSString * scheme;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSString * hostname;
@property (weak, nonatomic, readonly) NSString * credentials;
@property (weak, nonatomic, readonly) NSURL * fullURL;
@property (weak, nonatomic, readonly) NSString * fullURLString;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, assign) BOOL passive;
@property (nonatomic, strong) WRRequestError * error;

- (void) start;
- (void) destroy;

+(NSDictionary *) cachedFolders;
+(void) addFoldersToCache:(NSArray *) foldersArray forParentFolderPath:(NSString *) key;

@end

#pragma mark - WRRequest

@interface WRRequest : WRBase

@property (nonatomic, strong) WRRequest * nextRequest;
@property (nonatomic, strong) WRRequest * prevRequest;
@property (nonatomic, readonly) WRRequestTypes type;
@property (nonatomic, weak) id<WRRequestDelegate> delegate;
@property (strong, nonatomic, readonly) WRStreamInfo * streamInfo;
@property (nonatomic, assign) BOOL didManagedToOpenStream;

@end

#pragma mark - WRRequestDownload

@interface WRRequestDownload : WRRequest<NSStreamDelegate>

@property (nonatomic, readwrite) BOOL downloadToMemoryBlock;
@property (nonatomic, retain) NSURL *downloadLocation;
@property (nonatomic, strong) NSMutableData * receivedData;

- (void)startWithFullURL:(NSURL *)fullURL;

@end

#pragma mark - WRRequestUpload

@interface WRRequestUpload : WRRequest<WRRequestDelegate, NSStreamDelegate>

@property (nonatomic, strong) WRRequestListDirectory * listrequest;
@property (nonatomic, strong) NSData * sentData;

@end

#pragma mark - WRRequestDelete

@interface WRRequestDelete : WRRequest<NSStreamDelegate> {
    BOOL isDirectory;
}

@end

#pragma mark - WRRequestCreateDirectory

@interface WRRequestCreateDirectory : WRRequestUpload<NSStreamDelegate>

@end

#pragma mark - WRRequestListDir

@interface WRRequestListDirectory : WRRequestDownload<NSStreamDelegate>

@property (nonatomic, strong) NSArray * filesInfo;

@end

#pragma mark - WRRequestQueue

//  Used to add requests (read, write) to a queue.
//  The request will be sent to the server in the order in which they were added.
//  If an error occures on one of the operations

@interface WRRequestQueue : WRBase<WRRequestDelegate> {
@private
    WRRequest * headRequest;
    WRRequest * tailRequest;

}

@property (nonatomic, strong) id<WRQueueDelegate> delegate;

- (void) addRequest:(WRRequest *) request;
- (void) addRequestInFront:(WRRequest *) request;
- (void) addRequestsFromArray: (NSArray *) array;
- (void) removeRequestFromQueue:(WRRequest *) request;

@end

typedef enum {
    //client errors
    kWRFTPClientHostnameIsNil = 901,
    kWRFTPClientCantOpenStream = 902,
    kWRFTPClientCantWriteStream = 903,
    kWRFTPClientCantReadStream = 904,
    kWRFTPClientSentDataIsNil = 905,
    kWRFTPClientFileAlreadyExists = 907,
    kWRFTPClientCantOverwriteDirectory = 908,
    kWRFTPClientStreamTimedOut = 909,

    // 400 FTP errors
    kWRFTPServerAbortedTransfer = 426,
    kWRFTPServerResourceBusy = 450,
    kWRFTPServerCantOpenDataConnection = 425,

    // 500 FTP errors
    kWRFTPServerUserNotLoggedIn = 530,
    kWRFTPServerFileNotAvailable = 550,
    kWRFTPServerStorageAllocationExceeded = 552,
    kWRFTPServerIllegalFileName = 553,
    kWRFTPServerUnknownError

} WRErrorCodes;

#pragma mark - WRRequestError

@interface WRRequestError : NSObject

@property (nonatomic, assign) WRErrorCodes errorCode;
@property (weak, nonatomic, readonly) NSString * message;

- (WRErrorCodes) errorCodeWithError:(NSError *) error;

@end
