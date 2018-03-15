/*****************************************************************************
 * MLFile.m
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2015 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de
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

#import "MLFile.h"
#import "MLShow.h"
#import "MLShowEpisode.h"
#import "MLAlbum.h"
#import "MLAlbumTrack.h"
#import "MLMediaLibrary.h"
#import "MLThumbnailerQueue.h"
#import "MLFileParserQueue.h"

NSString *kMLFileTypeMovie = @"movie";
NSString *kMLFileTypeClip = @"clip";
NSString *kMLFileTypeTVShowEpisode = @"tvShowEpisode";
NSString *kMLFileTypeAudio = @"audio";
NSString *const MLFileThumbnailWasUpdated = @"MLFileThumbnailWasUpdated";

@implementation MLFile

- (NSString *)description
{
    return [NSString stringWithFormat:@"<MLFile title='%@'>", [self title]];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.thumbnailName = [NSUUID UUID].UUIDString;
}

+ (NSArray *)allFiles
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return [NSArray array];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:moc];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES"]];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [request setSortDescriptors:@[descriptor]];

    NSError *error;
    NSArray *movies = [moc executeFetchRequest:request error:&error];
    if (!movies) {
        APLog(@"WARNING: %@", error);
    }

    return movies;
}

+ (NSArray *)fileForURL:(NSURL *)url;
{
    if (!url) return nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return [NSArray array];

    NSString *path = url.path.stringByRemovingPercentEncoding;
#if TARGET_OS_IPHONE
    path = [[MLMediaLibrary sharedMediaLibrary] pathRelativeToDocumentsFolderFromAbsolutPath:path];
#endif
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:moc];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"path == %@", path]];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [request setSortDescriptors:@[descriptor]];

    NSError *error;
    NSArray *files = [moc executeFetchRequest:request error:&error];
    if (!files)
        APLog(@"WARNING: %@", error);

    return files;
}

+ (instancetype)fileForURIRepresentation:(NSURL *)uriRepresentation {
    NSManagedObject *object = [[MLMediaLibrary sharedMediaLibrary] objectForURIRepresentation:uriRepresentation];
    if ([object isKindOfClass:[MLFile class]]) {
        return (MLFile *)object;
    } else {
        return nil;
    }
}

- (BOOL)isKindOfType:(NSString *)type
{
    return [self.type isEqualToString:type];
}
- (BOOL)isMovie
{
    return [self isKindOfType:kMLFileTypeMovie];
}
- (BOOL)isClip
{
    return [self isKindOfType:kMLFileTypeClip];
}
- (BOOL)isShowEpisode
{
    return [self isKindOfType:kMLFileTypeTVShowEpisode];
}
- (BOOL)isAlbumTrack
{
    return [self isKindOfType:kMLFileTypeAudio];
}

- (BOOL)isSupportedAudioFile
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([[self.path lastPathComponent] rangeOfString:@"\\.(aac|aiff|aif|amr|aob|ape|axa|caf|flac|it|m2a|m4a|m4b|mka|mlp|mod|mp1|mp2|mp3|mpa|mpc|oga|oma|opus|rmi|s3m|spx|tta|voc|vqf|w64|wav|wma|wv|xa|xm)$" options:options].location != NSNotFound);
}

- (NSString *)artworkURL
{
    if ([self isShowEpisode]) {
        return self.showEpisode.artworkURL;
    }
    return [self primitiveValueForKey:@"artworkURL"];
}

- (NSString *)title
{
    if ([self isShowEpisode]) {
        MLShowEpisode *episode = self.showEpisode;
        NSMutableString *name = [[NSMutableString alloc] init];
        if (episode.show.name.length > 0)
            [name appendString:episode.show.name];

        if ([episode.seasonNumber intValue] > 0) {
            if (![name isEqualToString:@""])
                [name appendString:@" - "];
            [name appendFormat:@"S%02dE%02d", [episode.seasonNumber intValue], [episode.episodeNumber intValue]];
        }

        if (episode.name.length > 0) {
            if ([name length] > 0)
                [name appendString:@" - "];
            [name appendString:episode.name];
        }

        NSString *returnValue = [NSString stringWithString:name];
        return returnValue;
    } else if ([self isAlbumTrack]) {
        MLAlbumTrack *track = self.albumTrack;
        if (track && track.title.length > 0) {
            NSMutableString *name = [[NSMutableString alloc] initWithString:track.title];

            if (track.album.name.length > 0)
                [name appendFormat:@" - %@", track.album.name];

            if (track.artist.length > 0)
                [name appendFormat:@" - %@", track.artist];

            NSString *returnValue = [NSString stringWithString:name];
            return returnValue;
        }
    }

    [self willAccessValueForKey:@"title"];
    NSString *ret = [self primitiveValueForKey:@"title"];
    [self didAccessValueForKey:@"title"];

    return ret;
}

@dynamic seasonNumber;
@dynamic remainingTime;
@dynamic releaseYear;
@dynamic lastSubtitleTrack;
@dynamic lastAudioTrack;
@dynamic playCount;
@dynamic artworkURL;
@dynamic type;
@dynamic title;
@dynamic shortSummary;
@dynamic currentlyWatching;
@dynamic episodeNumber;
@dynamic hasFetchedInfo;
@dynamic noOnlineMetaData;
@dynamic showEpisode;
@dynamic labels;
@dynamic tracks;
@dynamic isOnDisk;
@dynamic duration;
@dynamic artist;
@dynamic album;
@dynamic albumTrackNumber;
@dynamic folderTrackNumber;
@dynamic genre;
@dynamic albumTrack;
@dynamic unread;
@dynamic thumbnailName;

- (NSNumber *)lastPosition
{
    [self willAccessValueForKey:@"lastPosition"];
    NSNumber *ret = [self primitiveValueForKey:@"lastPosition"];
    [self didAccessValueForKey:@"lastPosition"];
    return ret;
}

- (void)setLastPosition:(NSNumber *)lastPosition
{
    @try {
        [self willChangeValueForKey:@"lastPosition"];
        [self setPrimitiveValue:lastPosition forKey:@"lastPosition"];
        [self didChangeValueForKey:@"lastPosition"];
    }
    @catch (NSException *exception) {
        APLog(@"setLastPosition raised exception");
    }
}

- (NSString *)path
{
    [self willAccessValueForKey:@"path"];
    NSString *ret = [self primitiveValueForKey:@"path"];
    [self didAccessValueForKey:@"path"];
    return ret;
}

- (void)setPath:(NSString *)path
{
    @try {
        [self willChangeValueForKey:@"path"];
        [self setPrimitiveValue:path forKey:@"path"];
        [self didChangeValueForKey:@"path"];
    }
    @catch (NSException *exception) {
        APLog(@"setUrl raised exception");
    }
}
- (void)setUrl:(NSURL *)url {
    NSString *path = url.path;
#if TARGET_OS_IPHONE
    path = [[MLMediaLibrary sharedMediaLibrary] pathRelativeToDocumentsFolderFromAbsolutPath:path];
#endif
    self.path = path;
}

- (NSURL *)url {
    NSString *path = self.path;
#if TARGET_OS_IPHONE
    path = [[MLMediaLibrary sharedMediaLibrary] absolutPathFromPathRelativeToDocumentsFolder:path];
#endif
    return [NSURL fileURLWithPath:path];
}

- (NSString *)thumbnailPath
{
    MLMediaLibrary *sharedLibrary = [MLMediaLibrary sharedMediaLibrary];
    NSString *folder = [sharedLibrary thumbnailFolderPath];
    NSString *thumbnailFullName = [[self thumbnailName] stringByAppendingPathExtension:@"png"];
    return [folder stringByAppendingPathComponent:thumbnailFullName];
}

- (UIImage *)computedThumbnail
{
    NSString *thumbnailPath = [self thumbnailPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath])
        return [UIImage imageWithContentsOfFile:[self thumbnailPath]];
    else {
        if (self.isAlbumTrack) {
            if (self.albumTrack.containsArtwork)
                [[MLFileParserQueue sharedFileParserQueue] addFile:self];
        }
    }
    return nil;
}

- (void)setComputedThumbnailScaledForDevice:(UIImage *)thumbnail
{
    [self setComputedThumbnail:[UIImage scaleImage:thumbnail
                                         toFitRect:(CGRect){CGPointZero, (CGSize)[UIImage preferredThumbnailSizeForDevice]}]];
}

- (void)setComputedThumbnail:(UIImage *)image
{
    NSURL *url = [NSURL fileURLWithPath:[self thumbnailPath]];

    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:[[self thumbnailPath] stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    if (!image) {
        [manager removeItemAtURL:url error:nil];
        return;
    }

    /* device category 3 or later include hardware accelerated JPEG support so we should prefer
     * the now faster and smaller format.
     * For compatiblity reasons, we also call those JPEG files *.png */
    if ([[MLMediaLibrary sharedMediaLibrary] deviceSpeedCategory] >= 3)
        [UIImageJPEGRepresentation(image, .9) writeToURL:url atomically:YES];
    else
        [UIImagePNGRepresentation(image) writeToURL:url atomically:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:MLFileThumbnailWasUpdated
                                                        object:self];
}

- (BOOL)isSafe
{
    [self willAccessValueForKey:@"isSafe"];
    NSNumber *ret = [self primitiveValueForKey:@"isSafe"];
    [self didAccessValueForKey:@"isSafe"];
    return [ret boolValue];
}

- (void)setIsSafe:(BOOL)isSafe
{
    @try {
        [self willChangeValueForKey:@"isSafe"];
        [self setPrimitiveValue:@(isSafe) forKey:@"isSafe"];
        [self didChangeValueForKey:@"isSafe"];
    }
    @catch (NSException *exception) {
        APLog(@"setIsSafe raised exception");
    }
}

- (BOOL)isBeingParsed
{
    [self willAccessValueForKey:@"isBeingParsed"];
    NSNumber *ret = [self primitiveValueForKey:@"isBeingParsed"];
    [self didAccessValueForKey:@"isBeingParsed"];
    return [ret boolValue];
}

- (void)setIsBeingParsed:(BOOL)isBeingParsed
{
    @try {
        [self willChangeValueForKey:@"isBeingParsed"];
        [self setPrimitiveValue:@(isBeingParsed) forKey:@"isBeingParsed"];
        [self didChangeValueForKey:@"isBeingParsed"];
    }
    @catch (NSException *exception) {
        APLog(@"setIsBeingParsed raised exception");
    }
}

- (BOOL)thumbnailTimeouted
{
    [self willAccessValueForKey:@"thumbnailTimeouted"];
    NSNumber *ret = [self primitiveValueForKey:@"thumbnailTimeouted"];
    [self didAccessValueForKey:@"thumbnailTimeouted"];
    return [ret boolValue];
}

- (void)setThumbnailTimeouted:(BOOL)thumbnailTimeouted
{
    @try {
        [self willChangeValueForKey:@"thumbnailTimeouted"];
        [self setPrimitiveValue:@(thumbnailTimeouted) forKey:@"thumbnailTimeouted"];
        [self didChangeValueForKey:@"thumbnailTimeouted"];
    }
    @catch (NSException *exception) {
        APLog(@"setThumbnailTimeouted raised exception");
    }
}

- (void)willDisplay
{
    [[MLThumbnailerQueue sharedThumbnailerQueue] setHighPriorityForFile:self];
}

- (void)didHide
{
    [[MLThumbnailerQueue sharedThumbnailerQueue] setDefaultPriorityForFile:self];
}

- (NSManagedObject *)videoTrack
{
    NSSet *tracks = [self tracks];
    if (!tracks)
        return nil;
    for (NSManagedObject *track in tracks) {
        if ([[[track entity] name] isEqualToString:@"VideoTrackInformation"])
            return track;
    }
    return nil;
}

- (size_t)fileSizeInBytes
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [manager attributesOfItemAtPath:[self.url path] error:nil];
    NSNumber *fileSize = fileAttributes[NSFileSize];
    return [fileSize unsignedLongValue];
}

#if TARGET_OS_IOS
- (CSSearchableItemAttributeSet *)coreSpotlightAttributeSet
{
    if (!SYSTEM_RUNS_IOS9)
        return nil;

    NSString *workString;

    CSSearchableItemAttributeSet* attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:@"public.audiovisual-content"];
    attributeSet.title = self.title;
    attributeSet.metadataModificationDate = [NSDate date];
    attributeSet.addedDate = [NSDate date];
    attributeSet.duration = @(self.duration.intValue / 1000);
    attributeSet.streamable = @(0);
    attributeSet.deliveryType = @(0);
    attributeSet.local = @(1);
    attributeSet.playCount = @(0);

    UIImage *computedThumb = self.computedThumbnail;
    if (computedThumb) {
        attributeSet.thumbnailData = UIImageJPEGRepresentation(computedThumb, .9);
        computedThumb = nil;
    }

    NSArray *tracks = [[self tracks] allObjects];
    NSUInteger trackCount = tracks.count;
    NSMutableArray *codecs = [NSMutableArray new];
    NSMutableArray *languages = [NSMutableArray new];
    for (NSUInteger x = 0; x < trackCount; x++) {
        NSManagedObject *track = tracks[x];
        NSString *codec = [track valueForKey:@"codec"];
        if (codec)
            [codecs addObject:codec];
        NSString *language = [track valueForKey:@"language"];
        if (language != nil)
            [languages addObject:language];

        NSString *trackEntityName = [[track entity] name];
        if ([trackEntityName isEqualToString:@"VideoTrackInformation"]) {
            attributeSet.videoBitRate = [track valueForKey:@"bitrate"];
        } else if ([trackEntityName isEqualToString:@"AudioTrackInformation"]) {
            attributeSet.audioSampleRate = [track valueForKey:@"sampleRate"];
            attributeSet.audioChannelCount = [track valueForKey:@"channelsNumber"];
            attributeSet.audioBitRate = [track valueForKey:@"bitrate"];
        }
    }
    attributeSet.codecs = [NSArray arrayWithArray:codecs];
    attributeSet.languages = [NSArray arrayWithArray:languages];

    workString = self.genre;
    if (workString)
        attributeSet.genre = workString;

    MLAlbumTrack *albumTrack = self.albumTrack;
    if (albumTrack) {
        attributeSet.artist = albumTrack.artist;
        attributeSet.title = albumTrack.title;
        attributeSet.audioTrackNumber = albumTrack.trackNumber;
        MLAlbum *album = albumTrack.album;
        if (album) {
            attributeSet.album = album.name;
        }
        if (attributeSet.genre == nil)
            attributeSet.genre = albumTrack.genre;
    }

    return attributeSet;
}

- (void)updateCoreSpotlightEntry
{
    if ([CSSearchableIndex class] && [CSSearchableIndex isIndexingAvailable]) {
        /* create final CS item, which will replace the earlier entity */
        CSSearchableItemAttributeSet *attributeSet = [self coreSpotlightAttributeSet];

        CSSearchableItem *item;
        item = [[CSSearchableItem alloc] initWithUniqueIdentifier:self.objectID.URIRepresentation.absoluteString
                                                 domainIdentifier:[[MLMediaLibrary sharedMediaLibrary] applicationGroupIdentifier]
                                                     attributeSet:attributeSet];
        [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item] completionHandler:nil];
    }
}
#endif

@end
