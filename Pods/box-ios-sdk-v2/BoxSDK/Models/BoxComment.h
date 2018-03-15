//
//  BoxComment.h
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxModel.h"
#import "BoxCommentableItem.h"

@class BoxUser, BoxItem;

/**
 * BoxComment represents comments on Box.
 */
@interface BoxComment : BoxModel <BoxCommentableItem>

/**
 * The message represented by this comment
 */
@property (nonatomic, readonly) NSString *message;

/**
 * The tagged message represented by this comment.
 *
 * The difference between this and the message is that this contains
 * any user that was mentioned in the message
 */
@property (nonatomic, readonly) NSString *taggedMessage;

/**
 * The BoxUser who created this comment.
 */
@property (nonatomic, readonly) BoxUser *createdBy;

/**
 * The date this user was first created on Box.
 */
@property (nonatomic, readonly) NSDate *createdAt;

/**
 * The date this item was last updated on Box.
 */
@property (nonatomic, readonly) NSDate *modifiedAt;

/**
 * Whether this comment is a reply to another comment
 */
@property (nonatomic, readonly) NSNumber *isReplyComment;

/**
 * The item this comment was made on
 */
@property (nonatomic, readonly) BoxModel<BoxCommentableItem> *item;

@end
