///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMListMemberDevicesArg;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `ListMemberDevicesArg` struct.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMListMemberDevicesArg : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// The team's member id
@property (nonatomic, readonly, copy) NSString *teamMemberId;

/// Whether to list web sessions of the team's member
@property (nonatomic, readonly) NSNumber *includeWebSessions;

/// Whether to list linked desktop devices of the team's member
@property (nonatomic, readonly) NSNumber *includeDesktopClients;

/// Whether to list linked mobile devices of the team's member
@property (nonatomic, readonly) NSNumber *includeMobileClients;

#pragma mark - Constructors

///
/// Full constructor for the struct (exposes all instance variables).
///
/// @param teamMemberId The team's member id
/// @param includeWebSessions Whether to list web sessions of the team's member
/// @param includeDesktopClients Whether to list linked desktop devices of the
/// team's member
/// @param includeMobileClients Whether to list linked mobile devices of the
/// team's member
///
/// @return An initialized instance.
///
- (instancetype)initWithTeamMemberId:(NSString *)teamMemberId
                  includeWebSessions:(nullable NSNumber *)includeWebSessions
               includeDesktopClients:(nullable NSNumber *)includeDesktopClients
                includeMobileClients:(nullable NSNumber *)includeMobileClients;

///
/// Convenience constructor (exposes only non-nullable instance variables with
/// no default value).
///
/// @param teamMemberId The team's member id
///
/// @return An initialized instance.
///
- (instancetype)initWithTeamMemberId:(NSString *)teamMemberId;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `ListMemberDevicesArg` struct.
///
@interface DBTEAMListMemberDevicesArgSerializer : NSObject

///
/// Serializes `DBTEAMListMemberDevicesArg` instances.
///
/// @param instance An instance of the `DBTEAMListMemberDevicesArg` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMListMemberDevicesArg` API object.
///
+ (NSDictionary *)serialize:(DBTEAMListMemberDevicesArg *)instance;

///
/// Deserializes `DBTEAMListMemberDevicesArg` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMListMemberDevicesArg` API object.
///
/// @return An instantiation of the `DBTEAMListMemberDevicesArg` object.
///
+ (DBTEAMListMemberDevicesArg *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
