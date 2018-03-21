//
//  BoxUsersRequestBuilder.h
//  BoxSDK
//
//  Created on 8/15/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"

// User status
typedef NSString BoxAPIUserStatus;
extern BoxAPIUserStatus *const BoxAPIUserStatusActive;
extern BoxAPIUserStatus *const BoxAPIUserStatusInActive;

// User role
typedef NSString BoxAPIUserRole;
extern BoxAPIUserRole *const BoxAPIUserRoleCoAdmin;
extern BoxAPIUserRole *const BoxAPIUserRoleUser;

/**
 * BoxUsersRequestBuilder is the class for building API requests relating
 * to BoxUser.
 *
 * This class allows constructing of the HTTP body for `POST` and 'PUT` requests as well
 * as setting query string parameters on the request.
 */
@interface BoxUsersRequestBuilder : BoxAPIRequestBuilder

/** @name Settable fields */

/**
 * The login of the user.
 */
@property (nonatomic, readwrite, strong) NSString *login;

/**
 * The name of the user.
 */
@property (nonatomic, readwrite, strong) NSString *name;

/**
 * The role of the user.
 * Can be `coadmin` or `user`.
 */
@property (nonatomic, readwrite, strong) NSString *role;

/**
 * The language that will be displayed for localization for this user.
 * The language to pass in will follow the http://en.wikipedia.org/wiki/ISO_639-1
 *   standard.
 */
@property (nonatomic, readwrite, strong) NSString *language;

/**
 * A boolean representing whether a user can use Box Sync.
 */
@property (nonatomic, readwrite, strong) NSNumber *isSyncEnabled;

/**
 * The phone number of this user.
 */
@property (nonatomic, readwrite, strong) NSString *phone;

/**
 * The address of this user.
 */
@property (nonatomic, readwrite, strong) NSString *address;

/**
 * The job title of this user.
 */
@property (nonatomic, readwrite, strong) NSString *jobTitle;

/**
 * A number representing the user's total allotted space.
 */
@property (nonatomic, readwrite, strong) NSNumber *spaceAmount;

/**
 * The tracking code for this user.
 */
@property (nonatomic, readwrite, strong) NSDictionary *trackingCodes;

/**
 * A boolean representing whether the user can see other users in his enterprise.
 * This only applies for users who have an enterprise account.
 */
@property (nonatomic, readwrite, strong) NSNumber *canSeeManagedUsers;

/**
 * A number representing the user's active status.
 * May only be `active` or `inactive`.
 */
@property (nonatomic, readwrite, strong) NSString *status;

/**
 * A boolean representing whether the user is exempt from enterprise device limits.
 * This only applies for users who have an enterprise account.
 */
@property (nonatomic, readwrite, strong) NSNumber *isExemptFromDeviceLimits;

/**
 * A boolean representing whether the user is exempt from two factor authentication.
 * This only applies for users who have an enterprise account.
 */
@property (nonatomic, readwrite, strong) NSNumber *isExemptFromLoginVerification;

/**
 * A boolean representing whether the user is required to reset his password.
 */
@property (nonatomic, readwrite, strong) NSNumber *isPasswordResetRequired;

@end
