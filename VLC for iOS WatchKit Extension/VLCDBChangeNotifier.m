//
//  VLCDBChangeNotifier.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 01.04.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "VLCDBChangeNotifier.h"
#import <notify.h>


@interface VLCDBChangeNotifier ()
@property (nonatomic, strong) NSMapTable *observers;
@property (nonatomic, assign) int notification_token;
@end
@implementation VLCDBChangeNotifier

- (id)init
{
    self = [super init];
    if (self) {
        self.observers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsCopyIn];
    }
    [self startListening];
    return self;
}

- (void)dealloc {
    notify_cancel(_notification_token);
}

+ (instancetype)sharedNotifier
{
    static dispatch_once_t onceToken;
    static VLCDBChangeNotifier *instance;
    dispatch_once(&onceToken, ^{
        instance = [VLCDBChangeNotifier new];
    });
    return instance;
}

- (void)addObserver:(id)observer block:(void (^)(void))onUpdate {
    [self.observers setObject:onUpdate forKey:observer];
}

- (void)removeObserver:(id)observer {
    [self.observers removeObjectForKey:observer];
}

- (void)dbDidChange {
    for (void(^onUpdate)() in self.observers.objectEnumerator) {
        onUpdate();
    }
}
- (void)startListening {
    const char *notification_name = "org.videolan.ios-app.dbupdate";
    dispatch_queue_t queue = dispatch_get_main_queue();
    int registration_token;
    __weak typeof(self) weakSelf = self;
    notify_register_dispatch(notification_name, &registration_token, queue, ^ (int token) {
        [weakSelf dbDidChange];
    });
    self.notification_token = registration_token;
}

@end
