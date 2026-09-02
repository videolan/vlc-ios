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

@implementation PodcastBackgroundRefresher
{
    BGAppRefreshTask *_currentTask;
    NSString *_taskIdentifier;
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
        _taskIdentifier = [NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".podcast-refresh"];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshDidEnd)
                                                     name:NSNotification.VLCPodcastsRefreshDidEnd
                                                   object:nil];
    }
    return self;
}

- (void)registerTask
{
    BOOL registered = [BGTaskScheduler.sharedScheduler
                       registerForTaskWithIdentifier:_taskIdentifier
                       usingQueue:dispatch_get_main_queue()
                       launchHandler:^(BGTask *task) {
        if (![task isKindOfClass:[BGAppRefreshTask class]]) {
            [task setTaskCompletedWithSuccess:NO];
            return;
        }
        [self runTask:(BGAppRefreshTask *)task];
    }];

    if (!registered) {
        APLog(@"podcast background refresh: the task identifier is not permitted");
        return;
    }

    [self scheduleTask];
}

- (void)scheduleTask
{
    BGAppRefreshTaskRequest *request =
        [[BGAppRefreshTaskRequest alloc] initWithIdentifier:_taskIdentifier];
    request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:kVLCPodcastRefreshInterval];

    NSError *error = nil;
    if (![BGTaskScheduler.sharedScheduler submitTaskRequest:request error:&error]) {
        APLog(@"podcast background refresh: failed to schedule (%@)", error.localizedDescription);
    }
}

- (void)runTask:(BGAppRefreshTask *)task
{
    [self scheduleTask];

    _currentTask = task;
    task.expirationHandler = ^{
        [self completeWithSuccess:NO];
    };

    [PodcastsOnAirBridge configureWithMediaLibraryService:VLCAppCoordinator.sharedInstance.mediaLibraryService];

    if (PodcastsOnAirBridge.numberOfShows == 0) {
        [self completeWithSuccess:YES];
        return;
    }

    if (![PodcastsOnAirBridge refreshAllSubscriptions]) {
        [self completeWithSuccess:NO];
    }
}

- (void)refreshDidEnd
{
    [self completeWithSuccess:YES];
}

- (void)completeWithSuccess:(BOOL)success
{
    BGAppRefreshTask *task = _currentTask;
    if (!task) {
        return;
    }
    _currentTask = nil;
    [task setTaskCompletedWithSuccess:success];
}

@end
