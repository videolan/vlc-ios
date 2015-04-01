//
//  VLCDBChangeNotifier.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 01.04.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VLCDBChangeNotifier : NSObject
+ (instancetype)sharedNotifier;
- (void)addObserver:(id)observer block:(void (^)(void))onUpdate;
- (void)removeObserver:(id)observer;
@end
