/*****************************************************************************
 * PodcastBackgroundRefresher.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "PodcastBackgroundRefresher.h"
#import "VLCAppCoordinator.h"
#import "VLC-Swift.h"

#import <BackgroundTasks/BackgroundTasks.h>

static const NSTimeInterval kVLCPodcastRefreshInterval = 2 * 60 * 60;
static const NSTimeInterval kVLCPodcastDownloadDelay = 15 * 60;

@implementation PodcastBackgroundRefresher
{
    BGAppRefreshTask *_currentRefreshTask;
    BGProcessingTask *_currentDownloadTask;
    NSString *_refreshTaskIdentifier;
    NSString *_downloadTaskIdentifier;
}

+ (instancetype)sharedInstance
{
    static PodcastBackgroundRefresher *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PodcastBackgroundRefresher alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
        _refreshTaskIdentifier = [bundleIdentifier stringByAppendingString:@".podcast-refresh"];
        _downloadTaskIdentifier = [bundleIdentifier stringByAppendingString:@".podcast-download"];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(refreshDidEnd)
                                   name:NSNotification.VLCPodcastsRefreshDidEnd
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(cachingDidEnd)
                                   name:NSNotification.VLCPodcastsCachingDidEnd
                                 object:nil];
    }
    return self;
}

- (void)registerTasks
{
    BGTaskScheduler *scheduler = BGTaskScheduler.sharedScheduler;

    BOOL registered = [scheduler registerForTaskWithIdentifier:_refreshTaskIdentifier
                                                    usingQueue:dispatch_get_main_queue()
                                                 launchHandler:^(BGTask *task) {
        if (![task isKindOfClass:[BGAppRefreshTask class]]) {
            [task setTaskCompletedWithSuccess:NO];
            return;
        }
        [self runRefreshTask:(BGAppRefreshTask *)task];
    }];

    if (registered) {
        [self scheduleRefreshTask];
    } else {
        APLog(@"podcast background refresh: the task identifier is not permitted");
    }

    registered = [scheduler registerForTaskWithIdentifier:_downloadTaskIdentifier
                                               usingQueue:dispatch_get_main_queue()
                                            launchHandler:^(BGTask *task) {
        if (![task isKindOfClass:[BGProcessingTask class]]) {
            [task setTaskCompletedWithSuccess:NO];
            return;
        }
        [self runDownloadTask:(BGProcessingTask *)task];
    }];

    if (!registered) {
        APLog(@"podcast background download: the task identifier is not permitted");
    }
}

#pragma mark - feed refresh

- (void)scheduleRefreshTask
{
    BGAppRefreshTaskRequest *request =
        [[BGAppRefreshTaskRequest alloc] initWithIdentifier:_refreshTaskIdentifier];
    request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:kVLCPodcastRefreshInterval];

    NSError *error = nil;
    if (![BGTaskScheduler.sharedScheduler submitTaskRequest:request error:&error]) {
        APLog(@"podcast background refresh: failed to schedule (%@)", error.localizedDescription);
    }
}

- (void)runRefreshTask:(BGAppRefreshTask *)task
{
    [self scheduleRefreshTask];

    _currentRefreshTask = task;
    task.expirationHandler = ^{
        [self completeRefreshWithSuccess:NO];
    };

    [PodcastsOnAirBridge configureWithMediaLibraryService:VLCAppCoordinator.sharedInstance.mediaLibraryService];

    if (PodcastsOnAirBridge.numberOfShows == 0) {
        [self completeRefreshWithSuccess:YES];
        return;
    }

    if (![PodcastsOnAirBridge refreshAllSubscriptions]) {
        [self completeRefreshWithSuccess:NO];
    }
}

- (void)refreshDidEnd
{
    [self completeRefreshWithSuccess:YES];
}

- (void)completeRefreshWithSuccess:(BOOL)success
{
    BGAppRefreshTask *task = _currentRefreshTask;
    if (!task) {
        return;
    }
    _currentRefreshTask = nil;
    [task setTaskCompletedWithSuccess:success];
}

#pragma mark - episode downloads

- (void)scheduleDownloadTask
{
    BGProcessingTaskRequest *request =
        [[BGProcessingTaskRequest alloc] initWithIdentifier:_downloadTaskIdentifier];
    request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:kVLCPodcastDownloadDelay];
    request.requiresNetworkConnectivity = YES;
    request.requiresExternalPower = YES;

    NSError *error = nil;
    if (![BGTaskScheduler.sharedScheduler submitTaskRequest:request error:&error]) {
        APLog(@"podcast background download: failed to schedule (%@)", error.localizedDescription);
    }
}

- (void)runDownloadTask:(BGProcessingTask *)task
{
    _currentDownloadTask = task;
    task.expirationHandler = ^{
        [PodcastsOnAirBridge interruptCaching];
        [self completeDownloadWithSuccess:NO];
    };

    [PodcastsOnAirBridge configureWithMediaLibraryService:VLCAppCoordinator.sharedInstance.mediaLibraryService];

    if ([PodcastsOnAirBridge cacheNewEpisodes]) {
        return;
    }

    if (PodcastsOnAirBridge.automaticDownloadsEnabled) {
        [self scheduleDownloadTask];
    }
    [self completeDownloadWithSuccess:YES];
}

- (void)cachingDidEnd
{
    [self completeDownloadWithSuccess:YES];
}

- (void)completeDownloadWithSuccess:(BOOL)success
{
    BGProcessingTask *task = _currentDownloadTask;
    if (!task) {
        return;
    }
    _currentDownloadTask = nil;
    [task setTaskCompletedWithSuccess:success];
}

@end
