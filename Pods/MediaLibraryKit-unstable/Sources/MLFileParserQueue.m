/*****************************************************************************
 * MLFileParserQueue.m
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <CommonCrypto/CommonDigest.h> // for MD5

#import "MLFileParserQueue.h"
#import "MLFile.h"
#import "MLMediaLibrary.h"
#import "MLCrashPreventer.h"
#import "MLAlbumTrack.h"
#import "MLAlbum.h"
#import "MLTitleDecrapifier.h"
#import "MLThumbnailerQueue.h"

#ifdef MLKIT_READONLY_TARGET

@implementation MLFileParserQueue

+ (MLFileParserQueue *)sharedFileParserQueue
{
    static MLFileParserQueue *shared = nil;
    if (!shared) {
        shared = [[MLFileParserQueue alloc] init];
    }
    return shared;
}

- (void)addFile:(MLFile *)file
{
}

- (void)setHighPriorityForFile:(MLFile *)file
{
}

- (void)setDefaultPriorityForFile:(MLFile *)file
{
}

- (void)stop
{
}

- (void)resume
{
}

@end

#else

@interface MLFileParserQueue ()
{
    NSDictionary *_fileDescriptionToOperation;
    NSOperationQueue *_queue;
}
@end

@interface MLParsingOperation : NSOperation <VLCMediaDelegate>
{
    MLFile *_file;
    VLCMedia *_media;
    BOOL _parsing;
    NSTimer *_timeOutTimer;
    dispatch_semaphore_t _parsingSema;
}
@property (strong,readwrite) MLFile *file;
@end

@interface MLFileParserQueue ()
- (void)didFinishOperation:(MLParsingOperation *)op;
@end

@implementation MLParsingOperation
@synthesize file=_file;
- (id)initWithFile:(MLFile *)file;
{
    if (!(self = [super init]))
        return nil;
    self.file = file;
    return self;
}

- (void)parse
{
    MLFileParserQueue *parserQueue = [MLFileParserQueue sharedFileParserQueue];
    [parserQueue.queue setSuspended:YES]; // Balanced in -mediaDidFinishParsing

    NSAssert(!_media, @"We are already parsing");

    MLFile *file = self.file;
    APLog(@"Starting PARSE %@", file);
    [[MLCrashPreventer sharedPreventer] willParseFile:file];

    _parsing = YES;
    _timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:3. target:self selector:@selector(cancelParsing:) userInfo:nil repeats:NO];

    _media = [VLCMedia mediaWithURL:file.url];
    _media.delegate = self;
    [_media parseWithOptions:VLCMediaParseLocal|VLCMediaFetchLocal];
     // Balanced in -mediaDidFinishParsing:
}

- (void)cancelParsing:(NSTimer *)timer
{
    if (_parsing && _media) {
        [self mediaDidFinishParsing:_media];
        return;
    }

    _parsing = NO;
    [self endParsing];
}

- (void)main
{
    _parsingSema = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self parse];
    });

    dispatch_semaphore_wait(_parsingSema, DISPATCH_TIME_FOREVER);
}

- (void)mediaDidFinishParsing:(VLCMedia *)media
{
    _parsing = NO;
    [_timeOutTimer invalidate];

    APLog(@"Parsed %@ - %lu tracks", media, (unsigned long)[[_media tracksInformation] count]);

    if (_media.delegate != self) {
        [self endParsing];
        return;
    }

    MLFile *file = self.file;

    _media.delegate = nil;
    NSArray *tracks = [_media tracksInformation];
    NSMutableSet *tracksSet = [NSMutableSet setWithCapacity:[tracks count]];
    BOOL mediaHasVideo = NO;
    for (NSDictionary *track in tracks) {
        NSString *type = track[VLCMediaTracksInformationType];
        NSManagedObject *trackInfo = nil;
        if ([type isEqualToString:VLCMediaTracksInformationTypeVideo]) {
            trackInfo = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"VideoTrackInformation"];
            [trackInfo setValue:track[VLCMediaTracksInformationVideoWidth] forKey:@"width"];
            [trackInfo setValue:track[VLCMediaTracksInformationVideoHeight] forKey:@"height"];
            mediaHasVideo = YES;
        } else if ([type isEqualToString:VLCMediaTracksInformationTypeAudio]) {
            trackInfo = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"AudioTrackInformation"];
            [trackInfo setValue:track[VLCMediaTracksInformationAudioRate] forKey:@"sampleRate"];
            [trackInfo setValue:track[VLCMediaTracksInformationAudioChannelsNumber] forKey:@"channelsNumber"];
        } else if ([type isEqualToString:VLCMediaTracksInformationTypeText]) {
            trackInfo = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"SubtitlesTrackInformation"];
            [trackInfo setValue:track[VLCMediaTracksInformationTextEncoding] forKey:@"textEncoding"];
        }

        if (trackInfo) {
            [trackInfo setValue:track[VLCMediaTracksInformationBitrate] forKey:@"bitrate"];
            [trackInfo setValue:[track[VLCMediaTracksInformationCodec] stringValue] forKey:@"codec"];
            [trackInfo setValue:track[VLCMediaTracksInformationCodec] forKey:@"codecFourCC"];
            [trackInfo setValue:track[VLCMediaTracksInformationCodecLevel] forKey:@"codecLevel"];
            [trackInfo setValue:track[VLCMediaTracksInformationCodecProfile] forKey:@"codecProfile"];
            [trackInfo setValue:track[VLCMediaTracksInformationLanguage] forKey:@"language"];
            [tracksSet addObject:trackInfo];
        }
    }
    /* assume the best if we fail to parse the video */
    if (tracks.count == 0) {
        mediaHasVideo = YES;
    }

    @try {
        [file setTracks:tracksSet];
        [file setDuration:[[_media length] numberValue]];
    }
    @catch (NSException *exception) {
        APLog(@"we failed to write some metadata because the file disappeared in front of us");
    }

    if (!mediaHasVideo) {
        NSDictionary *audioContentInfo = [_media metaDictionary];
        if (audioContentInfo && audioContentInfo.count > 0) {
            NSString *title = audioContentInfo[VLCMetaInformationTitle];
            NSString *artist = audioContentInfo[VLCMetaInformationArtist];
            NSString *albumName = audioContentInfo[VLCMetaInformationAlbum];
            NSString *releaseYear = audioContentInfo[VLCMetaInformationDate];
            NSString *genre = audioContentInfo[VLCMetaInformationGenre];
            NSString *trackNumber = audioContentInfo[VLCMetaInformationTrackNumber];
            NSString *discNumber = audioContentInfo[VLCMetaInformationDiscNumber];

            MLAlbum *album = nil;

            BOOL wasCreated = NO;

            @try {
                NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
                if (albumName)
                    [mutDict setObject:albumName forKey:MLAlbumTrackAlbumName];
                if (title)
                    [mutDict setObject:title forKey:MLAlbumTrackTrackName];
                if (trackNumber)
                    [mutDict setObject:@([trackNumber integerValue]) forKey:MLAlbumTrackNumber];
                if (discNumber)
                    [mutDict setObject:@([discNumber integerValue]) forKey:MLAlbumTrackDiscNumber];

                MLAlbumTrack *track = [MLAlbumTrack trackWithMetadata:[NSDictionary dictionaryWithDictionary:mutDict]
                                                       createIfNeeded:YES
                                                           wasCreated:&wasCreated];
                if (track) {
                    album = track.album;
                    track.title = title ? title : @"";
                    track.artist = artist ? artist : @"";
                    track.genre = genre ? genre : @"";
                    album.releaseYear = releaseYear ? releaseYear : @"";

                    if (!track.title || [track.title isEqualToString:@""])
                        track.title = [MLTitleDecrapifier decrapify:file.title];

                    [track addFilesObject:file];
                    file.albumTrack = track;
                }
            }
            @catch (NSException *exception) {
                APLog(@"album track creation failed");
            }
        }

        @try {
            file.type = kMLFileTypeAudio;
        }
        @catch (NSException *exception) {
            APLog(@"file type setting failed");
        }

        APLog(@"'%@' is an audio file, fetching artwork", file.title);
        NSString *artist, *albumName, *title;
        BOOL skipOperation = NO;

        if (file.isAlbumTrack) {
            artist = file.albumTrack.artist;
            albumName = file.albumTrack.album.name;

            if (!file.albumTrack.containsArtwork)
                skipOperation = YES;
        }

        title = file.title;

        if (!title) {
            NSDictionary *poorMansContentInfo = [MLTitleDecrapifier audioContentInfoFromFile:file];
            if (poorMansContentInfo)
                title = poorMansContentInfo[VLCMetaInformationTitle];
            @try {
                file.title = title;
            }
            @catch (NSException *exception) {
                APLog(@"file title setting failed");
            }
        }

        if (!skipOperation) {
            @try {
                NSString *artworkPath = [self artworkPathForMediaItemWithTitle:title Artist:artist andAlbumName:albumName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:artworkPath]) {
                    file.computedThumbnail = [UIImage scaleImage:[UIImage imageWithContentsOfFile:artworkPath]
                                                       toFitRect:(CGRect){CGPointZero, [UIImage preferredThumbnailSizeForDevice]}];
                }
                if (file.computedThumbnail == nil)
                    file.albumTrack.containsArtwork = NO;
            }
            @catch (NSException *exception) {
                APLog(@"file thumbnail setting failed");
            }
        }
    }
    @try {
        file.hasFetchedInfo = @(YES);
    }
    @catch (NSException *exception) {
        APLog(@"failed to set that we fetch info for the file");
    }

    if (mediaHasVideo) {
        MLMediaLibrary *sharedLibrary = [MLMediaLibrary sharedMediaLibrary];
        [sharedLibrary computeThumbnailForFile:file];
        [sharedLibrary fetchMetaDataForFile:file];
    }

#if TARGET_OS_IOS
    if ([[MLMediaLibrary sharedMediaLibrary] isSpotlightIndexingEnabled]) {
        [file updateCoreSpotlightEntry];
    }
#endif

    [self endParsing];
}

- (void)endParsing
{
    MLFileParserQueue *parserQueue = [MLFileParserQueue sharedFileParserQueue];
    [[MLCrashPreventer sharedPreventer] didParseFile:self.file];
    _media = nil;
    [parserQueue.queue setSuspended:NO];
    [parserQueue didFinishOperation:self];
    dispatch_semaphore_signal(_parsingSema);
}

#pragma mark - audio file specific code

- (NSString *)artworkPathForMediaItemWithTitle:(NSString *)title Artist:(NSString*)artist andAlbumName:(NSString*)albumname
{
    NSString *artworkURL;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = searchPaths[0];
    cacheDir = [cacheDir stringByAppendingFormat:@"/%@", [[NSBundle mainBundle] bundleIdentifier]];

    if ((artist.length == 0 || albumname.length == 0) && title != nil && title.length > 0) {
        /* Use generated hash to find art */
        artworkURL = [cacheDir stringByAppendingFormat:@"/art/arturl/%@/art.jpg", [self _md5FromString:title]];
    } else {
        /* Otherwise, it was cached by artist and album */
        artworkURL = [cacheDir stringByAppendingFormat:@"/art/artistalbum/%@/%@/art.jpg", artist, albumname];
    }

    return artworkURL;
}

- (NSString *)_md5FromString:(NSString *)string
{
    const char *ptr = [string UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];

    return [NSString stringWithString:output];
}

@end

@implementation MLFileParserQueue
@synthesize queue=_queue;
+ (MLFileParserQueue *)sharedFileParserQueue
{
    static MLFileParserQueue *shared = nil;
    if (!shared) {
        shared = [[MLFileParserQueue alloc] init];
    }
    return shared;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        _fileDescriptionToOperation = [[NSMutableDictionary alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:1];
    }
    return self;
}

static inline NSString *hashFromFile(MLFile *file)
{
    NSString *path = [[[file objectID] URIRepresentation] absoluteString];
    const char *cstr = [path cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:path.length];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);

    NSMutableString *sha1Hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [sha1Hash appendFormat:@"%02x", digest[i]];

    return sha1Hash;
}

- (void)didFinishOperation:(MLParsingOperation *)op
{
    [_fileDescriptionToOperation setValue:nil forKey:hashFromFile(op.file)];
}

- (void)addFile:(MLFile *)file
{
    if (_fileDescriptionToOperation[hashFromFile(file)])
        return;
    if (![[MLCrashPreventer sharedPreventer] isFileSafe:file]) {
        APLog(@"%@ is unsafe and will crash, ignoring", file);
        return;
    }
    if (file.isBeingParsed) {
        APLog(@"%@ is already being parsed, ignoring", file);
        return;
    }
    MLParsingOperation *op = [[MLParsingOperation alloc] initWithFile:file];
    [_fileDescriptionToOperation setValue:op forKey:hashFromFile(file)];
    [self.queue addOperation:op];
}

- (void)stop
{
    if (![[MLCrashPreventer sharedPreventer] fileParsingInProgress])
        [_queue setSuspended:YES];
    [_queue setMaxConcurrentOperationCount:0];
}

- (void)resume
{
    if (![[MLCrashPreventer sharedPreventer] fileParsingInProgress])
        [_queue setSuspended:NO];
    [_queue setMaxConcurrentOperationCount:1];
}

- (void)setHighPriorityForFile:(MLFile *)file
{
    MLParsingOperation *op = _fileDescriptionToOperation[hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityHigh];
}

- (void)setDefaultPriorityForFile:(MLFile *)file
{
    MLParsingOperation *op = _fileDescriptionToOperation[hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityNormal];
}

@end

#endif
