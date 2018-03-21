///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBPAPERPaperApiCursorError;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `PaperApiCursorError` union.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBPAPERPaperApiCursorError : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// The `DBPAPERPaperApiCursorErrorTag` enum type represents the possible tag
/// states with which the `DBPAPERPaperApiCursorError` union can exist.
typedef NS_ENUM(NSInteger, DBPAPERPaperApiCursorErrorTag) {
  /// The provided cursor is expired.
  DBPAPERPaperApiCursorErrorExpiredCursor,

  /// The provided cursor is invalid.
  DBPAPERPaperApiCursorErrorInvalidCursor,

  /// The provided cursor contains invalid user.
  DBPAPERPaperApiCursorErrorWrongUserInCursor,

  /// Indicates that the cursor has been invalidated. Call the corresponding
  /// non-continue endpoint to obtain a new cursor.
  DBPAPERPaperApiCursorErrorReset,

  /// (no description).
  DBPAPERPaperApiCursorErrorOther,

};

/// Represents the union's current tag state.
@property (nonatomic, readonly) DBPAPERPaperApiCursorErrorTag tag;

#pragma mark - Constructors

///
/// Initializes union class with tag state of "expired_cursor".
///
/// Description of the "expired_cursor" tag state: The provided cursor is
/// expired.
///
/// @return An initialized instance.
///
- (instancetype)initWithExpiredCursor;

///
/// Initializes union class with tag state of "invalid_cursor".
///
/// Description of the "invalid_cursor" tag state: The provided cursor is
/// invalid.
///
/// @return An initialized instance.
///
- (instancetype)initWithInvalidCursor;

///
/// Initializes union class with tag state of "wrong_user_in_cursor".
///
/// Description of the "wrong_user_in_cursor" tag state: The provided cursor
/// contains invalid user.
///
/// @return An initialized instance.
///
- (instancetype)initWithWrongUserInCursor;

///
/// Initializes union class with tag state of "reset".
///
/// Description of the "reset" tag state: Indicates that the cursor has been
/// invalidated. Call the corresponding non-continue endpoint to obtain a new
/// cursor.
///
/// @return An initialized instance.
///
- (instancetype)initWithReset;

///
/// Initializes union class with tag state of "other".
///
/// @return An initialized instance.
///
- (instancetype)initWithOther;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Tag state methods

///
/// Retrieves whether the union's current tag state has value "expired_cursor".
///
/// @return Whether the union's current tag state has value "expired_cursor".
///
- (BOOL)isExpiredCursor;

///
/// Retrieves whether the union's current tag state has value "invalid_cursor".
///
/// @return Whether the union's current tag state has value "invalid_cursor".
///
- (BOOL)isInvalidCursor;

///
/// Retrieves whether the union's current tag state has value
/// "wrong_user_in_cursor".
///
/// @return Whether the union's current tag state has value
/// "wrong_user_in_cursor".
///
- (BOOL)isWrongUserInCursor;

///
/// Retrieves whether the union's current tag state has value "reset".
///
/// @return Whether the union's current tag state has value "reset".
///
- (BOOL)isReset;

///
/// Retrieves whether the union's current tag state has value "other".
///
/// @return Whether the union's current tag state has value "other".
///
- (BOOL)isOther;

///
/// Retrieves string value of union's current tag state.
///
/// @return A human-readable string representing the union's current tag state.
///
- (NSString *)tagName;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `DBPAPERPaperApiCursorError` union.
///
@interface DBPAPERPaperApiCursorErrorSerializer : NSObject

///
/// Serializes `DBPAPERPaperApiCursorError` instances.
///
/// @param instance An instance of the `DBPAPERPaperApiCursorError` API object.
///
/// @return A json-compatible dictionary representation of the
/// `DBPAPERPaperApiCursorError` API object.
///
+ (NSDictionary *)serialize:(DBPAPERPaperApiCursorError *)instance;

///
/// Deserializes `DBPAPERPaperApiCursorError` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBPAPERPaperApiCursorError` API object.
///
/// @return An instantiation of the `DBPAPERPaperApiCursorError` object.
///
+ (DBPAPERPaperApiCursorError *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
