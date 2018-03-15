//
//  GRKArrayDiff+UITableView.h
//
//  Created by Levi Brown on July 12, 2015.
//  Copyright (c) 2015-2018 Levi Brown <mailto:levigroker@gmail.com> This work is
//  licensed under the Creative Commons Attribution 4.0 International License. To
//  view a copy of this license, visit https://creativecommons.org/licenses/by/4.0/
//
//  The above attribution and this license must accompany any version of the source
//  code, binary distributable, or derivatives.
//

#import <Foundation/Foundation.h>
#import "GRKArrayDiff.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface GRKArrayDiff (UITableView)

#if TARGET_OS_IPHONE

/**
 * Updates a given table view based on information contained in this GRKArrayDiff.
 *
 * @param tableView  The target table view to update.
 * @param section    The target section of the table view.
 * @param animation  The animation style to perform when updating the table.
 * @param completion A completion block which will be called once the table has been updated (and animations, if any, have completed). This can be `nil`.
 */
- (void)updateTableView:(nullable UITableView *)tableView section:(NSInteger)section animation:(UITableViewRowAnimation)animation completion:(nullable void(^)(void))completion;

#endif

@end
