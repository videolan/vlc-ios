/*****************************************************************************
 * VLCHTTPConnection.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCHTTPConnection.h"
#import "HTTPConnection.h"
#import "MultipartFormDataParser.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "MultipartMessageHeaderField.h"
#import "VLCHTTPUploaderController.h"
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

@property (nonatomic) VLCHTTPUploaderController *uploadController;

@end

@implementation VLCHTTPConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    // Add support for POST
    if ([method isEqualToString:@"POST"]) {
        if ([path isEqualToString:@"/upload.json"])
            return YES;
    }

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
        for (NSString* param in params) {
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
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"]) {
        return [[HTTPDataResponse alloc] initWithData:[@"\"OK\"" dataUsingEncoding:NSUTF8StringEncoding]];
    }
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
        NSPersistentStoreCoordinator *psc = [moc persistentStoreCoordinator];
        NSManagedObject *mo = [moc existingObjectWithID:[psc managedObjectIDForURIRepresentation:[NSURL URLWithString:filePath]] error:nil];

        NSData *theData;
        if ([mo isKindOfClass:[MLFile class]])
            theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForMediaFile:(MLFile *)mo]);
        else if ([mo isKindOfClass:[MLShow class]])
            theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForShow:(MLShow *)mo]);
        else if ([mo isKindOfClass:[MLLabel class]])
            theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForLabel:(MLLabel *)mo]);
        else if ([mo isKindOfClass:[MLAlbum class]])
            theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForMediaFile:[[(MLAlbum *)mo tracks].anyObject files].anyObject]);
        else if ([mo isKindOfClass:[MLAlbumTrack class]])
            theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForMediaFile:[(MLAlbumTrack *)mo files].anyObject]);
        else if ([mo isKindOfClass:[MLShowEpisode class]])
            theData = UIImagePNGRepresentation([VLCThumbnailsCache thumbnailForMediaFile:[(MLShowEpisode *)mo files].anyObject]);

        if (theData) {
            HTTPDataResponse *dataResponse = [[HTTPDataResponse alloc] initWithData:theData];
            dataResponse.contentType = @"image/png";
            return dataResponse;
        }
    }
    NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];

    if (([relativePath isEqualToString:@"/index.html"]) || ([relativePath isEqualToString:@"/libMediaVLC.xml"])) {
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

        NSMutableArray *mediaInHtml = [[NSMutableArray alloc] initWithCapacity:allMedia.count];
        NSMutableArray *mediaInXml = [[NSMutableArray alloc] initWithCapacity:allMedia.count];
        self.uploadController = [[VLCHTTPUploaderController alloc] init];
        NSString *hostName = [self.uploadController hostname];
        NSString *pathLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *duration;

        for (NSManagedObject *mo in allMedia) {
            if ([mo isKindOfClass:[MLFile class]]) {
                duration = [[VLCTime timeWithNumber:[(MLFile *)mo duration]] stringValue];
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
                                        mo.objectID.URIRepresentation,
                                        [[(MLFile *)mo url] stringByReplacingOccurrencesOfString:@"file://"withString:@""],
                                        [(MLFile *)mo title],
                                        duration, (float)([(MLFile *)mo fileSizeInBytes] / 1e6)]];
                if ([relativePath isEqualToString:@"/libMediaVLC.xml"]) {
                    NSString *pathSub = [self _checkSubtitleFound:[(MLFile *)mo url]];
                    if (![pathSub isEqualToString:@""])
                        pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                    [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/download/%@/Thumbnails/File/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", [(MLFile *)mo title], hostName, pathLibrary, [[NSString stringWithFormat:@"%@", mo.objectID.URIRepresentation] lastPathComponent], duration, [(MLFile *)mo fileSizeInBytes], hostName, [[(MLFile *)mo url] stringByReplacingOccurrencesOfString:@"file://"withString:@""], pathSub]];
                }
            }
            else if ([mo isKindOfClass:[MLShow class]]) {
                NSArray *episodes = [(MLShow *)mo sortedEpisodes];
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
                                        [(MLShow *)mo name],
                                        (unsigned long)[episodes count]]];
                for (MLShowEpisode *showEp in episodes) {
                    duration = [[VLCTime timeWithNumber:[(MLFile *)[[showEp files] anyObject] duration]] stringValue];
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
                                            [[(MLFile *)[[showEp files] anyObject] url] stringByReplacingOccurrencesOfString:@"file://"withString:@""],
                                            showEp.seasonNumber,
                                            showEp.episodeNumber,
                                            showEp.name,
                                            duration, (float)([(MLFile *)[[showEp files] anyObject] fileSizeInBytes] / 1e6)]];
                    if ([relativePath isEqualToString:@"/libMediaVLC.xml"]) {
                        NSString *pathSub = [self _checkSubtitleFound:[(MLFile *)[[showEp files] anyObject] url]];
                        if (![pathSub isEqualToString:@""])
                            pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                        [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@ - S%@E%@\" thumb=\"http://%@/download/%@/Thumbnails/File/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", [(MLShow *)mo name], showEp.seasonNumber, showEp.episodeNumber, hostName, pathLibrary, [[NSString stringWithFormat:@"%@", showEp.objectID.URIRepresentation] lastPathComponent], duration, [(MLFile *)[[showEp files] anyObject] fileSizeInBytes], hostName, [[(MLFile *)[[showEp files] anyObject] url] stringByReplacingOccurrencesOfString:@"file://"withString:@""], pathSub]];
                    }
                }
                [mediaInHtml addObject:@"</div></div>"];
            } else if ([mo isKindOfClass:[MLLabel class]]) {
                NSArray *folderItems = [(MLLabel *)mo sortedFolderItems];
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
                                        [(MLLabel *)mo name],
                                        (unsigned long)[folderItems count]]];
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
                                            [[file url] stringByReplacingOccurrencesOfString:@"file://"withString:@""],
                                            file.title,
                                            duration, (float)([file fileSizeInBytes] / 1e6)]];
                    if ([relativePath isEqualToString:@"/libMediaVLC.xml"]) {
                        NSString *pathSub = [self _checkSubtitleFound:[file url]];
                        if (![pathSub isEqualToString:@""])
                            pathSub = [NSString stringWithFormat:@"http://%@/download/%@", hostName, pathSub];
                        [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/download/%@/Thumbnails/File/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"%@\"/>", file.title, hostName, pathLibrary, [[NSString stringWithFormat:@"%@", file.objectID.URIRepresentation] lastPathComponent], duration, [file fileSizeInBytes], hostName, [[file url] stringByReplacingOccurrencesOfString:@"file://"withString:@""], pathSub]];
                    }
                }
                [mediaInHtml addObject:@"</div></div>"];
            } else if ([mo isKindOfClass:[MLAlbum class]]) {
                NSArray *albumTracks = [(MLAlbum *)mo sortedTracks];
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
                                        [(MLAlbum *)mo name],
                                        (unsigned long)[albumTracks count]]];
                for (MLAlbumTrack *track in albumTracks) {
                    duration = [[VLCTime timeWithNumber:[(MLFile *)[[track files] anyObject] duration]] stringValue];
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
                                            [[(MLFile *)[[track files] anyObject] url] stringByReplacingOccurrencesOfString:@"file://"withString:@""],
                                            track.title,
                                            duration, (float)([(MLFile *)[[track files] anyObject] fileSizeInBytes] / 1e6)]];
                    if ([relativePath isEqualToString:@"/libMediaVLC.xml"])
                        [mediaInXml addObject:[NSString stringWithFormat:@"<Media title=\"%@\" thumb=\"http://%@/download/%@/Thumbnails/File/%@.png\" duration=\"%@\" size=\"%li\" pathfile=\"http://%@/download/%@\" pathSubtitle=\"\"/>", track.title, hostName, pathLibrary, [[NSString stringWithFormat:@"%@", track.objectID.URIRepresentation] lastPathComponent], duration, [(MLFile *)[[track files] anyObject] fileSizeInBytes], hostName, [[(MLFile *)[[track files] anyObject] url] stringByReplacingOccurrencesOfString:@"file://"withString:@""]]];
                }
                [mediaInHtml addObject:@"</div></div>"];
            }
        }

        NSString *deviceModel = [[UIDevice currentDevice] model];
        NSDictionary *replacementDict;

        if ([relativePath isEqualToString:@"/libMediaVLC.xml"]) {
            replacementDict = @{@"FILES" : [mediaInXml componentsJoinedByString:@" "],
                                @"NB_FILE" : [NSString stringWithFormat:@"%li", (unsigned long)mediaInXml.count],
                                @"LIB_TITLE" : [[UIDevice currentDevice] name]};
        } else
            replacementDict = @{@"FILES" : [mediaInHtml componentsJoinedByString:@" "],
                                @"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE", nil),
                                @"WEBINTF_DROPFILES" : NSLocalizedString(@"WEBINTF_DROPFILES", nil),
                                @"WEBINTF_DROPFILES_LONG" : [NSString stringWithFormat:NSLocalizedString(@"WEBINTF_DROPFILES_LONG", nil), deviceModel],
                                @"WEBINTF_DOWNLOADFILES" : NSLocalizedString(@"WEBINTF_DOWNLOADFILES", nil),
                                @"WEBINTF_DOWNLOADFILES_LONG" : [NSString stringWithFormat: NSLocalizedString(@"WEBINTF_DOWNLOADFILES_LONG", nil), deviceModel]};

        return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                   forConnection:self
                                                       separator:@"%%"
                                           replacementDictionary:replacementDict];
    } else if ([relativePath isEqualToString:@"/style.css"]) {
        NSDictionary *replacementDict = @{@"WEBINTF_TITLE" : NSLocalizedString(@"WEBINTF_TITLE", nil)};
        return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                   forConnection:self
                                                       separator:@"%%"
                                           replacementDictionary:replacementDict];
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
    NSString* uploadDirPath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = YES;
    if (![fileManager fileExistsAtPath:uploadDirPath isDirectory:&isDir ])
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
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate networkActivityStarted];
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
}

- (void)notifyUserAboutEndOfFreeStorage:(NSString *)filename
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
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

- (NSMutableArray *)_listOfSubtitle
{
    NSMutableArray *listOfSubtitle = [[NSMutableArray alloc] init];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *allfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *filePath;
    for (int count = 0; count < allfiles.count; count++) {
        filePath = [[NSString stringWithFormat:@"%@/%@", documentsDirectory, allfiles[count]] stringByReplacingOccurrencesOfString:@"file://"withString:@""];
        if ([filePath isSupportedSubtitleFormat])
            [listOfSubtitle addObject:filePath];
    }
    return listOfSubtitle;
}

- (NSString *)_checkSubtitleFound:(NSString *)fileURL
{
    NSString *subtitlePath = @"";
    NSString *fileName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    NSMutableArray *listOfSubtitle = [[NSMutableArray alloc] init];
    listOfSubtitle = [self _listOfSubtitle];
    NSString *fileSub;
    for (int count = 0; count < listOfSubtitle.count; count++) {
        fileSub = [NSString stringWithFormat:@"%@", listOfSubtitle[count]];
        if ([fileSub rangeOfString:fileName].location != NSNotFound)
            subtitlePath = [listOfSubtitle objectAtIndex:count];
    }
    return subtitlePath;
}

@end
