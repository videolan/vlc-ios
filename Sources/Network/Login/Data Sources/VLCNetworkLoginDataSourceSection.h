/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@protocol VLCNetworkLoginDataSourceSection <NSObject>
@property (nonatomic) NSUInteger sectionIndex;

- (void)configureWithTableView:(UITableView *)tableView;
- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView;
- (NSString *)cellIdentifierForRow:(NSUInteger)row;
- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row;


@optional
// return NSNotFound to prevent selection
// if not implemented but implements didSelectRow: assume selection is possible
- (NSUInteger)willSelectRow:(NSUInteger)row;
- (void)didSelectRow:(NSUInteger)row;

// if not implemented assume editable
- (BOOL)canEditRow:(NSUInteger)row;

- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRow:(NSUInteger)row;

@end

NS_ASSUME_NONNULL_END
