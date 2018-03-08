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
#import "UIDevice+VLC.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMetaData.h"

#if TARGET_OS_IOS
#import "VLCThumbnailsCache.h"
#endif
#if TARGET_OS_TV
#import "VLCPlayerControlWebSocket.h"
#endif

@interface VLCHTTPConnection()
{
    MultipartFormDataParser *_parser;
    NSFileHandle *_storeFile;
    NSString *_filepath;
    UInt64 _contentLength;
    UInt64 _receivedContent;
#if TARGET_OS_TV
    NSMutableArray *_receivedFiles;
#endif
}
@end

@implementation VLCHTTPConnection

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

- (NSObject<HTTPResponse> *)_httpPOSTresponseUploadJSON
{
    return [[HTTPDataResponse alloc] initWithData:[@"\"OK\"" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)fileIsInDocumentFolder:(NSString*)filepath
{
    if (!filepath) return NO;

    NSError *error;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [searchPaths firstObject];

    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];

    if (error != nil) {
        APLog(@"checking filerelationship failed %@", error);
        return NO;
    }

    return [array containsObject:filepath.lastPathComponent];
}

#if TARGET_OS_IOS
- (NSObject<HTTPResponse> *)_httpGETDownloadForPath:(NSString *)path
{
    NSString *filePath = [[path stringByReplacingOccurrencesOfString:@"/download/" withString:@""] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet];
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
    NSString *filePath = [[path stringByReplacingOccurrencesOfString:@"/thumbnail/" withString:@""] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet];
    filePath = [filePath stringByReplacingOccurrencesOfString:@".png" withString:@""];

    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (moc) {
        NSPersistentStoreCoordinator *psc = [moc persistentStoreCoordinator];
        if (psc) {
            NSManagedObject *mo = nil;
            @try {
                mo = [moc existingObjectWithID:[psc managedObjectIDForURIRepresentation:[NSURL URLWithString:filePath]] error:nil];
            }@catch (NSException *exeption) {
                return [[HTTPErrorResponse alloc] initWithErrorCode:404];
            }

            NSData *theData = UIImageJPEGRepresentation([VLCThumbnailsCache thumbnailForManagedObject:mo], .9);
            NSString *contentType = @"image/jpg";

            if (theData) {
                HTTPDataResponse *dataResponse = [[HTTPDataResponse alloc] initWithData:theData];
                dataResponse.contentType = contentType;
                return dataResponse;
            }
        }
    }
    return [[HTTPErrorResponse alloc] initWithErrorCode:404];
}

- (NSObject<HTTPResponse> *)_httpGETLibraryForPath:(NSString *)path
{
    NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    BOOL shouldReturnLibVLCXML = [relativePath isEqualToString:@"/libMediaVLC.xml"];

    NSMutableArray *allMedia = [[NSMutableArray alloc] init];

    /* add all albums */
    NSArray *allAlbums = [MLAlbum allAlbums];
    for (MLAlbum *album in allAlbums) {
        if (album.name.length > 0 && album.tracks.count > 1)
            [allMedia addObject:album];
    }

    /* add all shows */
    NSArray *allShows = [MLShow allShows];
    for (MLShow *show in allShows) {
        if (show.name.length > 0 && show.episodes.count > 1)
            [allMedia addObject:show];
    }

    /* add all folders*/
    NSArray *allFolders = [MLLabel allLabels];
    for (MLLabel *folder in allFolders)
        [allMedia addObject:folder];

    /* add all remaining files */
    NSArray *allFiles = [MLFile allFiles];
    for (MLFile *file in allFiles) {
        if (file.labels.count > 0) continue;

        if (!file.isShowEpisode && !file.isAlbumTrack)
            [allMedia addObject:file];
        else if (file.isShowEpisode) {
            if (file.showEpisode.show.episodes.count < 2)
                [allMedia addObject:file];
        } else if (file.isAlbumTrack) {
            if (file.albumTrack.album.tracks.count < 2)
                [allMedia addObject:file];
        }
    }

    NSUInteger mediaCount = allMedia.count;
    NSMutableArray *mediaInHtml = [[NSMutableArray alloc] initWithCapacity:mediaCount];
    NSMutableArray *mediaInXml = [[NSMutableArray alloc] initWithCapacity:mediaCount];
    NSString *hostName = [[VLCHTTPUploaderController sharedInstance] hostname];
    NSString *duration;

    for (NSManagedObject *mo in allMedia) {
        if ([mo isKindOfClass:[MLFile class]]) {
            MLFile *file = (MLFile *)mo;
            duration = [[VLCTime timeWithNumber:file.duration] stringValue];
            [mediaInHtml addObject:[NSString stringWithFormat:
                                    @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                    <a href=\"download/%@\" class=\"inner\"> \
                                    <div class=\"down icon\"></div> \
                                    <div class=\"infos\"> \
                                    <span class=\"first-line\">%@</span> \
                                    <span class=\"second-line\">%@ - %0.2f MB</span> \
                                    </div> \
                                    </a> \
                                    </div>",
                                    file.objectID.URIRepresentation,
                                    [file.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
                                    file.title,
                                    duration, (float)(file.fileSizeInBytes / 1e6)]];
            if (shouldReturnLibVLCXML) {
                NSString *pathSub = [self _checkIfSubtitleWasFound:file.path];
                if (pathSub)
                    pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", file.title, hostName, file.objectID.URIRepresentation.absoluteString, duration, file.fileSizeInBytes, hostName, [file.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet], pathSub]];
            }
        }
        else if ([mo isKindOfClass:[MLShow class]]) {
            MLShow *show = (MLShow *)mo;
            NSArray *episodes = [show sortedEpisodes];
            [mediaInHtml addObject:[NSString stringWithFormat:
                                    @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                    <a href=\"#\" class=\"inner folder\"> \
                                    <div class=\"open icon\"></div> \
                                    <div class=\"infos\"> \
                                    <span class=\"first-line\">%@</span> \
                                    <span class=\"second-line\">%lu items</span> \
                                    </div> \
                                    </a> \
                                    <div class=\"content\">",
                                    mo.objectID.URIRepresentation,
                                    show.name,
                                    (unsigned long)[episodes count]]];
            for (MLShowEpisode *showEp in episodes) {
                MLFile *anyFileFromEpisode = (MLFile *)[[showEp files] anyObject];
                duration = [[VLCTime timeWithNumber:[anyFileFromEpisode duration]] stringValue];
                [mediaInHtml addObject:[NSString stringWithFormat:
                                        @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                        <a href=\"download/%@\" class=\"inner\"> \
                                        <div class=\"down icon\"></div> \
                                        <div class=\"infos\"> \
                                        <span class=\"first-line\">S%@E%@ - %@</span> \
                                        <span class=\"second-line\">%@ - %0.2f MB</span> \
                                        </div> \
                                        </a> \
                                        </div>",
                                        showEp.objectID.URIRepresentation,
                                        [anyFileFromEpisode.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
                                        showEp.seasonNumber,
                                        showEp.episodeNumber,
                                        showEp.name,
                                        duration, (float)([anyFileFromEpisode fileSizeInBytes] / 1e6)]];
                if (shouldReturnLibVLCXML) {
                    NSString *pathSub = [self _checkIfSubtitleWasFound:[anyFileFromEpisode path]];
                    if (![pathSub isEqualToString:@""])
                        pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                    [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@ - S%@E%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", show.name, showEp.seasonNumber, showEp.episodeNumber, hostName, showEp.objectID.URIRepresentation, duration, [anyFileFromEpisode fileSizeInBytes], hostName, [anyFileFromEpisode.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet], pathSub]];
                }
            }
            [mediaInHtml addObject:@"</div></div>"];
        } else if ([mo isKindOfClass:[MLLabel class]]) {
            MLLabel *label = (MLLabel *)mo;
            NSArray *folderItems = [label sortedFolderItems];
            [mediaInHtml addObject:[NSString stringWithFormat:
                                    @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                    <a href=\"#\" class=\"inner folder\"> \
                                    <div class=\"open icon\"></div> \
                                    <div class=\"infos\"> \
                                    <span class=\"first-line\">%@</span> \
                                    <span class=\"second-line\">%lu items</span> \
                                    </div> \
                                    </a> \
                                    <div class=\"content\">",
                                    label.objectID.URIRepresentation,
                                    label.name,
                                    (unsigned long)folderItems.count]];
            for (MLFile *file in folderItems) {
                duration = [[VLCTime timeWithNumber:[file duration]] stringValue];
                [mediaInHtml addObject:[NSString stringWithFormat:
                                        @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                        <a href=\"download/%@\" class=\"inner\"> \
                                        <div class=\"down icon\"></div> \
                                        <div class=\"infos\"> \
                                        <span class=\"first-line\">%@</span> \
                                        <span class=\"second-line\">%@ - %0.2f MB</span> \
                                        </div> \
                                        </a> \
                                        </div>",
                                        file.objectID.URIRepresentation,
                                        [file.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
                                        file.title,
                                        duration, (float)(file.fileSizeInBytes / 1e6)]];
                if (shouldReturnLibVLCXML) {
                    NSString *pathSub = [self _checkIfSubtitleWasFound:file.path];
                    if (pathSub)
                        pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                    [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", file.title, hostName, file.objectID.URIRepresentation, duration, file.fileSizeInBytes, hostName, [file.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet], pathSub]];
                }
            }
            [mediaInHtml addObject:@"</div></div>"];
        } else if ([mo isKindOfClass:[MLAlbum class]]) {
            MLAlbum *album = (MLAlbum *)mo;
            NSArray *albumTracks = [album sortedTracks];
            [mediaInHtml addObject:[NSString stringWithFormat:
                                    @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                    <a href=\"#\" class=\"inner folder\"> \
                                    <div class=\"open icon\"></div> \
                                    <div class=\"infos\"> \
                                    <span class=\"first-line\">%@</span> \
                                    <span class=\"second-line\">%lu items</span> \
                                    </div> \
                                    </a> \
                                    <div class=\"content\">",
                                    album.objectID.URIRepresentation,
                                    album.name,
                                    (unsigned long)albumTracks.count]];
            for (MLAlbumTrack *track in albumTracks) {
                MLFile *anyFileFromTrack = [track anyFileFromTrack];
                duration = [[VLCTime timeWithNumber:[anyFileFromTrack duration]] stringValue];
                [mediaInHtml addObject:[NSString stringWithFormat:
                                        @"<div style=\"background-image:url('thumbnail/%@.png')\"> \
                                        <a href=\"download/%@\" class=\"inner\"> \
                                        <div class=\"down icon\"></div> \
                                        <div class=\"infos\"> \
                                        <span class=\"first-line\">%@</span> \
                                        <span class=\"second-line\">%@ - %0.2f MB</span> \
                                        </div> \
                                        </a> \
                                        </div>",
                                        track.objectID.URIRepresentation,
                                        [anyFileFromTrack.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet],
                                        track.title,
                                        duration, (float)([anyFileFromTrack fileSizeInBytes] / 1e6)]];
                if (shouldReturnLibVLCXML)
                    [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"\"/>", track.title, hostName, track.objectID.URIRepresentation, duration, [anyFileFromTrack fileSizeInBytes], hostName, [anyFileFromTrack.url.path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet]]];
            }
            [mediaInHtml addObject:@"</div></div>"];
        }
    }


    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *deviceModel = [currentDevice model];
    NSDictionary *replacementDict;
    HTTPDynamicFileResponse *fileResponse;

    if (shouldReturnLibVLCXML) {
        replacementDict = @{@"FILES" : [mediaInXml componentsJoinedByString:@" "],
                            @"NB_FILE" : [NSString stringWithFormat:@"%li", (unsigned long)mediaInXml.count],
                            @"LIB_TITLE" : [currentDevice name]};

        fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                           forConnection:self
                                                               separator:@"%%"
                                                   replacementDictionary:replacementDict];
        fileResponse.contentType = @"application/xml";
    } else {
        replacementDict = @{@"FILES" : [mediaInHtml componentsJoinedByString:@" "],
                            @"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE", nil),
                            @"WEBINTF_DROPFILES" : NSLocalizedString(@"WEBINTF_DROPFILES", nil),
                            @"WEBINTF_DROPFILES_LONG" : [NSString stringWithFormat:NSLocalizedString(@"WEBINTF_DROPFILES_LONG", nil), deviceModel],
                            @"WEBINTF_DOWNLOADFILES" : NSLocalizedString(@"WEBINTF_DOWNLOADFILES", nil),
                            @"WEBINTF_DOWNLOADFILES_LONG" : [NSString stringWithFormat: NSLocalizedString(@"WEBINTF_DOWNLOADFILES_LONG", nil), deviceModel]};
        fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                           forConnection:self
                                                               separator:@"%%"
                                                   replacementDictionary:replacementDict];
        fileResponse.contentType = @"text/html";
    }

    return fileResponse;
}
#else
- (NSObject<HTTPResponse> *)_httpGETLibraryForPath:(NSString *)path
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *deviceModel = [currentDevice model];
    NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    NSDictionary *replacementDict = @{@"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE_ATV", nil),
                                      @"WEBINTF_DROPFILES" : NSLocalizedString(@"WEBINTF_DROPFILES", nil),
                                      @"WEBINTF_DROPFILES_LONG" : [NSString stringWithFormat:NSLocalizedString(@"WEBINTF_DROPFILES_LONG_ATV", nil), deviceModel],
                                      @"WEBINTF_OPEN_URL" : NSLocalizedString(@"ENTER_URL", nil)};

    HTTPDynamicFileResponse *fileResponse;
    if ([relativePath isEqualToString:@"/index.html"]) {
        fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                           forConnection:self
                                                               separator:@"%%"
                                                   replacementDictionary:replacementDict];
        fileResponse.contentType = @"text/html";
    }

    return fileResponse;
}
#endif


- (NSObject<HTTPResponse> *)_httpGETCSSForPath:(NSString *)path
{
#if TARGET_OS_IOS
    NSDictionary *replacementDict = @{@"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE", nil)};
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

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
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

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
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
            mediaTitle = [media metadataForKey:VLCMetaInformationTitle];
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

#if TARGET_OS_IOS
    if ([path hasPrefix:@"/download/"]) {
        return [self _httpGETDownloadForPath:path];
    }
    if ([path hasPrefix:@"/thumbnail"]) {
        return [self _httpGETThumbnailForPath:path];
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

    long long percentage = ((_receivedContent * 100) / _contentLength);
    APLog(@"received %lli kB (%lli %%)", _receivedContent / 1024, percentage);
#if TARGET_OS_TV
        if (percentage >= 10) {
            [self performSelectorOnMainThread:@selector(startPlaybackOfPath:) withObject:_filepath waitUntilDone:NO];
        }
#endif
}

#if TARGET_OS_TV
- (void)startPlaybackOfPath:(NSString *)path
{
    APLog(@"Starting playback of %@", path);
    if (_receivedFiles == nil)
        _receivedFiles = [[NSMutableArray alloc] init];

    if ([_receivedFiles containsObject:path])
        return;

    [_receivedFiles addObject:path];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaList *mediaList = vpc.mediaList;

    if (!mediaList) {
        mediaList = [[VLCMediaList alloc] init];
    }

    [mediaList addMedia:[VLCMedia mediaWithURL:[NSURL fileURLWithPath:path]]];

    if (!vpc.mediaList) {
        [vpc playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
    }

    VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];

    if (![movieVC isBeingPresented]) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:movieVC
                                                                                     animated:YES
                                                                                   completion:nil];
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
    NSString* filename = [(disposition.params)[@"filename"] lastPathComponent];

    if ((nil == filename) || [filename isEqualToString: @""]) {
        // it's either not a file part, or
        // an empty form sent. we won't handle it.
        return;
    }

    // create the path where to store the media temporarily
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *uploadDirPath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
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
    if (![fileManager createDirectoryAtPath:uploadDirPath withIntermediateDirectories:true attributes:nil error:nil])
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
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                      message:[NSString stringWithFormat:
                                                               NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                               filename,
                                                               [[UIDevice currentDevice] model]]
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                            otherButtonTitles:nil];
    [alert show];
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
