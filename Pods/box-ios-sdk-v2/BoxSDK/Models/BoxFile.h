//
//  BoxFile.h
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItem.h"
#import "BoxCommentableItem.h"

/**
 * BoxFile represents files on Box.
 */
@interface BoxFile : BoxItem <BoxCommentableItem>

/**
 * The SHA1 of the file's content.
 */
@property (nonatomic, readonly) NSString *SHA1;

/**
 * The number of comments that have been made on the file.
 * This will be nil unless you explicitly request it through "?fields=comment_count".
 */
@property (nonatomic, readonly) NSNumber *commentCount;

@end
