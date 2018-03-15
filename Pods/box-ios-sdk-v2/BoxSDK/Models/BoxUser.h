//
//  BoxUser.h
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxModel.h"

/**
 * BoxUser represents users on Box.
 */
@interface BoxUser : BoxModel

/**
 * An user's name.
 */
@property (nonatomic, readonly) NSString *name;

/**
 * An user's login.
 */
@property (nonatomic, readonly) NSString *login;

/**
 * The date this user was first created on Box.
 */
@property (nonatomic, readonly) NSDate *createdAt;

/**
 * The date this item was last updated on Box.
 */
@property (nonatomic, readonly) NSDate *modifiedAt;

/**
 * The user's role.
 */
@property (nonatomic, readonly) NSString *role;

/**
 * The user's language.
 */
@property (nonatomic, readonly) NSString *language;

/**
 * The user's space amount.
 */
@property (nonatomic, readonly) NSNumber *spaceAmount;

/**
 * The amount of space the user has consumed.
 */
@property (nonatomic, readonly) NSNumber *spaceUsed;

/**
 * The largest file size a user can upload at once.
 */
@property (nonatomic, readonly) NSNumber *maxUploadSize;

/**
 * The tracking codes set for this user.
 */
@property (nonatomic, readonly) NSDictionary *trackingCodes;

/**
 * Whether this user can see other users within his enterprise.
 */
@property (nonatomic, readonly) NSNumber *canSeeManagedUsers;

/**
 * Whether sync is enabled for this user.
 */
@property (nonatomic, readonly) NSNumber *isSyncEnabled;

/**
 * The status of this user. It can either be active or inactive.
 */
@property (nonatomic, readonly) NSString *status;

/**
 * The user's job title.
 */
@property (nonatomic, readonly) NSString *jobTitle;

/**
 * The user's phone number.
 */
@property (nonatomic, readonly) NSString *phone;

/**
 * The user's phone number.
 */
@property (nonatomic, readonly) NSString *address;

/**
 * The url to this user's avatar.
 */
@property (nonatomic, readonly) NSURL *avatarURL;

/**
 * Whether this user is exempt from device limits.
 */
@property (nonatomic, readonly) NSNumber *isExemptFromDeviceLimits;

/**
 * Whether this user is exempt from login verification.
 */
@property (nonatomic, readonly) NSNumber *isExemptFromLoginVerification;

/**
 * Whether this user's account has been deactivated.
 */
@property (nonatomic, readonly) NSNumber *isDeactivated;

/**
 * Whether this user's needs to reset his/her password.
 */
@property (nonatomic, readonly) NSNumber *isPasswordResetRequired;

/**
 * The reason why the user's account was deactivated.
 */
@property (nonatomic, readonly) NSString *deactivatedReason;

/**
 * Whether this user has a custom avatar.
 */
@property (nonatomic, readonly) NSNumber *hasCustomAvatar;

@end
