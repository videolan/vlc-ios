//
//  VLCHTTPUploaderViewController.m
//  VLC for iOS
//
//  Created by Jean-Baptiste Kempf on 19/05/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCHTTPUploaderController.h"
#import "VLCAppDelegate.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDNumber.h"

#import "HTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPLogging.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPFileResponse.h"

#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

#if TARGET_IPHONE_SIMULATOR
NSString *const WifiInterfaceName = @"en1";
#else
NSString *const WifiInterfaceName = @"en0";
#endif

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;

@interface VLCHTTPUploaderController ()

@end

@implementation VLCHTTPUploaderController

- (id)init
{
    if ( self = [super init] ) {
        // Just log to the Xcode console.
        [DDLog addLogger:[DDTTYLogger sharedInstance]];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationDidBecomeActive:)
            name:UIApplicationDidBecomeActiveNotification object:nil];
        [center addObserver:self selector:@selector(applicationDidEnterBackground:)
            name:UIApplicationDidEnterBackgroundNotification object:nil];

        return self;
    }
    else
        return nil;
}

- (void)applicationDidBecomeActive: (NSNotification *)notification
{
    BOOL isHTTPServerOn = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingSaveHTTPUploadServerStatus];
    [self changeHTTPServerState:isHTTPServerOn];
}

- (void)applicationDidEnterBackground: (NSNotification *)notification
{
    [self changeHTTPServerState:NO];
}

-(BOOL)changeHTTPServerState:(BOOL)state
{
    if(state) {
        // Initalize our http server
        _httpServer = [[HTTPServer alloc] init];

        [_httpServer setInterface:WifiInterfaceName];

        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
        [self.httpServer setType:@"_http._tcp."];

        // Serve files from the standard Sites folder
        NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"] stringByDeletingLastPathComponent];

        DDLogInfo(@"Setting document root: %@", docRoot);

        [self.httpServer setDocumentRoot:docRoot];

        [self.httpServer setPort:80];

        [self.httpServer setConnectionClass:[VLCHTTPConnection class]];

        NSError *error = nil;
        if(![self.httpServer start:&error])
        {
            if (error.code == 13) {
                DDLogError(@"Port forbidden by OS, trying another one");
                [self.httpServer setPort:8888];
                if(![self.httpServer start:&error])
                    return true;
            }

            /* Address already in Use, take a random one */
            if(error.code == 48) {
                DDLogError(@"Port already in use, trying another one");
                [self.httpServer setPort:0];
                if(![self.httpServer start:&error])
                    return true;
            }

            if (error.code != 0)
                DDLogError(@"Error starting HTTP Server: %@", error.localizedDescription);
            return false;
        }
        return true;
    } else {
        [self.httpServer stop];
        return true;
    }
}

- (NSString *)currentIPAddress
{
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([@(temp_addr->ifa_name) isEqualToString:WifiInterfaceName])
                    address = @(inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr));
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end


/**
 * All we have to do is override appropriate methods in HTTPConnection.
 **/

@implementation VLCHTTPConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    HTTPLogTrace();

    // Add support for POST
    if ([method isEqualToString:@"POST"])
    {
        if ([path isEqualToString:@"/upload.json"])
        {
            return YES;
        }
    }

    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    HTTPLogTrace();

    // Inform HTTP server that we expect a body to accompany a POST request

    if([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }

        // enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];

            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    HTTPLogTrace();
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"])
    {
        return [[HTTPDataResponse alloc] initWithData:[@"\"OK\"" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if( [method isEqualToString:@"GET"] && [path hasPrefix:@"/upload/"] ) {
        // let download the uploaded files
        return [[HTTPFileResponse alloc] initWithFilePath: [[config documentRoot] stringByAppendingString:path] forConnection:self];
    }

    return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    HTTPLogTrace();

    // set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    parser.delegate = self;

    uploadedFiles = [[NSMutableArray alloc] init];
}

- (void)processBodyData:(NSData *)postDataChunk
{
    HTTPLogTrace();
    // append data to the parser. It will invoke callbacks to let us handle
    // parsed data.
    [parser appendData:postDataChunk];
}


//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
    // in this sample, we are not interested in parts, other then file parts.
    // check content disposition to find out filename

    MultipartMessageHeaderField* disposition = (header.fields)[@"Content-Disposition"];
    NSString* filename = [(disposition.params)[@"filename"] lastPathComponent];

    if ( (nil == filename) || [filename isEqualToString: @""] ) {
        // it's either not a file part, or
        // an empty form sent. we won't handle it.
        return;
    }

    // create the path where to store the media
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* uploadDirPath = searchPaths[0];

    BOOL isDir = YES;
    if (![[NSFileManager defaultManager]fileExistsAtPath:uploadDirPath isDirectory:&isDir ]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString* filePath = [uploadDirPath stringByAppendingPathComponent: filename];
    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        storeFile = nil;
    }
    else {
        HTTPLogVerbose(@"Saving file to %@", filePath);
        if(![[NSFileManager defaultManager] createDirectoryAtPath:uploadDirPath withIntermediateDirectories:true attributes:nil error:nil]) {
            HTTPLogError(@"Could not create directory at path: %@", filePath);
        }
        if(![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
            HTTPLogError(@"Could not create file at path: %@", filePath);
        }
        storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [uploadedFiles addObject: [NSString stringWithFormat:@"/upload/%@", filename]];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
    }
}

- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header
{
    // here we just write the output from parser to the file.
    if( storeFile ) {
        [storeFile writeData:data];
    }
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
    // as the file part is over, we close the file.
    [storeFile closeFile];
    storeFile = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate activateIdleTimer];

    /* update media library when file upload was completed */
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate updateMediaList];
}

@end
