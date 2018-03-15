//
//  BoxAPIMultipartToJSONOperation.m
//  BoxSDK
//
//  Created on 2/27/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIMultipartToJSONOperation.h"

#import "BoxSDKErrors.h"
#import "BoxLog.h"

#define BOX_API_MULTIPART_CONTENT_DISPOSITION (@"Content-Disposition")
#define BOX_API_MULTIPART_CONTENT_TYPE        (@"Content-Type")
#define BOX_API_MULTIPART_CONTENT_LENGTH      (@"Content-Length")

#define BOX_API_OUTPUT_STREAM_BUFFER_SIZE     (32u << 10) // 32 KiB

#pragma mark - Form Boundary Helpers

static NSString *const BoxAPIMultipartFormBoundary = @"0xBoXSdKMulTiPaRtFoRmBoUnDaRy";
static NSString *const BoxAPIMultipartFormCRLF     = @"\r\n";

static NSString * BoxAPIMultipartInitialBoundary(void)
{
    return [NSString stringWithFormat:@"--%@%@", BoxAPIMultipartFormBoundary, BoxAPIMultipartFormCRLF];
}

static NSString * BoxAPIMultipartEncapsulationBoundary(void)
{
    return [NSString stringWithFormat:@"%@--%@%@", BoxAPIMultipartFormCRLF, BoxAPIMultipartFormBoundary, BoxAPIMultipartFormCRLF];
}

static NSString * BoxAPIMultipartFinalBoundary(void)
{
    return [NSString stringWithFormat:@"%@--%@--%@", BoxAPIMultipartFormCRLF, BoxAPIMultipartFormBoundary, BoxAPIMultipartFormCRLF];
}

static NSString * BoxAPIMultipartContentTypeHeader(void)
{
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoxAPIMultipartFormBoundary];
}

#pragma mark - Multipart Form pieces

typedef enum {
    BoxAPIMultipartPieceStateNotOpen = 0,
    BoxAPIMultipartPieceStateInitialBoundary,
    BoxAPIMultipartPieceStateHeaders,
    BoxAPIMultipartPieceStateBodyData,
    BoxAPIMultipartPieceStateFinalBoundary,
    BoxAPIMultipartPieceStateClosed,
} BoxAPIMultipartPieceState;

/**
 * This class encapsulates one multipart form parameter. It provides one
 * interface to extract the data associated with this multipart piece that
 * will ouput raw bytes from the underlying components that make up the piece.
 * All components are represented as sreams. Components that are not streams
 * are converted to streams.
 *
 * These components are:
 *
 * - A form boundary (either initial or encapsulation)
 * - Headers included in the multipart piece (i.e.: Content-Type, Content-Disposition)
 * - The body data associated with this piece
 * - An optional final form boundary
 *
 * Clients of this class are expected to configure these components through the given
 * properties before reading from the underlying components.
 *
 * Reading data from an instance of this class is implemented as a state machine.
 * Reading from each component is represented as a distinct state. The read method
 * will only read data from one component during a single invocation.
 *
 * The states are:
 * - not open
 * - initial boundary
 * - headers
 * - body data
 * - final boundary
 * - closed
 *
 * @warning This class is declared in a `.m` file and is used internally by BoxAPIMultipartTOJSONOperation
 * to implement [RFC 1876](http://tools.ietf.org/rfc/rfc1867.txt) compliant uploads.
 *
 * @warning This class presents an interface like an NSOutputStream, but it differs in several
 * key ways.
 */
@interface BoxAPIMultipartPiece : NSObject

/** @name State */

/**
 * Headers associated with the multipart piece. These include Content-Disposition,
 * Content-Length, and Content-Type.
 */
@property (nonatomic, readwrite, strong) NSMutableDictionary *headers;

/**
 * An input stream generated from encoding headers.
 */
@property (nonatomic, readwrite, strong) NSInputStream *headersInputStream;

/**
 * An input stream for the body of the piece.
 */
@property (nonatomic, readonly) NSInputStream *bodyInputStream;

/**
 * The length of the data in bodyInputStream.
 */
@property (nonatomic, readwrite, assign) unsigned long long bodyContentLength;

/**
 * Whether this piece is the first piece in the request. Consumers of this class
 * should set this property to `YES` on the first instance of this class
 * written to a connection's input stream.
 *
 * This property determines whether startBoundaryInputStream is an encapsulation
 * boundary or an initial boundary.
 */
@property (nonatomic, readwrite, assign) BOOL hasInitialBoundary;

/**
 * An input stream generated from the first boundary of this piece. This boundary
 * may either be an initial boundary or an encapsulation boundary.
 */
@property (nonatomic, readwrite, strong) NSInputStream *startBoundaryInputStream;

/**
 * Whether this piece is the last piece in the request. Consumers of this class
 * should set this property to `YES` on the last instance of this class
 * written to a connection's input stream.
 *
 * This property determines whether endBoundaryInputStream is empty or
 * a final boundary.
 */
@property (nonatomic, readwrite, assign) BOOL hasFinalBoundary;

/**
 * An input stream generated from the end boundary of this piece. This boundary
 * may either be empty or a final boundary.
 */
@property (nonatomic, readwrite, strong) NSInputStream *endBoundaryInputStream;

/**
 * Encapsulates the current input stream this piece is reading from.
 */
@property (nonatomic, readwrite, assign) BoxAPIMultipartPieceState state;

/** @name Initializers */

/**
 * Initialize a multipart piece with data as the body data
 *
 * @param data The data to be sent as the body of this multipart piece
 * @param fieldName The value of the name component of the Content-Disposition header for this piece.
 * @param filename If this piece is a file, the value of the filename parameter of the Content-Disposition
 *   header for this piece. filename should only be provided if this piece represents a file upload. Pass nil
 *   otherwise.
 */
- (id)initWithData:(NSData *)data fieldName:(NSString *)fieldName filename:(NSString *)filename;

/**
 * Initialize a multipart piece with data as the body data
 *
 * @param data The data to be sent as the body of this multipart piece
 * @param fieldName The value of the name component of the Content-Disposition header for this piece.
 * @param filename If this piece is a file, the value of the filename parameter of the Content-Disposition
 *   header for this piece. filename should only be provided if this piece represents a file upload. Pass nil
 *   otherwise.
 * @param MIMEType The MIME type of the provided data. This value will be included in this piece's Content-Type
 *   header. MIMEType is optional. Pass nil if you do not wish to provide it.
 */
- (id)initWithData:(NSData *)data fieldName:(NSString *)fieldName filename:(NSString *)filename MIMEType:(NSString *)MIMEType;

/**
 * Initialize a multipart piece with inputStream as the body data
 *
 * @param inputStream A stream containing the data to be sent as the body of this multipart piece
 * @param fieldName The value of the name component of the Content-Disposition header for this piece.
 * @param filename If this piece is a file, the value of the filename parameter of the Content-Disposition
 *   header for this piece. filename should only be provided if this piece represents a file upload. Pass nil
 *   otherwise.
 */
- (id)initWithInputStream:(NSInputStream *)inputStream fieldName:(NSString *)fieldName filename:(NSString *)filename;

/**
 * Initialize a multipart piece with inputStream as the body data
 *
 * @param inputStream A stream containing the data to be sent as the body of this multipart piece
 * @param fieldName The value of the name component of the Content-Disposition header for this piece.
 * @param filename If this piece is a file, the value of the filename parameter of the Content-Disposition
 *   header for this piece. filename should only be provided if this piece represents a file upload. Pass nil
 *   otherwise.
 * @param MIMEType The MIME type of the provided data. This value will be included in this piece's Content-Type
 *   header. MIMEType is optional. Pass nil if you do not wish to provide it.
 */
- (id)initWithInputStream:(NSInputStream *)inputStream fieldName:(NSString *)fieldName filename:(NSString *)filename MIMEType:(NSString *)MIMEType;

/** @name Piece data */

/**
 * The length in bytes of all components of this piece.
 *
 * @return The length in bytes of all components of this piece.
 */
- (unsigned long long)contentLength;

/**
 * The bytes representing the start boundary of this piece. This may be an encapsulation
 * boundary or an initial boundary.
 *
 * @see hasInitialBoundary
 *
 * @return The bytes representing the start boundary of this piece.
 */
- (NSData *)startBoundaryData;

/**
 * The bytes representing the end boundary of this piece. This may be empty
 * or a final boundary.
 *
 * @see hasFinalBoundary
 *
 * @return The bytes representing the end boundary of this piece.
 */
- (NSData *)endBoundaryData;

/**
 * The bytes representing the headers of this multipart piece.
 *
 * @return The bytes representing the headers of this multipart piece.
 */
- (NSData *)headersData;

/** @name Stream interaction */

/**
 * This method is the main interface of this class. It reads from the streams of the
 * underlying piece components and places read bytes into outputData.
 *
 * This method returns -1 on failure to read from any of its underlying streams.
 *
 * @warning Unlike an NSInputStream, this method may return 0, yet still have data left to
 * read. This occurs whenever the multipart piece is switching between its component
 * input streams. To determine whether a piece has data left to read, use hasBytesAvailable.
 *
 * @see hasBytesAvailable
 *
 * @warning Neither outputData nor *outputData may be nil. If either are nil, an assertion
 * failure will be raised.
 *
 * @param outputData Data read from the underlying streams will be written into outputData's byte array
 * @param length The maximum amount of data to read into outputData
 * @param error an NSError pointer to be populated with a stream error if any. error will be populated if
 *   this method returns `-1`.
 *
 * @return The number of bytes written to outputData, or -1 on a stream error.
 */
- (NSInteger)read:(NSMutableData **)outputData maxLength:(NSUInteger)length error:(NSError **)error;

/**
 * Create the streams of the underlying components for reading.
 *
 * This method should be called on the state transition from `BoxAPIMultipartPieceStateNotOpen`
 * to `BoxAPIMultipartPieceStateInitialBoundary`.
 */
- (void)initializeInputStreams;

/**
 * Close the current stream and open the next one for reading.
 *
 * This method should be called when the input stream of one component reaches its end.
 */
- (void)transitionToNextState;

/**
 * Whether the multipart piece still has data left to read. This method returns true as long
 * as state is not `BoxAPIMultipartPieceStateClosed`
 */
- (BOOL)hasBytesAvailable;

/**
 * Closes all underlying component streams and advances state to `BoxAPIMultipartPieceStateClosed`.
 */
- (void)close;

@end

@implementation BoxAPIMultipartPiece

@synthesize headers = _headers;
@synthesize headersInputStream = _headersInputStream;
@synthesize bodyInputStream = _bodyInputStream;
@synthesize bodyContentLength = _bodyContentLength;
@synthesize hasInitialBoundary = _hasInitialBoundary;
@synthesize startBoundaryInputStream = _startBoundaryInputStream;
@synthesize hasFinalBoundary = _hasFinalBoundary;
@synthesize endBoundaryInputStream = _endBoundaryInputStream;
@synthesize state = _state;

- (id)initWithData:(NSData *)data fieldName:(NSString *)fieldName filename:(NSString *)filename
{
    self = [self initWithData:data fieldName:fieldName filename:filename MIMEType:nil];

    return self;
}

- (id)initWithData:(NSData *)data fieldName:(NSString *)fieldName filename:(NSString *)filename MIMEType:(NSString *)MIMEType
{
    self = [self initWithInputStream:[NSInputStream inputStreamWithData:data] fieldName:fieldName filename:filename MIMEType:MIMEType];

    if (self != nil)
    {
        _bodyContentLength = data.length;
    }

    return self;
}

- (id)initWithInputStream:(NSInputStream *)inputStream fieldName:(NSString *)fieldName filename:(NSString *)filename
{
    self = [self initWithInputStream:inputStream fieldName:fieldName filename:filename MIMEType:nil];

    return self;
}

- (id)initWithInputStream:(NSInputStream *)inputStream fieldName:(NSString *)fieldName filename:(NSString *)filename MIMEType:(NSString *)MIMEType
{
    self = [super init];
    if (self != nil)
    {
        _state = BoxAPIMultipartPieceStateNotOpen;

        _bodyContentLength = 0;
        _hasInitialBoundary = NO;
        _hasFinalBoundary = NO;

        _headers = [NSMutableDictionary dictionary];

        // attach the parameter name as the Content-Disposition header
        BOXAssert(fieldName != nil, @"field name must be specified when sending multipart form data");
        NSString *contentDispositionHeader = [NSString stringWithFormat:@"form-data; name=\"%@\"", fieldName];
        if (filename != nil)
        {
            contentDispositionHeader = [contentDispositionHeader stringByAppendingFormat:@"; filename=\"%@\"", filename];
        }
        [_headers setObject:contentDispositionHeader forKey:BOX_API_MULTIPART_CONTENT_DISPOSITION];

        // add the optionally given MIME Type as the Content-Type header
        if (MIMEType != nil)
        {
            [_headers setObject:MIMEType forKey:BOX_API_MULTIPART_CONTENT_TYPE];
        }

        _bodyInputStream = inputStream;
    }

    return self;
}

- (unsigned long long)contentLength
{
    unsigned long long contentLength = 0;

    contentLength += [self startBoundaryData].length;
    contentLength += [self headersData].length;
    contentLength += self.bodyContentLength;
    contentLength += [self endBoundaryData].length;

    return contentLength;
}

- (NSData *)startBoundaryData
{
    NSData *startBoundaryData = nil;
    if (self.hasInitialBoundary)
    {
        startBoundaryData = [BoxAPIMultipartInitialBoundary() dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        startBoundaryData = [BoxAPIMultipartEncapsulationBoundary() dataUsingEncoding:NSUTF8StringEncoding];
    }

    return startBoundaryData;
}

- (NSData *)endBoundaryData
{
    NSData *endBoundaryData = nil;
    if (self.hasFinalBoundary)
    {
        endBoundaryData = [BoxAPIMultipartFinalBoundary() dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        endBoundaryData = [[NSData alloc] init];
    }

    return endBoundaryData;
}

- (NSData *)headersData
{
    NSMutableData *headersData = [NSMutableData data];

    for (id headerName in self.headers)
    {
        id headerValue = [self.headers valueForKey:headerName];
        NSString *headerString = [NSString stringWithFormat:@"%@: %@%@", headerName, headerValue, BoxAPIMultipartFormCRLF];
        [headersData appendData:[headerString dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [headersData appendData:[BoxAPIMultipartFormCRLF dataUsingEncoding:NSUTF8StringEncoding]];
    return headersData;
}

- (NSInteger)read:(NSMutableData **)outputData maxLength:(NSUInteger)length error:(NSError **)error
{
    NSInteger bytesRead = 0;

    BOXAssert(outputData != nil, @"outputData is a required out param. It must be non nil");
    NSMutableData *data = *outputData;
    BOXAssert(data != nil, @"ouputData is a required out param. It must point to the address of a non-nil NSMutableData");

    data.length = length;
    uint8_t *buffer = [data mutableBytes];

    if (self.state == BoxAPIMultipartPieceStateNotOpen)
    {
        [self initializeInputStreams];
        [self transitionToNextState];
    }
    else if (self.state == BoxAPIMultipartPieceStateInitialBoundary)
    {
        if ([self.startBoundaryInputStream hasBytesAvailable])
        {
            bytesRead += [self.startBoundaryInputStream read:buffer maxLength:length];
        }
        else
        {
            [self transitionToNextState];
        }
    }
    else if (self.state == BoxAPIMultipartPieceStateHeaders)
    {
        if ([self.headersInputStream hasBytesAvailable])
        {
            bytesRead += [self.headersInputStream read:buffer maxLength:length];
        }
        else
        {
            [self transitionToNextState];
        }
    }
    else if (self.state == BoxAPIMultipartPieceStateBodyData)
    {
        if ([self.bodyInputStream hasBytesAvailable])
        {
            bytesRead += [self.bodyInputStream read:buffer maxLength:length];
        }
        else
        {
            [self transitionToNextState];
        }
    }
    else if (self.state == BoxAPIMultipartPieceStateFinalBoundary)
    {
        if ([self.endBoundaryInputStream hasBytesAvailable])
        {
            bytesRead += [self.endBoundaryInputStream read:buffer maxLength:length];
        }
        else
        {
            [self transitionToNextState];
        }
    }

    BOXAssert(bytesRead == -1 || bytesRead <= length, @"should have read no more than %lu bytes", (unsigned long) length);

    if (bytesRead == -1)
    {
        switch (self.state)
        {
            case BoxAPIMultipartPieceStateInitialBoundary:
                BOXLog(@"failed to read from input stream for multipart piece %@ during phase %@", self, @"initial boundary");
                if (error != NULL)
                {
                    *error = [self.startBoundaryInputStream streamError];
                }
                break;
            case BoxAPIMultipartPieceStateHeaders:
                BOXLog(@"failed to read from input stream for multipart piece %@ during phase %@", self, @"headers");
                if (error != NULL)
                {
                    *error = [self.headersInputStream streamError];
                }
                break;
            case BoxAPIMultipartPieceStateBodyData:
                BOXLog(@"failed to read from input stream for multipart piece %@ during phase %@", self, @"body data");
                if (error != NULL)
                {
                    *error = [self.bodyInputStream streamError];
                }
                break;
            case BoxAPIMultipartPieceStateFinalBoundary:
                BOXLog(@"failed to read from input stream for multipart piece %@ during phase %@", self, @"final boundary");
                if (error != NULL)
                {
                    *error = [self.endBoundaryInputStream streamError];
                }
                break;
            case BoxAPIMultipartPieceStateClosed:
                // fall through
            case BoxAPIMultipartPieceStateNotOpen:
                // fall through
            default:
                BOXAssertFail(@"This state should not be reachable. We are not reading from streams during these states");
        }

        [self close];
    }
    else
    {
        // only set length of buffer if read was successful
        data.length = bytesRead;
    }

    return bytesRead;
}

- (void)initializeInputStreams
{
    self.startBoundaryInputStream = [NSInputStream inputStreamWithData:[self startBoundaryData]];
    self.endBoundaryInputStream = [NSInputStream inputStreamWithData:[self endBoundaryData]];
    self.headersInputStream = [NSInputStream inputStreamWithData:[self headersData]];
}

- (void)transitionToNextState
{
    BoxAPIMultipartPieceState nextState = BoxAPIMultipartPieceStateClosed;

    switch (self.state)
    {
        case BoxAPIMultipartPieceStateNotOpen:
            nextState = BoxAPIMultipartPieceStateInitialBoundary;
            [self.startBoundaryInputStream open];
            break;
        case BoxAPIMultipartPieceStateInitialBoundary:
            nextState = BoxAPIMultipartPieceStateHeaders;
            [self.startBoundaryInputStream close];
            [self.headersInputStream open];
            break;
        case BoxAPIMultipartPieceStateHeaders:
            nextState = BoxAPIMultipartPieceStateBodyData;
            [self.headersInputStream close];
            [self.bodyInputStream open];
            break;
        case BoxAPIMultipartPieceStateBodyData:
            nextState = BoxAPIMultipartPieceStateFinalBoundary;
            [self.bodyInputStream close];
            [self.endBoundaryInputStream open];
            break;
        case BoxAPIMultipartPieceStateFinalBoundary:
            nextState = BoxAPIMultipartPieceStateClosed;
            [self.endBoundaryInputStream close];
            break;
        case BoxAPIMultipartPieceStateClosed:
            // fall through
        default:
            nextState = BoxAPIMultipartPieceStateClosed;
    }

    self.state = nextState;
}

- (BOOL)hasBytesAvailable
{
    if (self.state == BoxAPIMultipartPieceStateClosed)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)close
{
    [self.startBoundaryInputStream close];
    [self.headersInputStream close];
    [self.bodyInputStream close];
    [self.endBoundaryInputStream close];

    self.state = BoxAPIMultipartPieceStateClosed;
}

- (NSString *)description
{
    return [[super description] stringByAppendingFormat:@" BoxAPIMultipartPiece with body content-disposition: %@, content-length: %llu",
            [self.headers objectForKey:BOX_API_MULTIPART_CONTENT_DISPOSITION],
            [self contentLength]];
}

@end

#pragma mark - Upload Operation

@interface BoxAPIMultipartToJSONOperation ()
{
    dispatch_once_t _pred;
}

@property (nonatomic, readwrite, strong) NSMutableArray *formPieces;
@property (nonatomic, readwrite, assign) unsigned long long bytesWritten;

@property (nonatomic, readonly) NSOutputStream *outputStream;
@property (nonatomic, readonly) NSMutableData *outputBuffer;
@property (nonatomic, readonly) NSInputStream *inputStream;

@property (nonatomic, readwrite, strong) BoxAPIMultipartPiece *currentPiece;
@property (nonatomic, readwrite, strong) NSEnumerator *pieceEnumerator;

- (NSDictionary *)HTTPHeaders;

- (void)initStreams;
- (void)close;

// called on stream read error
- (void)abortWithError:(NSError *)error;

@end

@implementation BoxAPIMultipartToJSONOperation

@synthesize responseJSON = _responseJSON;
@synthesize formPieces = _formPieces;
@synthesize bytesWritten = _bytesWritten;
@synthesize outputStream = _outputStream;
@synthesize outputBuffer = _outputBuffer;
@synthesize inputStream = _inputStream;

@synthesize currentPiece = _currentPiece;
@synthesize pieceEnumerator = _pieceEnumerator;

@synthesize progressBlock = _progressBlock;

#pragma mark - Upload operation initializers

- (id)initWithURL:(NSURL *)URL HTTPMethod:(NSString *)HTTPMethod body:(NSDictionary *)body queryParams:(NSDictionary *)queryParams OAuth2Session:(BoxOAuth2Session *)OAuth2Session
{
    // do not pass body to super because we do not wish to JSON-encode it. The body will be converted to
    // NSDatas and appended as multipart form pieces
    self = [super initWithURL:URL HTTPMethod:HTTPMethod body:nil queryParams:queryParams OAuth2Session:OAuth2Session];
    if (self != nil)
    {
        _formPieces = [NSMutableArray array];
        _bytesWritten = 0;
        _outputBuffer = [NSMutableData dataWithCapacity:0];
        for (id bodyKey in body)
        {
            NSData *formDataToAppend = nil;
            id bodyValue = [body valueForKey:bodyKey];
            if ([bodyValue isKindOfClass:[NSData class]])
            {
                formDataToAppend = bodyValue;
            }
            else if ([bodyValue isKindOfClass:[NSNull class]])
            {
                formDataToAppend = [NSData data];
            }
            else // most likely this is a string
            {
                formDataToAppend = [[bodyValue description] dataUsingEncoding:NSUTF8StringEncoding];
            }

            BoxAPIMultipartPiece *piece = [[BoxAPIMultipartPiece alloc] initWithData:formDataToAppend fieldName:[bodyKey description] filename:nil];
            [_formPieces addObject:piece];
        }
    }

    return self;
}

#pragma mark - Append data to upload operation

- (void)appendMultipartPieceWithData:(NSData *)data fieldName:(NSString *)fieldName filename:(NSString *)filename MIMEType:(NSString *)MIMEType
{
    BoxAPIMultipartPiece *piece = [[BoxAPIMultipartPiece alloc] initWithData:data fieldName:fieldName filename:filename MIMEType:MIMEType];
    [self.formPieces addObject:piece];
}

- (void)appendMultipartPieceWithInputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)length fieldName:(NSString *)fieldName filename:(NSString *)filename MIMEType:(NSString *)MIMEType
{
    BoxAPIMultipartPiece *piece = [[BoxAPIMultipartPiece alloc] initWithInputStream:inputStream fieldName:fieldName filename:filename MIMEType:MIMEType];
    piece.bodyContentLength = length;
    [self.formPieces addObject:piece];
}

#pragma mark -

- (void)prepareAPIRequest
{
    [super prepareAPIRequest];

    // HTTPHeaders is dependent on the content-length of the underlying pieces.
    // initialize the pieces first so boundaries can be set
    [self initStreams];

    [self.APIRequest setAllHTTPHeaderFields:[self HTTPHeaders]];

    // attach body stream to request
    [self.APIRequest setHTTPBodyStream:self.inputStream];
}

// Override this method to turn it into a NO-OP. The multipart operation will attach itself
// to the request with a stream
- (NSData *)encodeBody:(NSDictionary *)bodyDictionary
{
    return nil;
}

- (void)performProgressCallback
{
    if (self.progressBlock)
    {
        self.progressBlock([self contentLength], self.bytesWritten);
    }
}

- (void)cancel
{
    // Close the output stream before cancelling the operation
    [self close];

    [super cancel];
}

#pragma mark - Multipart Stream methods

- (unsigned long long)contentLength
{
    unsigned long long contentLength = 0;
    for (BoxAPIMultipartPiece *piece in self.formPieces)
    {
        contentLength += piece.contentLength;
    }

    return contentLength;
}

- (NSDictionary *)HTTPHeaders
{
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:BoxAPIMultipartContentTypeHeader() forKey:BOX_API_MULTIPART_CONTENT_TYPE];
    [headers setObject:[NSString stringWithFormat:@"%llu", [self contentLength]] forKey:BOX_API_MULTIPART_CONTENT_LENGTH];

    return [NSDictionary dictionaryWithDictionary:headers];
}

- (void)initStreams
{
    dispatch_once(&_pred, ^{
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreateBoundPair(NULL, &readStream, &writeStream, BOX_API_OUTPUT_STREAM_BUFFER_SIZE);
        _inputStream = CFBridgingRelease(readStream);
        _outputStream = CFBridgingRelease(writeStream);

        _outputStream.delegate = self;
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        [_outputStream open];

        BoxAPIMultipartPiece *initialPiece = [self.formPieces objectAtIndex:0];
        initialPiece.hasInitialBoundary = YES;

        BoxAPIMultipartPiece *finalPiece = [self.formPieces lastObject];
        finalPiece.hasFinalBoundary = YES;
    });
}

- (void)close
{
    self.outputStream.delegate = nil;
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [self.outputStream close];
    _outputStream = nil;
}

- (void)abortWithError:(NSError *)error
{
    [self close];
    [self.connection cancel];
    [self connection:self.connection didFailWithError:error];
}

#pragma mark - NSStream Delegate

/**
 *This retry works around a nasty problem in which mutli-part uploads
 * will fail due to the stream delegate being sent a `NSStreamEventHasSpaceAvailable`
 * event before the input stream has finished opening. This workaround simply replays
 * the event after allowing the run-loop to cycle, providing enough time for the input
 * stream to finish opening. It appears that this bug is in the CFNetwork layer.
 * (See https://github.com/AFNetworking/AFNetworking/issues/948)
 *
 * @param stream The stream to resend a `NSStreamEventHasSpaceAvailable` event to
 */
- (void)retryWrite:(NSStream *)stream
{
    [self stream:stream handleEvent:NSStreamEventHasSpaceAvailable];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    if (streamEvent & NSStreamEventHasSpaceAvailable)
    {
        if (self.inputStream.streamStatus < NSStreamStatusOpen)
        {
            // See comments in `retryWrite:` for details
            [self performSelector:@selector(retryWrite:) withObject:theStream afterDelay:0.1];
        }
        else
        {
            [self writeDataToOutputStream];
        }
    }
}

- (void)writeDataToOutputStream
{
    while ([self.outputStream hasSpaceAvailable])
    {
        if (self.outputBuffer.length > 0)
        {
            NSInteger bytesWrittenToOutputStream = [self.outputStream write:[self.outputBuffer mutableBytes] maxLength:self.outputBuffer.length];

            if (bytesWrittenToOutputStream == -1)
            {
                // Failed to write from to output stream. The upload cannot be completed
                BOXLog(@"BoxAPIMultipartToJSONOperation failed to write to the output stream. Aborting upload.");
                NSError *streamWriteError = [self.outputStream streamError];
                NSDictionary *userInfo = @{
                    NSUnderlyingErrorKey : streamWriteError,
                };
                NSError *uploadError = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:BoxSDKStreamErrorWriteFailed userInfo:userInfo];
                [self abortWithError:uploadError];

                return; // Bail out due to error
            }
            else
            {
                self.bytesWritten += bytesWrittenToOutputStream;
                [self performProgressCallback];

                // truncate buffer by removing the consumed bytes from the front
                [self.outputBuffer replaceBytesInRange:NSMakeRange(0, bytesWrittenToOutputStream) withBytes:NULL length:0];
            }
        }
        else
        {
            // prime reading from the stream
            if (self.currentPiece == nil)
            {
                if (self.pieceEnumerator == nil)
                {
                    self.pieceEnumerator = [self.formPieces objectEnumerator];
                }
                self.currentPiece = [self.pieceEnumerator nextObject];
            }

            // if there is no currentPiece by now, we have enumerated through all pieces,
            // so close the stream. No more stream events will be received.
            if (self.currentPiece == nil)
            {
                [self close];
                return; // Upload finished, break out of loop
            }

            if ([self.currentPiece hasBytesAvailable])
            {
                self.outputBuffer.length = BOX_API_OUTPUT_STREAM_BUFFER_SIZE;
                NSMutableData *buffer = self.outputBuffer;
                NSError *streamReadError = nil;
                NSInteger bytesReadFromPiece = [self.currentPiece read:&buffer maxLength:BOX_API_OUTPUT_STREAM_BUFFER_SIZE error:&streamReadError];

                if (bytesReadFromPiece == -1)
                {
                    // Failed to read from an input stream. The upload cannot be completed
                    BOXLog(@"BoxAPIMultipartToJSONOperation failed to read from a multipart piece. Aborting upload.");
                    NSDictionary *userInfo = @{
                        NSUnderlyingErrorKey : streamReadError,
                    };
                    NSError *uploadError = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:BoxSDKStreamErrorReadFailed userInfo:userInfo];
                    [self abortWithError:uploadError];

                    return; // Bail out due to error
                }
                else
                {
                    self.outputBuffer.length = bytesReadFromPiece;
                }
            }
            else
            {
                self.currentPiece = [self.pieceEnumerator nextObject];
            }
        }
    }
}

@end
