///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails;
@class DBTEAMLOGSharedFolderMembershipManagementPolicy;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `SharedFolderChangeMemberManagementPolicyDetails` struct.
///
/// Changed who can manage the membership of a shared folder.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// Target asset index.
@property (nonatomic, readonly) NSNumber *targetIndex;

/// Original shared folder name.
@property (nonatomic, readonly, copy) NSString *originalFolderName;

/// Shared folder type. Might be missing due to historical data gap.
@property (nonatomic, readonly, copy, nullable) NSString *sharedFolderType;

/// New membership management policy.
@property (nonatomic, readonly) DBTEAMLOGSharedFolderMembershipManagementPolicy *dNewValue;

/// Previous membership management policy. Might be missing due to historical
/// data gap.
@property (nonatomic, readonly, nullable) DBTEAMLOGSharedFolderMembershipManagementPolicy *previousValue;

#pragma mark - Constructors

///
/// Full constructor for the struct (exposes all instance variables).
///
/// @param targetIndex Target asset index.
/// @param originalFolderName Original shared folder name.
/// @param dNewValue New membership management policy.
/// @param sharedFolderType Shared folder type. Might be missing due to
/// historical data gap.
/// @param previousValue Previous membership management policy. Might be missing
/// due to historical data gap.
///
/// @return An initialized instance.
///
- (instancetype)initWithTargetIndex:(NSNumber *)targetIndex
                 originalFolderName:(NSString *)originalFolderName
                          dNewValue:(DBTEAMLOGSharedFolderMembershipManagementPolicy *)dNewValue
                   sharedFolderType:(nullable NSString *)sharedFolderType
                      previousValue:(nullable DBTEAMLOGSharedFolderMembershipManagementPolicy *)previousValue;

///
/// Convenience constructor (exposes only non-nullable instance variables with
/// no default value).
///
/// @param targetIndex Target asset index.
/// @param originalFolderName Original shared folder name.
/// @param dNewValue New membership management policy.
///
/// @return An initialized instance.
///
- (instancetype)initWithTargetIndex:(NSNumber *)targetIndex
                 originalFolderName:(NSString *)originalFolderName
                          dNewValue:(DBTEAMLOGSharedFolderMembershipManagementPolicy *)dNewValue;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the
/// `SharedFolderChangeMemberManagementPolicyDetails` struct.
///
@interface DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetailsSerializer : NSObject

///
/// Serializes `DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails`
/// instances.
///
/// @param instance An instance of the
/// `DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails` API object.
///
+ (NSDictionary *)serialize:(DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails *)instance;

///
/// Deserializes `DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails`
/// instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails` API object.
///
/// @return An instantiation of the
/// `DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails` object.
///
+ (DBTEAMLOGSharedFolderChangeMemberManagementPolicyDetails *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
