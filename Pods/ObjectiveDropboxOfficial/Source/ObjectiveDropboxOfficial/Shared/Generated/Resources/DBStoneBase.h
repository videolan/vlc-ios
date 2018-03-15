///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"
#import "DBStoneSerializers.h"

NS_ASSUME_NONNULL_BEGIN

///
/// Route object used to encapsulate route-specific information.
///
@interface DBRoute : NSObject

/// Name of the route.
@property (nonatomic, readonly, copy) NSString *name;

/// Namespace that the route is contained within.
@property (nonatomic, readonly, copy) NSString *namespace_;

/// Whether the route is deprecated.
@property (nonatomic, readonly) NSNumber *deprecated;

/// Class of the route's result object type (must implement `DBSerializable`
/// protocol).
@property (nonatomic, readonly, nullable) Class<DBSerializable> resultType;

/// Class of the route's error object type (must implement `DBSerializable`
/// protocol). Note: this class is only for route-specific errors, as opposed
/// to more generic Dropbox API errors, as represented by the `DBRequestError`
/// class.
@property (nonatomic, readonly, nullable) Class<DBSerializable> errorType;

/// Custom attributes associated with each route (can pertain to authentication
/// type, host cluster, request-type, etc.).
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *attrs;

/// Serialization block for the route's result object type, if that result object
/// type is an `NSArray`, otherwise nil.
@property (nonatomic, readonly, nullable) id (^dataStructSerialBlock)(id dataStruct);

/// Deserialization block for the route's result object type, if that result object
/// type is a data structure, otherwise nil.
@property (nonatomic, readonly, nullable) id (^dataStructDeserialBlock)(id dataStruct);

/// Initializes the route object.
- (nonnull instancetype)init:(NSString *)name
                  namespace_:(NSString *)namespace_
                  deprecated:(NSNumber *)deprecated
                  resultType:(nullable Class<DBSerializable>)resultType
                   errorType:(nullable Class<DBSerializable>)errorType
                       attrs:(NSDictionary<NSString *, NSString *> *)attrs
       dataStructSerialBlock:(id (^_Nullable)(id))dataStructSerialBlock
     dataStructDeserialBlock:(id (^_Nullable)(id))dataStructDeserialBlock;

@end

///
/// Wrapper object designed to represent a nil response from the Dropbox API.
///
@interface DBNilObject : NSObject

@end

NS_ASSUME_NONNULL_END
