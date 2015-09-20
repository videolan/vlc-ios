//
//  VLCWatchMessage.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 02.05.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "VLCWatchMessage.h"

NSString *const VLCWatchMessageNameGetNowPlayingInfo = @"getNowPlayingInfo";
NSString *const VLCWatchMessageNamePlayPause = @"playpause";
NSString *const VLCWatchMessageNameSkipForward = @"skipForward";
NSString *const VLCWatchMessageNameSkipBackward = @"skipBackward";
NSString *const VLCWatchMessageNamePlayFile = @"playFile";
NSString *const VLCWatchMessageNameSetVolume = @"setVolume";
NSString *const VLCWatchMessageNameNotification = @"notification";
NSString *const VLCWatchMessageNameRequestThumbnail = @"requestThumbnail";
NSString *const VLCWatchMessageNameRequestDB = @"requestDB";

NSString *const VLCWatchMessageKeyURIRepresentation = @"URIRepresentation";


static NSString *const VLCWatchMessageNameKey = @"name";
static NSString *const VLCWatchMessagePayloadKey = @"payload";

@implementation VLCWatchMessage
@synthesize dictionaryRepresentation = _dictionaryRepresentation;

- (instancetype)initWithName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _payload = payload;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *name = dictionary[VLCWatchMessageNameKey];
    id<NSObject> payloadObject = dictionary[VLCWatchMessagePayloadKey];
    id payload = [self payloadFromPayloadObject:payloadObject];
    return [self initWithName:name payload:payload];
}

- (NSDictionary *)dictionaryRepresentation
{
    if (!_dictionaryRepresentation) {
        _dictionaryRepresentation = [self.class messageDictionaryForName:self.name payload:self.payload];
    }
    return _dictionaryRepresentation;
}

- (id)payloadFromPayloadObject:(id<NSObject>)payloadObject {
    id payload;
    if ([payloadObject isKindOfClass:[NSData class]]) {
        @try {
            payload = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)payloadObject];
        }
        @catch (NSException *exception) {
            NSLog(@"%s Failed to decode payload with exception: %@",__PRETTY_FUNCTION__,exception);
        }
    } else {
        payload = payloadObject;
    }
    return payload;
}

+ (NSDictionary *)messageDictionaryForName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload
{
    id payloadObject;
    BOOL noArchiving = [payload isKindOfClass:[NSNumber class]] || [payload isKindOfClass:[NSString class]];
    if (noArchiving) {
        payloadObject = payload;
    } else if (payload != nil) {
        payloadObject = [NSKeyedArchiver archivedDataWithRootObject:payload];
    }
    // we use nil termination so when payloadData is nil payload is not set
    return [NSDictionary dictionaryWithObjectsAndKeys:
            name,VLCWatchMessageNameKey,
            payloadObject, VLCWatchMessagePayloadKey,
            nil];
}
+ (NSDictionary *)messageDictionaryForName:(NSString *)name
{
    return [self messageDictionaryForName:name payload:nil];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p name=%@, payload=%@>",NSStringFromClass(self.class), self, _name, _payload];
}

@end
