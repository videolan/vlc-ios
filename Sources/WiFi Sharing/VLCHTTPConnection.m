/*****************************************************************************
 * VLCHTTPConnection.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Carola Nitz <caro # videolan.org>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCActivityManager.h"
#import "VLCHTTPConnection.h"
#import "MultipartFormDataParser.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPErrorResponse.h"
#import "NSString+SupportedMedia.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMetaData.h"
#import "GCDAsyncSocket.h"
#import "VLC-Swift.h"

#if TARGET_OS_TV
#import "VLCPlayerControlWebSocket.h"
#import "VLCMicroMediaLibraryService.h"
#endif

#define TIMEOUT_WRITE_ERROR 30
#define HTTP_RESPONSE       90

@interface VLCHTTPConnection()
{
    MultipartFormDataParser *_parser;
    NSFileHandle *_storeFile;
    NSString *_filepath;
    UInt64 _contentLength;
    UInt64 _receivedContent;
    NSString *_webInterfaceTitle;
#if TARGET_OS_TV
    NSMutableArray *_receivedFiles;
#endif
}
@end

@implementation VLCHTTPConnection

#if TARGET_OS_IOS
static NSMutableDictionary *authentificationAttemptsHosts;
static NSMutableDictionary *authentifiedHosts;
#endif

#if TARGET_OS_IOS
+ (void)initialize
{
    authentificationAttemptsHosts = [[NSMutableDictionary alloc] init];
    authentifiedHosts = [[NSMutableDictionary alloc] init];
    [super initialize];
}

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    if (self) {
        if ([VLCHTTPUploaderController sharedInstance].isUsingEthernet)
            _webInterfaceTitle = NSLocalizedString(@"WEBINTF_ETHERNET", nil);
        else
            _webInterfaceTitle = NSLocalizedString(@"WEBINTF_TITLE", nil);
    }
    return self;
}

- (BOOL)isPasswordProtected:(NSString *)path
{
    if ([authentifiedHosts objectForKey:[asyncSocket connectedHost]]
        || [path hasPrefix:@"/public"]
        || [path isEqualToString:@"/favicon.ico"]) {
        return NO;
    }
    return [VLCKeychainCoordinator passcodeLockEnabled];
}

- (void)handleAuthenticationFailed
{
    // Status Code 401 - Unauthorized
    HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:401
                                                                description:nil
                                                                    version:HTTPVersion1_1];

    NSData *authData = [NSData dataWithContentsOfFile:[self filePathForURI:@"/public/auth.html"]];
    NSString *authContent = [[NSString alloc] initWithData:authData encoding:NSUTF8StringEncoding];
    NSDictionary *replacementDict = @{
        @"WEBINTF_TITLE" : _webInterfaceTitle,
        @"WEBINTF_AUTH_REQUIRED" : NSLocalizedString(@"WEBINTF_AUTH_REQUIRED", nil)
    };

    for(id key in replacementDict) {
        NSString *placeholder = [NSString stringWithFormat:@"%@%@%@", @"%%", key, @"%%"];
        authContent = [authContent stringByReplacingOccurrencesOfString:placeholder withString:[replacementDict objectForKey:key]];
    }

    [response setHeaderField:@"WWW-Authenticate" value:@"VLCAuth"];
    [response setBody: [authContent dataUsingEncoding:NSUTF8StringEncoding]];
    [response setHeaderField:@"Content-Length" value:[NSString stringWithFormat:@"%li", [[response body] length]]];

    NSData *responseData = [self preprocessErrorResponse:response];
    [asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_RESPONSE];
}
#endif

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    // Add support for POST
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"])
        return YES;

    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    // Inform HTTP server that we expect a body to accompany a POST request
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if (NSNotFound == paramsSeparator)
            return NO;

        if (paramsSeparator >= contentType.length - 1)
            return NO;

        NSString* type = [contentType substringToIndex:paramsSeparator];
        if (![type isEqualToString:@"multipart/form-data"]) {
            // we expect multipart/form-data content type
            return NO;
        }

        // enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        NSUInteger count = params.count;
        for (NSUInteger i = 0; i < count; i++) {
            NSString *param = params[i];
            paramsSeparator = [param rangeOfString:@"="].location;
            if ((NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1)
                continue;

            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];

            if ([paramName isEqualToString: @"boundary"])
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
        }
        // check if boundary specified
        if (nil == [request headerField:@"boundary"])
            return NO;

        return YES;
    }
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

#if TARGET_OS_IOS
- (int)authenticate:(NSString *)host
{
    NSDictionary *params = [self parseGetParams];
    int attempts = 1;
    int ret = kVLCWifiAuthentificationBanned;

    if (host == nil) {
        return kVLCWifiAuthentificationFailure;
    }

    @synchronized (authentificationAttemptsHosts) {
        if ([authentificationAttemptsHosts objectForKey:host]) {
            attempts += [[authentificationAttemptsHosts objectForKey:host] intValue];
        }

        if (attempts < kVLCWifiAuthentificationMaxAttempts) {
            if ([[params allKeys] containsObject:@"code"]) {
                XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem
                                                               itemForService:@"org.videolan.vlc-ios.passcode"
                                                               account:@"org.videolan.vlc-ios.passcode"
                                                               error:nil];
                NSString *storedCode = keychainItem.secret.stringValue;
                NSString *code = [params valueForKey:@"code"];

                if ([code isEqualToString:storedCode]) {
                    [authentifiedHosts setObject:@(YES) forKey:host];
                    [authentificationAttemptsHosts setObject:@(1) forKey:host];
                    ret = kVLCWifiAuthentificationSuccess;
                } else {
                    [authentificationAttemptsHosts setObject:@(attempts) forKey:host];
                    ret = kVLCWifiAuthentificationFailure;
                }
            } else {
                [authentificationAttemptsHosts setObject:@(attempts) forKey:host];
                ret = kVLCWifiAuthentificationFailure;
            }
        }
    }
    return ret;
}

- (NSObject<HTTPResponse> *)_httpGETAuthentification
{
    NSString *result;
    NSString *message;
    NSString *remainingAttempts;
    NSString *host = [asyncSocket connectedHost];
    int authResult = [self authenticate:host];
    int attempts = 0;

    @synchronized (authentificationAttemptsHosts) {
        if ([authentificationAttemptsHosts objectForKey:host]) {
            attempts += [[authentificationAttemptsHosts objectForKey:host] intValue];
        }
    }

    switch (authResult) {
        case kVLCWifiAuthentificationSuccess:
            result = @"ok";
            message = @"";
            remainingAttempts = @"";
            break;
        case kVLCWifiAuthentificationFailure:
            result = @"ko";
            message = NSLocalizedString(@"WEBINTF_AUTH_WRONG_PASSCODE", nil);
            remainingAttempts = [NSString stringWithFormat:@"%d", 5 - attempts];
            break;
        case kVLCWifiAuthentificationBanned:
            result = @"ban";
            message = NSLocalizedString(@"WEBINTF_AUTH_BANNED", nil);
            remainingAttempts = @"";
            break;
        default:
            result = @"ko";
            message = @"";
            remainingAttempts = @"";
    }
    NSDictionary *returnData = @{
        @"result": result,
        @"message": message,
        @"remainingAttempts": remainingAttempts
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:returnData options:kNilOptions error:nil];
    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:jsonData];
    response.contentType = @"text/html";
    return response;
}
#endif

- (NSObject<HTTPResponse> *)_httpPOSTresponseUploadJSON
{
    return [[HTTPDataResponse alloc] initWithData:[@"\"OK\"" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)fileIsInDocumentFolder:(NSString*)filepath
{
    if (!filepath) return NO;

    NSError *error;
    NSURLRelationship relationship;

#if TARGET_OS_IOS
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
#else
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
#endif
    NSString *directoryPath = [searchPaths firstObject];

    [[NSFileManager defaultManager] getRelationship:&relationship ofDirectoryAtURL:[NSURL fileURLWithPath:directoryPath] toItemAtURL:[NSURL fileURLWithPath:filepath] error:&error];
    return relationship == NSURLRelationshipContains;
}

- (NSObject<HTTPResponse> *)_httpGETDownloadForPath:(NSString *)path
{
    NSString *filePath = [[path stringByReplacingOccurrencesOfString:@"/download/" withString:@""] stringByRemovingPercentEncoding];
    if (![self fileIsInDocumentFolder:filePath]) {
       //return nil which gets handled as resource not found
        return nil;
    }
    HTTPFileResponse *fileResponse = [[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self];
    fileResponse.contentType = @"application/octet-stream";
    return fileResponse;
}

- (NSObject<HTTPResponse> *)_httpGETThumbnailForPath:(NSString *)path
{
    NSString *filePath = [[path stringByReplacingOccurrencesOfString:@"/Thumbnail/" withString:@""] stringByRemovingPercentEncoding];

    if ([filePath isEqualToString:@"/"]) return [[HTTPErrorResponse alloc] initWithErrorCode:404];

    UIImage *thumbnail = [UIImage imageWithContentsOfFile:filePath];
    if (!thumbnail) return [[HTTPErrorResponse alloc] initWithErrorCode:404];

    NSData *theData = UIImageJPEGRepresentation(thumbnail, .9);

    if (!theData) return [[HTTPErrorResponse alloc] initWithErrorCode:404];

    HTTPDataResponse *dataResponse = [[HTTPDataResponse alloc] initWithData:theData];
    dataResponse.contentType = @"image/jpg";
    return dataResponse;
}

#if TARGET_OS_IOS
- (NSObject<HTTPResponse> *)_httpGETLibraryForPath:(NSString *)path
{
    NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    BOOL shouldReturnLibVLCXML = [relativePath isEqualToString:@"/libMediaVLC.xml"];

    NSArray *allMedia = [self allMedia];
    return shouldReturnLibVLCXML ? [self generateXMLResponseFrom:allMedia path:path] : [self generateHttpResponseFrom:allMedia path:path];
}

- (NSArray *)allMedia
{
    MediaLibraryService* medialibrary = [[VLCHTTPUploaderController sharedInstance] medialibrary];

    // Adding all Albums
    NSMutableArray *allMedia = [[medialibrary albumsWithSortingCriteria:VLCMLSortingCriteriaDefault desc:false] mutableCopy] ?: [NSMutableArray new];
    // Adding all Playlists
    [allMedia addObjectsFromArray:[medialibrary playlistsWithSortingCriteria:VLCMLSortingCriteriaDefault desc:false]];
    // Adding all Videos files
    [allMedia addObjectsFromArray:[medialibrary mediaOfType:VLCMLMediaTypeVideo sortingCriteria:VLCMLSortingCriteriaDefault desc:false]];

    //TODO: add all shows
    // Adding all audio files which are not in an Album
    NSArray* audioFiles = [medialibrary mediaOfType:VLCMLMediaTypeAudio sortingCriteria:VLCMLSortingCriteriaDefault desc:false];
    for (VLCMLMedia *track in audioFiles) {
        if (track.subtype != VLCMLMediaSubtypeAlbumTrack) {
            [allMedia addObject:track];
        }
    }
    return [allMedia copy];
}

#else

- (NSObject<HTTPResponse> *)_httpGETLibraryForPath:(NSString *)path
{
    NSArray *allMedia = [self allMedia];
    return [self generateHttpResponseFrom:allMedia path:path];
}

- (NSArray *)allMedia
{
    return [[VLCMicroMediaLibraryService sharedInstance] rawListOfFiles];
}

#endif


- (NSString *)escapeTags:(NSString *)string
{
    return [[[[[string stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]
                        stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"]
                        stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"]
                        stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"]
                        stringByReplacingOccurrencesOfString:@"'" withString:@"&#039;"];
}

#if TARGET_OS_IOS
- (NSString *)createHTMLMediaObjectFromMedia:(VLCMLMedia *)media
{
    return [NSString stringWithFormat:
            @"<div style=\"background-image:url('Thumbnail/%@')\"> \
            <a href=\"download/%@\" class=\"inner\"> \
            <div class=\"down icon\"></div> \
            <div class=\"infos\"> \
            <span class=\"first-line\">%@</span> \
            <span class=\"second-line\">%@ - %@</span> \
            </div> \
            </a> \
            </div>",
            media.thumbnail.path,
            [[media mainFile].mrl.path
             stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
            [self escapeTags:media.title],
            [media mediaDuration], [media formatSize]];
}
#endif

- (NSString *)createHTMLFolderObjectWithImagePath:(NSString *)imagePath
                                             name:(NSString *)name
                                            count:(NSUInteger)count
{
    return [NSString stringWithFormat:
            @"<div style=\"background-image:url('Thumbnail/%@')\"> \
            <a href=\"#\" class=\"inner folder\"> \
            <div class=\"open icon\"></div> \
            <div class=\"infos\"> \
            <span class=\"first-line\">%@</span> \
            <span class=\"second-line\">%lu items</span> \
            </div> \
            </a> \
            <div class=\"content\">",
            imagePath,
            [self escapeTags:name],
            count];
}

#if TARGET_OS_TV
- (NSString *)createHTMLMediaObjectFromRawFileWithPath:(NSString *)path
{
    NSString *name = path.lastPathComponent;
    NSString *imagePath = [[VLCMicroMediaLibraryService sharedInstance] thumbnailURLForItemWithPath:path].path;

    return [NSString stringWithFormat:
            @"<div style=\"background-image:url('Thumbnail/%@')\"> \
            <a href=\"download/%@\" class=\"inner\"> \
            <div class=\"down icon\"></div> \
            <div class=\"infos\"> \
            <span class=\"first-line\">%@</span> \
            <span class=\"second-line\"></span> \
            </div> \
            </a> \
            </div>",
            [imagePath stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
            [path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
            [self escapeTags:name]];
}
#endif

- (HTTPDynamicFileResponse *)generateHttpResponseFrom:(NSArray *)media path:(NSString *)path
{
    NSString *deviceModel = [[UIDevice currentDevice] model];
    NSMutableArray *mediaInHtml = [[NSMutableArray alloc] initWithCapacity:media.count];

#if TARGET_OS_IOS
    for (NSObject <VLCMLObject> *mediaObject in media) {
        if ([mediaObject isKindOfClass:[VLCMLMedia class]]) {
            [mediaInHtml addObject:[self createHTMLMediaObjectFromMedia:(VLCMLMedia *)mediaObject]];
        } else if ([mediaObject isKindOfClass:[VLCMLPlaylist class]]) {
            VLCMLPlaylist *playlist = (VLCMLPlaylist *)mediaObject;
            NSArray *playlistItems = [playlist media];
            [mediaInHtml addObject: [self createHTMLFolderObjectWithImagePath:playlist.artworkMrl
                                                                name:playlist.name
                                                               count:playlistItems.count]];
            for (VLCMLMedia *media in playlistItems) {
                [mediaInHtml addObject:[self createHTMLMediaObjectFromMedia:media]];
            }
            [mediaInHtml addObject:@"</div></div>"];
        } else if ([mediaObject isKindOfClass:[VLCMLAlbum class]]) {
            VLCMLAlbum *album = (VLCMLAlbum *)mediaObject;
            NSArray *albumTracks = [album tracks];
            [mediaInHtml addObject:[self createHTMLFolderObjectWithImagePath:[album artworkMRL].path
                                                                        name:album.title
                                                                       count:albumTracks.count]];
            for (VLCMLMedia *track in albumTracks) {
                [mediaInHtml addObject:[self createHTMLMediaObjectFromMedia:track]];
            }
            [mediaInHtml addObject:@"</div></div>"];
        }
    } // end of forloop

    NSDictionary *replacementDict = @{@"FILES" : [mediaInHtml componentsJoinedByString:@" "],
                        @"WEBINTF_TITLE" : _webInterfaceTitle,
                        @"WEBINTF_DROPFILES" : NSLocalizedString(@"WEBINTF_DROPFILES", nil),
                        @"WEBINTF_DROPFILES_LONG" : [NSString stringWithFormat:NSLocalizedString(@"WEBINTF_DROPFILES_LONG", nil), deviceModel],
                        @"WEBINTF_DOWNLOADFILES" : NSLocalizedString(@"WEBINTF_DOWNLOADFILES", nil),
                        @"WEBINTF_DOWNLOADFILES_LONG" : [NSString stringWithFormat: NSLocalizedString(@"WEBINTF_DOWNLOADFILES_LONG", nil), deviceModel]};
#else
    for (NSObject *mediaObject in media) {
        if ([mediaObject isKindOfClass:[NSString class]]) {
            [mediaInHtml addObject:[self createHTMLMediaObjectFromRawFileWithPath:(NSString *)mediaObject]];
        } else if ([mediaObject isKindOfClass:[NSArray class]]) {
            NSArray *folderItems = (NSArray *)mediaObject;
            NSString *firstItem = folderItems.firstObject;
            NSString *folderName = firstItem.stringByDeletingLastPathComponent.lastPathComponent;
            NSString *artworkPath = @"";

            [mediaInHtml addObject: [self createHTMLFolderObjectWithImagePath:artworkPath
                                                                name:folderName
                                                               count:folderItems.count]];
            for (NSString *path in folderItems) {
                [mediaInHtml addObject:[self createHTMLMediaObjectFromRawFileWithPath:path]];
            }
            [mediaInHtml addObject:@"</div></div>"];
        }
    }
    NSDictionary *replacementDict = @{@"FILES" : [mediaInHtml componentsJoinedByString:@" "],
                                      @"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE_ATV", nil),
                                      @"WEBINTF_DROPFILES" : NSLocalizedString(@"WEBINTF_DROPFILES", nil),
                                      @"WEBINTF_DROPFILES_LONG" : [NSString stringWithFormat:NSLocalizedString(@"WEBINTF_DROPFILES_LONG_ATV", nil), deviceModel],
                                      @"WEBINTF_DOWNLOADFILES" : NSLocalizedString(@"WEBINTF_DOWNLOADFILES", nil),
                                      @"WEBINTF_DOWNLOADFILES_LONG" : [NSString stringWithFormat: NSLocalizedString(@"WEBINTF_DOWNLOADFILES_LONG", nil), deviceModel],
                                      @"WEBINTF_OPEN_URL" : NSLocalizedString(@"ENTER_URL", nil)};
#endif

    HTTPDynamicFileResponse *fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                       forConnection:self
                                                           separator:@"%%"
                                               replacementDictionary:replacementDict];
    fileResponse.contentType = @"text/html";

    return fileResponse;
}

#if TARGET_OS_IOS
- (HTTPDynamicFileResponse *)generateXMLResponseFrom:(NSArray *)media path:(NSString *)path
{
    NSMutableArray *mediaInXml = [[NSMutableArray alloc] initWithCapacity:media.count];
    /* form a strict character set to produce a valid XML stream */
    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
    [characterSet formUnionWithCharacterSet:NSCharacterSet.URLFragmentAllowedCharacterSet];
    [characterSet removeCharactersInString:@"!#$%&'()*+,/:;=?@[]"];
    NSString *hostName = [NSString stringWithFormat:@"%@:%@", [[VLCHTTPUploaderController sharedInstance] hostname], [[VLCHTTPUploaderController sharedInstance] hostnamePort]];
    for (NSObject <VLCMLObject> *mediaObject in media) {
        if ([mediaObject isKindOfClass:[VLCMLMedia class]]) {
            VLCMLMedia *file = (VLCMLMedia *)mediaObject;
            NSString *pathSub = [self _checkIfSubtitleWasFound:[file mainFile].mrl.path];
            if (pathSub)
                pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
            [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/Thumbnail/%@\" duration=\"%@\" size=\"%@\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>",
                                   [file.title stringByAddingPercentEncodingWithAllowedCharacters:characterSet],
                                   hostName,
                                   file.thumbnail.path,
                                   [file mediaDuration], [file formatSize],
                                   hostName,
                                   [[file mainFile].mrl.path stringByAddingPercentEncodingWithAllowedCharacters:characterSet], pathSub]];
        } else if ([mediaObject isKindOfClass:[VLCMLPlaylist class]]) {
            VLCMLPlaylist *playlist = (VLCMLPlaylist *)mediaObject;
            NSArray *playlistItems = [playlist media];
            for (VLCMLMedia *file in playlistItems) {
                NSString *pathSub = [self _checkIfSubtitleWasFound:[file mainFile].mrl.path];
                if (pathSub)
                    pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/Thumbnail/%@\" duration=\"%@\" size=\"%@\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>",
                                       [file.title stringByAddingPercentEncodingWithAllowedCharacters:characterSet],
                                       hostName,
                                       file.thumbnail.path,
                                       [file mediaDuration],
                                       [file formatSize],
                                       hostName,
                                       [[file mainFile].mrl.path stringByAddingPercentEncodingWithAllowedCharacters:characterSet], pathSub]];
            }
        } else if ([mediaObject isKindOfClass:[VLCMLAlbum class]]) {
            VLCMLAlbum *album = (VLCMLAlbum *)mediaObject;
            NSArray *albumTracks = [album tracks];
            for (VLCMLMedia *track in albumTracks) {

                [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/Thumbnail/%@\" duration=\"%@\" size=\"%@\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"\"/>",
                                       [track.title stringByAddingPercentEncodingWithAllowedCharacters:characterSet],
                                       hostName,
                                       track.thumbnail.path,
                                       [track mediaDuration],
                                       [track formatSize],
                                       hostName,
                                       [[track mainFile].mrl.path stringByAddingPercentEncodingWithAllowedCharacters:characterSet]]];
            }
        }
    } // end of forloop

    NSDictionary *replacementDict = @{@"FILES" : [mediaInXml componentsJoinedByString:@"\n"],
                        @"NB_FILE" : [NSString stringWithFormat:@"%li", (unsigned long)mediaInXml.count],
                        @"LIB_TITLE" : [[UIDevice currentDevice] name]};

    HTTPDynamicFileResponse *fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                       forConnection:self
                                                           separator:@"%%"
                                               replacementDictionary:replacementDict];
    fileResponse.contentType = @"application/xml";
    return fileResponse;
}
#endif

- (NSObject<HTTPResponse> *)_httpGETCSSForPath:(NSString *)path
{
#if TARGET_OS_IOS
    NSDictionary *replacementDict = @{@"WEBINTF_TITLE" : _webInterfaceTitle};
#else
    NSDictionary *replacementDict = @{@"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE_ATV", nil)};
#endif
    HTTPDynamicFileResponse *fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                                                forConnection:self
                                                                                    separator:@"%%"
                                                                        replacementDictionary:replacementDict];
    fileResponse.contentType = @"text/css";
    return fileResponse;
}

#if TARGET_OS_TV
- (NSObject <HTTPResponse> *)_HTTPGETPlaying
{
    /* JSON response:
     {
        "currentTime": 42,
        "media": {
            "id": "some id",
            "title": "some title",
            "duration": 120000
        }
     }
     */

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    if (!vpc.isPlaying) {
        return [[HTTPErrorResponse alloc] initWithErrorCode:404];
    }
    VLCMedia *media = [vpc currentlyPlayingMedia];
    if (!media) {
        return [[HTTPErrorResponse alloc] initWithErrorCode:404];
    }

    NSString *mediaTitle = vpc.metadata.title;
    if (!mediaTitle)
        mediaTitle = @"";
    NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString,
                                 @"title" : mediaTitle,
                                 @"duration" : @([vpc mediaDuration])};
    NSDictionary *returnDict = @{ @"currentTime" : @([vpc playedTime].intValue),
                                  @"media" : mediaDict };

    NSError *error;
    NSData *returnData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
    if (error != nil) {
        APLog(@"JSON serialization failed %@", error);
        return [[HTTPErrorResponse alloc] initWithErrorCode:500];
    }

    return [[HTTPDataResponse alloc] initWithData:returnData];
}

- (NSObject <HTTPResponse> *)_HTTPGETwebResources
{
    /* JS response
     {
        "WEBINTF_URL_SENT" : "URL sent successfully.",
        "WEBINTF_URL_EMPTY" :"'URL cannot be empty.",
        "WEBINTF_URL_INVALID" : "Not a valid URL."
     }
     */

    NSString *returnString = [NSString stringWithFormat:
                              @"var LOCALES = {\n" \
                                         "PLAYER_CONTROL: {\n" \
                                         "URL: {\n" \
                                         "EMPTY: \"%@\",\n" \
                                         "NOT_VALID: \"%@\",\n" \
                                         "SENT_SUCCESSFULLY: \"%@\"\n" \
                                         "}\n" \
                                         "}\n" \
                              "}",
                              NSLocalizedString(@"WEBINTF_URL_EMPTY", nil),
                              NSLocalizedString(@"WEBINTF_URL_INVALID", nil),
                              NSLocalizedString(@"WEBINTF_URL_SENT", nil)];

    NSData *returnData = [returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    return [[HTTPDataResponse alloc] initWithData:returnData];
}

- (NSObject <HTTPResponse> *)_HTTPGETPlaylist
{
    /* JSON response:
     [
        {
            "media": {
                "id": "some id 1",
                "title": "some title 1",
                "duration": 120000
            }
        },
     ...]
     */

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    if (!vpc.isPlaying || !vpc.mediaList) {
        return [[HTTPErrorResponse alloc] initWithErrorCode:404];
    }

    VLCMediaList *mediaList = vpc.mediaList;
    [mediaList lock];
    NSUInteger mediaCount = mediaList.count;
    NSMutableArray *retArray = [NSMutableArray array];
    for (NSUInteger x = 0; x < mediaCount; x++) {
        VLCMedia *media = [mediaList mediaAtIndex:x];
        NSString *mediaTitle;
        if (media.parsedStatus == VLCMediaParsedStatusDone) {
            mediaTitle = media.metaData.title;
        } else {
            mediaTitle = media.url.lastPathComponent;
        }

        NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString,
                                     @"title" : mediaTitle,
                                     @"duration" : @(media.length.intValue) };
        [retArray addObject:@{ @"media" : mediaDict }];
    }
    [mediaList unlock];

    NSError *error;
    NSData *returnData = [NSJSONSerialization dataWithJSONObject:retArray options:0 error:&error];
    if (error != nil) {
        APLog(@"JSON serialization failed %@", error);
        return [[HTTPErrorResponse alloc] initWithErrorCode:500];
    }

    return [[HTTPDataResponse alloc] initWithData:returnData];
}
#endif

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"])
        return [self _httpPOSTresponseUploadJSON];

    if ([path hasPrefix:@"/download/"]) {
        return [self _httpGETDownloadForPath:path];
    }
    if ([path hasPrefix:@"/Thumbnail/"]) {
        return [self _httpGETThumbnailForPath:path];
    }
#if TARGET_OS_IOS
    if ([path hasPrefix:@"/public/auth.html"]) {
        return [self _httpGETAuthentification];
    }
#else
    if ([path hasPrefix:@"/playing"]) {
        return [self _HTTPGETPlaying];
    }
    if ([path hasPrefix:@"/playlist"]) {
        return [self _HTTPGETPlaylist];
    }
    if ([path hasPrefix:@"/web_resources.js"]) {
        return [self _HTTPGETwebResources];
    }
#endif

    NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];

    if ([relativePath isEqualToString:@"/index.html"] || [relativePath isEqualToString:@"/libMediaVLC.xml"]) {
        return [self _httpGETLibraryForPath:path];
    } else if ([relativePath isEqualToString:@"/style.css"]) {
        return [self _httpGETCSSForPath:path];
    }

    return [super httpResponseForMethod:method URI:path];
}

#if TARGET_OS_TV
- (WebSocket *)webSocketForURI:(NSString *)path
{
    return [[VLCPlayerControlWebSocket alloc] initWithRequest:request socket:asyncSocket];
}
#endif

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    // set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    _parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    _parser.delegate = self;

    APLog(@"expecting file of size %lli kB", contentLength / 1024);
    _contentLength = contentLength;
}

- (void)processBodyData:(NSData *)postDataChunk
{
    /* append data to the parser. It will invoke callbacks to let us handle
     * parsed data. */
    [_parser appendData:postDataChunk];

    _receivedContent += postDataChunk.length;

#if WIFI_SHARING_DEBUG || TARGET_OS_TV
    long long percentage = ((_receivedContent * 100) / _contentLength);
#if WIFI_SHARING_DEBUG
    APLog(@"received %lli kB (%lli %%)", _receivedContent / 1024, percentage);
#endif
#endif
#if TARGET_OS_TV
        if (percentage >= 10) {
            [self performSelectorOnMainThread:@selector(startPlaybackOfPath:) withObject:_filepath waitUntilDone:NO];
        }
#endif
}

#if TARGET_OS_TV
- (void)startPlaybackOfPath:(NSString *)path
{
    if (!path) {
        return;
    }

    if (_receivedFiles == nil)
        _receivedFiles = [[NSMutableArray alloc] init];

    if ([_receivedFiles containsObject:path]) {
        return;
    }

    [_receivedFiles addObject:path];

    APLog(@"Starting playback of %@", path);
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaList *mediaList = vpc.mediaList;

    if (!mediaList) {
        mediaList = [[VLCMediaList alloc] init];
    }

    VLCMedia *mediaToPlay = [VLCMedia mediaWithURL:[NSURL fileURLWithPath:path]];
    [mediaList addMedia:mediaToPlay];
    NSInteger indexToPlay = [mediaList indexOfMedia:mediaToPlay];

    if (!vpc.isPlaying) {
        [vpc playMediaList:mediaList firstIndex:indexToPlay subtitlesFilePath:nil];
    }
}
#endif

//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void)processStartOfPartWithHeader:(MultipartMessageHeader*) header
{
    /* in this sample, we are not interested in parts, other then file parts.
     * check content disposition to find out filename */

    MultipartMessageHeaderField* disposition = (header.fields)[@"Content-Disposition"];
    NSString* filename = (disposition.params)[@"filename"];

    if ((nil == filename) || [filename isEqualToString: @""]) {
        // it's either not a file part, or
        // an empty form sent. we won't handle it.
        return;
    }

    // create the path where to store the media temporarily
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *uploadDirPath = [searchPaths.firstObject
                               stringByAppendingPathComponent:kVLCHTTPUploadDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = YES;
    if (![fileManager fileExistsAtPath:uploadDirPath isDirectory:&isDir])
        [fileManager createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];

    _filepath = [uploadDirPath stringByAppendingPathComponent: filename];

    NSNumber *freeSpace = [[UIDevice currentDevice] VLCFreeDiskSpace];
    if (_contentLength >= freeSpace.longLongValue) {
        /* avoid deadlock since we are on a background thread */
        [self performSelectorOnMainThread:@selector(notifyUserAboutEndOfFreeStorage:) withObject:filename waitUntilDone:NO];
        [self handleResourceNotFound];
        [self stop];
        return;
    }

    APLog(@"Saving file to %@", _filepath);
    if (![fileManager createDirectoryAtPath:[_filepath stringByDeletingLastPathComponent]
                withIntermediateDirectories:true attributes:nil error:nil])
        APLog(@"Could not create directory at path: %@", _filepath);

    if (![fileManager createFileAtPath:_filepath contents:nil attributes:nil])
        APLog(@"Could not create file at path: %@", _filepath);

    _storeFile = [NSFileHandle fileHandleForWritingAtPath:_filepath];

    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStarted];
    [activityManager disableIdleTimer];
}

- (void)notifyUserAboutEndOfFreeStorage:(NSString *)filename
{
#if TARGET_OS_IOS
    [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                         errorMessage:[NSString stringWithFormat:
                                                       NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                       filename,
                                                       [[UIDevice currentDevice] model]]
                                       viewController:[UIApplication sharedApplication].keyWindow.rootViewController];
#else
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                                             message:[NSString stringWithFormat:
                                                                                      NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                                                      filename,
                                                                                      [[UIDevice currentDevice] model]]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
#endif
}

- (void)processContent:(NSData*)data WithHeader:(MultipartMessageHeader*) header
{
    // here we just write the output from parser to the file.
    if (_storeFile) {
        @try {
            [_storeFile writeData:data];
#if TARGET_OS_IOS
            [[VLCHTTPUploaderController sharedInstance] resetIdleTimer];
#endif
        }
        @catch (NSException *exception) {
            APLog(@"File to write further data because storage is full.");
            [_storeFile closeFile];
            _storeFile = nil;
            /* don't block */
            [self performSelector:@selector(stop) withObject:nil afterDelay:0.1];
        }
    }

}

- (void)processEndOfPartWithHeader:(MultipartMessageHeader*)header
{
    // as the file part is over, we close the file.
    APLog(@"closing file");
    [_storeFile closeFile];
    _storeFile = nil;
}

- (BOOL)shouldDie
{
    if (_filepath) {
        if (_filepath.length > 0) {
            [[VLCHTTPUploaderController sharedInstance] moveFileFrom:_filepath];

#if TARGET_OS_TV
            [_receivedFiles removeObject:_filepath];
#endif
        }
    }
    return [super shouldDie];
}

#pragma mark subtitle

- (NSMutableArray *)_listOfSubtitles
{
    NSMutableArray *listOfSubtitles = [[NSMutableArray alloc] init];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *filePath;
    NSUInteger count = allFiles.count;
    for (NSUInteger i = 0; i < count; i++) {
        filePath = [[NSString stringWithFormat:@"%@/%@", documentsDirectory, allFiles[i]] stringByReplacingOccurrencesOfString:@"file://"withString:@""];
        if ([filePath isSupportedSubtitleFormat])
            [listOfSubtitles addObject:filePath];
    }
    return listOfSubtitles;
}

- (NSString *)_checkIfSubtitleWasFound:(NSString *)filePath
{
    NSString *subtitlePath;
    NSString *fileSub;
    NSString *currentPath;

    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    if (fileName == nil)
        return nil;

    NSMutableArray *listOfSubtitles = [self _listOfSubtitles];
    NSUInteger count = listOfSubtitles.count;

    for (NSUInteger i = 0; i < count; i++) {
        currentPath = listOfSubtitles[i];
        fileSub = [NSString stringWithFormat:@"%@", currentPath];
        if ([fileSub rangeOfString:fileName].location != NSNotFound)
            subtitlePath = currentPath;
    }
    return subtitlePath;
}

@end
