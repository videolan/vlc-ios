/*****************************************************************************
 * PlaylistExpansionTests.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Zachary Wilson <ztwilson2002 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <XCTest/XCTest.h>
#import <VLCKit/VLCKit.h>
#import "VLCPlaybackService.h"

@interface VLCPlaybackService (PlaylistExpansionTests)
- (void)_expandMediaList:(VLCMediaList *)children forMedia:(VLCMedia *)parent;
- (void)mediaPlayerSubitemsChanged:(VLCMedia *)media;
- (void)mediaPlayerLengthChanged:(int64_t)length;
@end

@interface PlaylistMedia : VLCMedia
@property (nonatomic, strong) VLCMediaList *discoveredSubitems;
@property (nonatomic, strong) VLCTime *testLength;
@end
@implementation PlaylistMedia
- (VLCMediaList *)subitems { return self.discoveredSubitems; }
- (VLCTime *)length { return self.testLength ?: [VLCTime nullTime]; }
@end

@interface PlaylistLibraryMedia : NSObject
@property (nonatomic) int64_t duration;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) BOOL isExternalMedia;
@property (nonatomic) UInt32 nbSubscriptions;
@end
@implementation PlaylistLibraryMedia
@end

@interface PlaylistListPlayer : VLCMediaListPlayer
@property (nonatomic) NSUInteger playbackCommands;
@property (nonatomic, strong) NSNumber *lastPlayedIndex;
@end
@implementation PlaylistListPlayer
- (void)play { self.playbackCommands++; }
- (void)playItemAtNumber:(NSNumber *)index
{
    self.playbackCommands++;
    self.lastPlayedIndex = index;
}
- (BOOL)next
{
    self.playbackCommands++;
    return YES;
}
@end

@interface PlaylistPlaybackService : VLCPlaybackService
@property (nonatomic, strong) VLCMedia *testPlaying;
@property (nonatomic, strong) PlaylistListPlayer *testListPlayer;
@property (nonatomic, readonly) NSUInteger starts;
@end
@implementation PlaylistPlaybackService
- (instancetype)init
{
    self = [super init];
    if (self) {
        _testListPlayer = [PlaylistListPlayer new];
        [self setValue:_testListPlayer forKey:@"listPlayer"];
    }
    return self;
}
- (VLCMedia *)currentlyPlayingMedia { return self.testPlaying; }
- (NSUInteger)starts { return self.testListPlayer.playbackCommands; }
@end

@interface PlaylistExpansionTests : XCTestCase
@end
@implementation PlaylistExpansionTests
- (PlaylistMedia *)media:(NSString *)name
{
    return [[PlaylistMedia alloc] initWithURL:[NSURL URLWithString:[@"https://example.invalid/" stringByAppendingString:name]]];
}

- (void)drainMainQueue
{
    XCTestExpectation *drained = [self expectationWithDescription:@"Pending queue updates"];
    dispatch_async(dispatch_get_main_queue(), ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:1.0];
}

- (void)testOrderedMetadataURLDeduplicationAndDuplicateCallback
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *parent = [self media:@"channels.m3u"];
    PlaylistMedia *first = [self media:@"channel"];
    VLCMedia *second = [self media:@"channel"];
    VLCMedia *third = [self media:@"another-channel"];
    first.metaData.title = @"News";
    first.testLength = [VLCTime timeWithNumber:@3000];
    second.metaData.title = @"News repeat";
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[parent]];
    service.testPlaying = parent;
    VLCMediaList *children = [[VLCMediaList alloc] initWithArray:@[first, second, third, first, third]];
    [service _expandMediaList:children forMedia:parent];
    XCTAssertEqual(service.mediaList.count, 2);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:0].metaData.title, @"News");
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:0].length.value, @3000);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:1], third);
    XCTAssertEqualObjects(service.testPlaying, parent);
    XCTAssertEqual(service.starts, 0);
    VLCMediaList *expanded = service.mediaList;
    [service _expandMediaList:children forMedia:parent];
    XCTAssertEqual(service.mediaList, expanded);
    XCTAssertEqual(service.starts, 0);
}

- (void)testRemovedParentAndEmptyDiscoveryDoNothing
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *parent = [self media:@"channels.m3u"];
    VLCMedia *other = [self media:@"movie"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[other]];
    VLCMediaList *original = service.mediaList;
    [service _expandMediaList:[[VLCMediaList alloc] initWithArray:@[[self media:@"child"]]] forMedia:parent];
    XCTAssertEqual(service.mediaList, original);
    [service _expandMediaList:[VLCMediaList new] forMedia:other];
    XCTAssertEqual(service.mediaList, original);
    XCTAssertEqual(service.starts, 0);
}

- (void)testUnrelatedPlaybackAndShuffleOrderArePreserved
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *parent = [self media:@"channels.m3u"];
    VLCMedia *other = [self media:@"movie"];
    VLCMedia *first = [self media:@"first"];
    VLCMedia *second = [self media:@"second"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[parent, other]];
    service.testPlaying = other;
    service.shuffleMode = YES;
    service.shuffledList = [[VLCMediaList alloc] initWithArray:@[other, parent]];
    [service _expandMediaList:[[VLCMediaList alloc] initWithArray:@[first, second]] forMedia:parent];
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:0], first);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:1], second);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:0], other);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:1], first);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:2], second);
    XCTAssertEqualObjects([service valueForKey:@"currentIndex"], @0);
    XCTAssertEqualObjects(service.testPlaying, other);
    XCTAssertEqualObjects([service valueForKey:@"shuffledOrder"], (@[@2, @0, @1]));
    XCTAssertEqual(service.starts, 0);
}

- (void)testAlreadyPlayingChildIsNotRestarted
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *parent = [self media:@"channels.m3u"];
    VLCMedia *first = [self media:@"first"];
    VLCMedia *second = [self media:@"second"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[parent]];
    service.testPlaying = second;
    [service _expandMediaList:[[VLCMediaList alloc] initWithArray:@[first, second]] forMedia:parent];
    XCTAssertEqualObjects(service.testPlaying, second);
    XCTAssertEqualObjects([service valueForKey:@"currentIndex"], @1);
    XCTAssertEqual(service.starts, 0);
}

- (void)testExpansionWithoutPlayingMediaSelectsTheFirstEntry
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *parent = [self media:@"channels.m3u"];
    VLCMedia *other = [self media:@"movie"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[other, parent]];
    [service _expandMediaList:[[VLCMediaList alloc] initWithArray:@[[self media:@"first"]]] forMedia:parent];
    XCTAssertEqual(service.mediaList.count, 2);
    XCTAssertEqualObjects([service valueForKey:@"currentIndex"], @0);
    XCTAssertEqual(service.starts, 0);
}

- (void)testActivePlaylistSelectsFirstChildWithoutRestartingPlayback
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *parent = [self media:@"channels.m3u"];
    VLCMedia *other = [self media:@"movie"];
    VLCMedia *first = [self media:@"first"];
    VLCMedia *second = [self media:@"second"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[parent, other]];
    service.testPlaying = parent;
    service.shuffleMode = YES;
    service.shuffledList = [[VLCMediaList alloc] initWithArray:@[other, parent]];
    __block NSUInteger notifications = 0;
    id token = [NSNotificationCenter.defaultCenter addObserverForName:VLCPlaybackServiceMediaListDidChange
                                                              object:service queue:nil
                                                          usingBlock:^(NSNotification *note) { notifications++; }];
    VLCMediaList *children = [[VLCMediaList alloc] initWithArray:@[first, second]];
    [service _expandMediaList:children forMedia:parent];
    [service _expandMediaList:children forMedia:parent];
    XCTAssertEqualObjects(service.testPlaying, parent);
    XCTAssertEqualObjects([service valueForKey:@"currentIndex"], @1);
    XCTAssertEqual(service.shuffledList.count, 3);
    XCTAssertEqual(service.testListPlayer.mediaList, service.shuffledList);
    XCTAssertEqual(service.starts, 0);
    XCTAssertEqual(notifications, 1);
    [NSNotificationCenter.defaultCenter removeObserver:token];
}

- (void)testPlayerCallbackUsesTheReportedPlaylistWithoutItsMediaDelegate
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    PlaylistMedia *parent = [[PlaylistMedia alloc] initWithURL:[NSURL URLWithString:@"https://example.invalid/channels.m3u"]];
    VLCMedia *child = [self media:@"channel"];
    VLCMedia *other = [self media:@"movie"];
    parent.discoveredSubitems = [[VLCMediaList alloc] initWithArray:@[child]];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[parent, other]];
    service.testPlaying = parent;
    [service mediaPlayerSubitemsChanged:parent];
    service.testPlaying = other;
    [self drainMainQueue];
    XCTAssertNil(parent.delegate);
    XCTAssertEqual(service.mediaList.count, 2);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:0], child);
    XCTAssertEqualObjects(service.testPlaying, other);
    XCTAssertEqual(service.starts, 0);
}

- (void)testCachedPlaylistCanBeReappendedAndExpandedAgain
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    PlaylistMedia *parent = [[PlaylistMedia alloc] initWithURL:[NSURL URLWithString:@"https://example.invalid/cached.m3u"]];
    VLCMedia *first = [self media:@"first"];
    VLCMedia *second = [self media:@"second"];
    VLCMedia *other = [self media:@"other"];
    parent.discoveredSubitems = [[VLCMediaList alloc] initWithArray:@[first, second]];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[parent]];
    service.testPlaying = parent;
    [service mediaPlayerSubitemsChanged:parent];
    [self drainMainQueue];
    XCTAssertEqual(service.mediaList.count, 2);

    service.mediaList = [[VLCMediaList alloc] initWithArray:@[other]];
    [service appendMedia:parent];
    __block NSUInteger notifications = 0;
    id token = [NSNotificationCenter.defaultCenter addObserverForName:VLCPlaybackServiceMediaListDidChange
                                                              object:service queue:nil
                                                          usingBlock:^(NSNotification *note) { notifications++; }];
    [service mediaPlayerSubitemsChanged:parent];
    [self drainMainQueue];
    VLCMediaList *expanded = service.mediaList;
    [service mediaPlayerSubitemsChanged:parent];
    [self drainMainQueue];
    XCTAssertEqual(service.mediaList, expanded);
    XCTAssertEqual(service.mediaList.count, 3);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:0], other);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:1], first);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:2], second);
    XCTAssertEqualObjects([service valueForKey:@"currentIndex"], @1);
    XCTAssertEqual(service.testListPlayer.mediaList, expanded);
    XCTAssertNil(parent.delegate);
    XCTAssertEqual(service.starts, 0);
    XCTAssertEqual(notifications, 1);
    [NSNotificationCenter.defaultCenter removeObserver:token];
}

- (void)testAppendMaintainsShuffleOrderWithoutStartingPlayback
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *first = [self media:@"first"];
    VLCMedia *second = [self media:@"second"];
    VLCMedia *third = [self media:@"third"];
    XCTAssertEqual([service appendMedia:first], 0);
    XCTAssertEqual([service appendMedia:second], 1);
    service.testPlaying = first;
    service.shuffleMode = YES;
    NSArray *order = [[service valueForKey:@"shuffledOrder"] copy];
    __block NSUInteger notifications = 0;
    id token = [NSNotificationCenter.defaultCenter addObserverForName:VLCPlaybackServiceMediaListDidChange
                                                              object:service queue:nil
                                                          usingBlock:^(NSNotification *note) { notifications++; }];
    XCTAssertEqual([service appendMedia:third], 2);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:2], third);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:2], third);
    XCTAssertEqualObjects([service valueForKey:@"shuffledOrder"], [order arrayByAddingObject:@2]);
    XCTAssertEqualObjects(service.testPlaying, first);
    XCTAssertEqual(service.starts, 0);
    XCTAssertEqual(notifications, 1);
    [NSNotificationCenter.defaultCenter removeObserver:token];
    service.shuffleMode = NO;
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:2], third);
    service.shuffleMode = YES;
    XCTAssertNotEqual([service.shuffledList indexOfMedia:third], NSNotFound);
}

- (void)testAppendToEmptyShuffledQueue
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    service.shuffleMode = YES;
    VLCMedia *media = [self media:@"first"];
    XCTAssertEqual([service appendMedia:media], 0);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:0], media);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:0], media);
    XCTAssertEqualObjects([service valueForKey:@"shuffledOrder"], @[@0]);
    XCTAssertEqual(service.starts, 0);
}

- (void)testAppendPreservesTheOnlyItemWhenShuffleIsEnabled
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *first = [self media:@"first"];
    VLCMedia *second = [self media:@"second"];
    [service appendMedia:first];
    service.testPlaying = first;
    service.shuffleMode = YES;
    XCTAssertEqual([service appendMedia:second], 1);
    XCTAssertEqual(service.shuffledList.count, 2);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:0], first);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:1], second);
    XCTAssertEqualObjects([service valueForKey:@"shuffledOrder"], (@[@0, @1]));
    XCTAssertEqual(service.starts, 0);
}

- (void)testAppendAfterClearingTheQueueDiscardsOldShuffleIndices
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    [service appendMedia:[self media:@"old-first"]];
    [service appendMedia:[self media:@"old-second"]];
    service.shuffleMode = YES;
    service.mediaList = [VLCMediaList new];
    [service setValue:nil forKey:@"shuffledList"];
    [service setValue:@(-1) forKey:@"currentIndex"];
    VLCMedia *media = [self media:@"new"];
    XCTAssertEqual([service appendMedia:media], 0);
    XCTAssertEqual(service.shuffledList.count, 1);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:0], media);
    XCTAssertEqualObjects([service valueForKey:@"shuffledOrder"], @[@0]);
}

- (void)testAppendAfterShuffledSessionRebuildsTheOrderForTheNewQueue
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    NSArray<VLCMedia *> *previousSession = @[[self media:@"a"], [self media:@"b"], [self media:@"c"],
                                             [self media:@"d"], [self media:@"e"]];
    service.mediaList = [[VLCMediaList alloc] initWithArray:previousSession];
    service.testPlaying = previousSession[3];
    service.shuffleMode = NO;
    service.shuffleMode = YES;
    VLCMedia *playing = [self media:@"playing"];
    VLCMedia *appended = [self media:@"appended"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[playing]];
    service.testPlaying = playing;
    [service setValue:nil forKey:@"shuffledList"];
    XCTAssertEqual([service appendMedia:appended], 1);
    XCTAssertEqual(service.shuffledList.count, 2);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:0], playing);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:1], appended);
    XCTAssertEqual(service.testListPlayer.mediaList, service.shuffledList);
    XCTAssertEqual(service.starts, 0);
}

- (void)testRemovingFromTheShuffledQueueUpdatesBothLists
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *first = [self media:@"first"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[first, [self media:@"second"], [self media:@"third"]]];
    service.testPlaying = first;
    service.shuffleMode = YES;
    VLCMedia *removed = [service.shuffledList mediaAtIndex:2];
    [service removeMediaFromMediaListAtIndex:2];
    XCTAssertEqual(service.mediaList.count, 2);
    XCTAssertEqual(service.shuffledList.count, 2);
    XCTAssertEqual([service.mediaList indexOfMedia:removed], NSNotFound);
    XCTAssertEqual([service.shuffledList indexOfMedia:removed], NSNotFound);
    XCTAssertEqualObjects([service.shuffledList mediaAtIndex:0], first);
    NSArray<NSNumber *> *order = [service valueForKey:@"shuffledOrder"];
    XCTAssertEqual(order.count, 2);
    for (NSUInteger i = 0; i < order.count; i++)
        XCTAssertEqualObjects([service.mediaList mediaAtIndex:order[i].unsignedIntegerValue], [service.shuffledList mediaAtIndex:i]);
    XCTAssertEqual(service.starts, 0);
}

- (void)testRemovingThePlayingItemPlaysTheEntryThatTookItsPlace
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *second = [self media:@"second"];
    VLCMedia *third = [self media:@"third"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[[self media:@"first"], second, third]];
    service.testPlaying = second;
    [service removeMediaFromMediaListAtIndex:1];
    XCTAssertEqual(service.mediaList.count, 2);
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:1], third);
    XCTAssertEqualObjects(service.testListPlayer.lastPlayedIndex, @1);
}

- (void)testRemovingAnEarlierItemKeepsNextOnTheFollowingEntry
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *third = [self media:@"third"];
    VLCMedia *fourth = [self media:@"fourth"];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[[self media:@"first"], [self media:@"second"], third, fourth]];
    service.testPlaying = third;
    [service playItemAtIndex:2];
    [service removeMediaFromMediaListAtIndex:0];
    [service next];
    XCTAssertEqualObjects([service.mediaList mediaAtIndex:2], fourth);
    XCTAssertEqualObjects(service.testListPlayer.lastPlayedIndex, @2);
}

- (void)testQueueTitlePrefersManagedLibraryOverGeneratedNativeTitle
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL fileURLWithPath:@"/queue-title-tests/original.mp4"]];
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    library.title = @"Renamed movie";
    XCTAssertGreaterThan(media.metaData.title.length, 0);
    XCTAssertNotEqualObjects(media.metaData.title, library.title);
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:library.title], @"Renamed movie");
}

- (void)testQueueTitlePrefersManagedLibraryOverPlaylistAlias
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *media = [self media:@"movie.mp4"];
    media.metaData.title = @"Playlist alias";
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    library.title = @"Library movie";
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:library.title], @"Library movie");
}

- (void)testQueueTitlePreservesStreamMetadataOverExternalPlaceholder
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *media = [self media:@"stream"];
    media.metaData.title = @"News channel";
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    library.isExternalMedia = YES;
    library.title = @"stream";
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:library.title], @"News channel");
    media.metaData.title = @"Evening news";
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:library.title], @"Evening news");
}

- (void)testQueueTitleUsesLibraryMetadataForExternalPodcast
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *media = [self media:@"episode.mp3"];
    media.metaData.title = @"Embedded title";
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    library.isExternalMedia = YES;
    library.nbSubscriptions = 1;
    library.title = @"Episode from feed";
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:library.title], @"Episode from feed");
}

- (void)testQueueTitleFallsBackToNativeWithoutUsableLibraryTitle
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *media = [self media:@"movie.mp4"];
    NSString *nativeTitle = media.metaData.title;
    XCTAssertGreaterThan(nativeTitle.length, 0);
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:nil libraryTitle:nil], nativeTitle);
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:nil libraryTitle:@"Unrelated title"], nativeTitle);
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:@""], nativeTitle);
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:nil], nativeTitle);
    media.metaData.title = @"Native metadata title";
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:nil libraryTitle:nil], @"Native metadata title");
}

- (void)testQueueTitlePreservesCallerLibraryFormatting
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    VLCMedia *media = [self media:@"movie.mp4"];
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    library.title = @"Movie.mp4";
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:@"Movie"], @"Movie");
    XCTAssertEqualObjects([service queueTitleForMedia:media libraryMedia:(id)library libraryTitle:library.title], @"Movie.mp4");
}

- (void)testQueueDurationPrefersMediaThenLibraryAndHidesUnknown
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    PlaylistMedia *media = [self media:@"duration"];
    PlaylistLibraryMedia *library = [PlaylistLibraryMedia new];
    library.duration = 125000;
    media.testLength = [VLCTime nullTime];
    XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:(id)library], @"02:05");
    media.testLength = [VLCTime timeWithNumber:@3000];
    XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:(id)library], @"00:03");
    media.testLength = [VLCTime timeWithNumber:@0];
    XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:(id)library], @"");
    media.testLength = [VLCTime timeWithNumber:@(-1)];
    XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:(id)library], @"");
    media.testLength = [VLCTime nullTime];
    XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:nil], @"");
    library.duration = 0;
    XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:(id)library], @"");
}

- (void)testRuntimeDurationRefreshesCapturedItemAndSuppressesUnchangedDisplay
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    PlaylistMedia *first = [self media:@"first"];
    PlaylistMedia *second = [self media:@"second"];
    first.testLength = [VLCTime timeWithNumber:@3000];
    second.testLength = [VLCTime timeWithNumber:@7000];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[first, second]];
    service.testPlaying = first;
    service.shuffleMode = YES;
    __block NSUInteger notifications = 0;
    id token = [NSNotificationCenter.defaultCenter addObserverForName:VLCPlaybackServiceMediaDurationDidChange
                                                              object:service queue:nil
                                                          usingBlock:^(NSNotification *note) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertEqualObjects(note.userInfo[@"media"], first);
        notifications++;
    }];
    first.testLength = [VLCTime timeWithNumber:@125000];
    [service mediaPlayerLengthChanged:125000];
    service.testPlaying = second;
    [self drainMainQueue];
    XCTAssertEqualObjects(first.length.value, @125000);
    XCTAssertEqualObjects(second.length.value, @7000);
    XCTAssertEqualObjects([service queueDurationForMedia:first libraryMedia:nil], @"02:05");
    service.testPlaying = first;
    [service mediaPlayerLengthChanged:125000];
    [self drainMainQueue];
    XCTAssertEqual(notifications, 1);
    first.testLength = [VLCTime timeWithNumber:@0];
    [service mediaPlayerLengthChanged:0];
    [self drainMainQueue];
    XCTAssertEqualObjects(first.length.value, @0);
    XCTAssertEqualObjects([service queueDurationForMedia:first libraryMedia:nil], @"");
    XCTAssertEqual(notifications, 2);
    [service.mediaList removeMediaAtIndex:0];
    [service mediaPlayerLengthChanged:5000];
    [self drainMainQueue];
    XCTAssertEqual(notifications, 2);
    [NSNotificationCenter.defaultCenter removeObserver:token];
}

- (void)testDurationRefreshReadsLatestValueRatherThanDeferredEventPayload
{
    PlaylistPlaybackService *service = [PlaylistPlaybackService new];
    PlaylistMedia *media = [self media:@"duration"];
    media.testLength = [VLCTime timeWithNumber:@3000];
    service.mediaList = [[VLCMediaList alloc] initWithArray:@[media]];
    service.testPlaying = media;
    __block NSUInteger notifications = 0;
    id token = [NSNotificationCenter.defaultCenter addObserverForName:VLCPlaybackServiceMediaDurationDidChange
                                                              object:service queue:nil
                                                          usingBlock:^(NSNotification *note) {
        XCTAssertEqualObjects(note.userInfo[@"media"], media);
        XCTAssertEqualObjects([service queueDurationForMedia:media libraryMedia:nil], @"02:06");
        notifications++;
    }];
    [service mediaPlayerLengthChanged:125000];
    media.testLength = [VLCTime timeWithNumber:@126000];
    [self drainMainQueue];
    XCTAssertEqual(notifications, 1);
    [service mediaPlayerLengthChanged:125000];
    [self drainMainQueue];
    XCTAssertEqual(notifications, 1);
    [NSNotificationCenter.defaultCenter removeObserver:token];
}
@end
