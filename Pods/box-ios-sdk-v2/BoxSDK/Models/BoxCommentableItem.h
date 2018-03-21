//
//  BoxCommentableItem.h
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

@protocol BoxCommentableItem<NSObject>

/**
 * The type of object returned by the API.
 */
@property (nonatomic, readonly) NSString *type;

/**
 * The ID of this model. This field is unique for all objects of the same type but may
 * not be unique across model types.
 */
@property (nonatomic, readonly) NSString *modelID;

@end
