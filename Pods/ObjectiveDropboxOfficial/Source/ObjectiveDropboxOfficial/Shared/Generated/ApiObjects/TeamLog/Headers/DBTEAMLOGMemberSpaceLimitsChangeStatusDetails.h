///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMLOGMemberSpaceLimitsChangeStatusDetails;
@class DBTEAMLOGSpaceLimitsStatus;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `MemberSpaceLimitsChangeStatusDetails` struct.
///
/// Changed the status with respect to whether the team member is under or over
/// storage quota specified by policy.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMLOGMemberSpaceLimitsChangeStatusDetails : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// Previous storage quota status.
@property (nonatomic, readonly) DBTEAMLOGSpaceLimitsStatus *previousValue;

/// New storage quota status.
@property (nonatomic, readonly) DBTEAMLOGSpaceLimitsStatus *dNewValue;

#pragma mark - Constructors

///
/// Full constructor for the struct (exposes all instance variables).
///
/// @param previousValue Previous storage quota status.
/// @param dNewValue New storage quota status.
///
/// @return An initialized instance.
///
- (instancetype)initWithPreviousValue:(DBTEAMLOGSpaceLimitsStatus *)previousValue
                            dNewValue:(DBTEAMLOGSpaceLimitsStatus *)dNewValue;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `MemberSpaceLimitsChangeStatusDetails`
/// struct.
///
@interface DBTEAMLOGMemberSpaceLimitsChangeStatusDetailsSerializer : NSObject

///
/// Serializes `DBTEAMLOGMemberSpaceLimitsChangeStatusDetails` instances.
///
/// @param instance An instance of the
/// `DBTEAMLOGMemberSpaceLimitsChangeStatusDetails` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMLOGMemberSpaceLimitsChangeStatusDetails` API object.
///
+ (NSDictionary *)serialize:(DBTEAMLOGMemberSpaceLimitsChangeStatusDetails *)instance;

///
/// Deserializes `DBTEAMLOGMemberSpaceLimitsChangeStatusDetails` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMLOGMemberSpaceLimitsChangeStatusDetails` API object.
///
/// @return An instantiation of the
/// `DBTEAMLOGMemberSpaceLimitsChangeStatusDetails` object.
///
+ (DBTEAMLOGMemberSpaceLimitsChangeStatusDetails *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
