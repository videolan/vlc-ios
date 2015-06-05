/*****************************************************************************
 * VLCHTTPConnection.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Carola Nitz <caro # videolan.org>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCHTTPConnection.h"
#import "MultipartFormDataParser.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"
#import "VLCThumbnailsCache.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"

@interface VLCHTTPConnection()
{
    MultipartFormDataParser *_parser;
    NSFileHandle *_storeFile;
    NSString *_filepath;
    UInt64 _contentLength;
    UInt64 _receivedContent;
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

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"])
        return [[HTTPDataResponse alloc] initWithData:[@"\"OK\"" dataUsingEncoding:NSUTF8StringEncoding]];

    if ([path hasPrefix:@"/download/"]) {
        NSString *filePath = [[path stringByReplacingOccurrencesOfString:@"/download/" withString:@""]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        HTTPFileResponse *fileResponse = [[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self];
        fileResponse.contentType = @"application/octet-stream";
        return fileResponse;
    }
    if ([path hasPrefix:@"/thumbnail"]) {
        NSString *filePath = [[path stringByReplacingOccurrencesOfString:@"/thumbnail/" withString:@""]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        filePath = [filePath stringByReplacingOccurrencesOfString:@".png" withString:@""];

        NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
        if (moc) {
            NSPersistentStoreCoordinator *psc = [moc persistentStoreCoordinator];
            if (psc) {
                NSManagedObject *mo = [moc existingObjectWithID:[psc managedObjectIDForURIRepresentation:[NSURL URLWithString:filePath]] error:nil];
                NSData *theData;
                NSString *contentType;

                /* devices category 3 and faster include HW accelerated JPEG encoding
                 * so we can make our transfers faster by using waaay smaller images */
                if ([[UIDevice currentDevice] speedCategory] < 3) {
                    theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForManagedObject:mo]);
                    contentType = @"image/png";
                } else {
                    theData = UIImageJPEGRepresentation([VLCThumbnailsCache thumbnailForManagedObject:mo], .9);
                    contentType = @"image/jpg";
                }

                if (theData) {
                    HTTPDataResponse *dataResponse = [[HTTPDataResponse alloc] initWithData:theData];
                    dataResponse.contentType = contentType;
                    return dataResponse;
                }
            }
        }
    }
    NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    BOOL shouldReturnLibVLCXML = [relativePath isEqualToString:@"/libMediaVLC.xml"];

    if ([relativePath isEqualToString:@"/index.html"] || shouldReturnLibVLCXML) {
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
        NSString *hostName = [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate uploadController] hostname];
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
                                        [file.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                        file.title,
                                        duration, (float)(file.fileSizeInBytes / 1e6)]];
                if (shouldReturnLibVLCXML) {
                    NSString *pathSub = [self _checkIfSubtitleWasFound:file.path];
                    if (pathSub)
                        pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                    [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", file.title, hostName, file.objectID.URIRepresentation, duration, file.fileSizeInBytes, hostName, [file.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pathSub]];
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
                                            [anyFileFromEpisode.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                            showEp.seasonNumber,
                                            showEp.episodeNumber,
                                            showEp.name,
                                            duration, (float)([anyFileFromEpisode fileSizeInBytes] / 1e6)]];
                    if (shouldReturnLibVLCXML) {
                        NSString *pathSub = [self _checkIfSubtitleWasFound:[anyFileFromEpisode path]];
                        if (![pathSub isEqualToString:@""])
                            pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                        [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@ - S%@E%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", show.name, showEp.seasonNumber, showEp.episodeNumber, hostName, showEp.objectID.URIRepresentation, duration, [anyFileFromEpisode fileSizeInBytes], hostName, [anyFileFromEpisode.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pathSub]];
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
                                            [file.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                            file.title,
                                            duration, (float)(file.fileSizeInBytes / 1e6)]];
                    if (shouldReturnLibVLCXML) {
                        NSString *pathSub = [self _checkIfSubtitleWasFound:file.path];
                        if (pathSub)
                            pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                        [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", file.title, hostName, file.objectID.URIRepresentation, duration, file.fileSizeInBytes, hostName, [file.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pathSub]];
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
                    MLFile *anyFileFromTrack = (MLFile *)[[track files] anyObject];
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
                                            [anyFileFromTrack.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                            track.title,
                                            duration, (float)([anyFileFromTrack fileSizeInBytes] / 1e6)]];
                    if (shouldReturnLibVLCXML)
                        [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/thumbnail/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"\"/>", track.title, hostName, track.objectID.URIRepresentation, duration, [anyFileFromTrack fileSizeInBytes], hostName, [anyFileFromTrack.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
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
    } else if ([relativePath isEqualToString:@"/style.css"]) {
        NSDictionary *replacementDict = @{@"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE", nil)};
        HTTPDynamicFileResponse *fileResponse = [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                                                    forConnection:self
                                                                                        separator:@"%%"
                                                                            replacementDictionary:replacementDict];
        fileResponse.contentType = @"text/css";
        return fileResponse;
    }

    return [super httpResponseForMethod:method URI:path];
}

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

    APLog(@"received %lli kB (%lli %%)", _receivedContent / 1024, ((_receivedContent * 100) / _contentLength));
}

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

    NSNumber *freeSpace = [[UIDevice currentDevice] freeDiskspace];
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
    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate networkActivityStarted];
    [appDelegate disableIdleTimer];
}

- (void)notifyUserAboutEndOfFreeStorage:(NSString *)filename
{
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                      message:[NSString stringWithFormat:
                                                               NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                               filename,
                                                               [[UIDevice currentDevice] model]]
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                            otherButtonTitles:nil];
    [alert show];
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
        if (_filepath.length > 0)
            [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate uploadController] moveFileFrom:_filepath];
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
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSMutableArray *listOfSubtitles = [self _listOfSubtitles];
    NSString *fileSub;
    NSUInteger count = listOfSubtitles.count;
    NSString *currentPath;
    for (NSUInteger i = 0; i < count; i++) {
        currentPath = listOfSubtitles[i];
        fileSub = [NSString stringWithFormat:@"%@", currentPath];
        if ([fileSub rangeOfString:fileName].location != NSNotFound)
            subtitlePath = currentPath;
    }
    return subtitlePath;
}

@end
