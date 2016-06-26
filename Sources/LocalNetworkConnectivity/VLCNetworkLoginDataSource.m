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

#import "VLCNetworkLoginDataSource.h"

@implementation VLCNetworkLoginDataSource

- (void)configureWithTableView:(UITableView *)tableView
{
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.dataSources enumerateObjectsUsingBlock:^(id<VLCNetworkLoginDataSourceSection>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj configureWithTableView:tableView];
    }];
}
- (void)setDataSources:(NSArray<id<VLCNetworkLoginDataSourceSection>> *)dataSources
{
    _dataSources = [dataSources copy];
    [dataSources enumerateObjectsUsingBlock:^(id<VLCNetworkLoginDataSourceSection>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.sectionIndex = idx;
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSources.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSources[section] numberOfRowsInTableView:tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCNetworkLoginDataSourceSection> dataSource = self.dataSources[indexPath.section];
    NSUInteger row = indexPath.row;
    NSString *cellIdentifier = [dataSource cellIdentifierForRow:row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [dataSource configureCell:cell forRow:row];
    return cell;
}

#pragma mark - UITableViewDelegate

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL editable = YES;
    id<VLCNetworkLoginDataSourceSection> dataSource = self.dataSources[indexPath.section];
    if ([dataSource respondsToSelector:@selector(canEditRow:)]) {
        editable = [dataSource canEditRow:indexPath.row];
    }
    return editable;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCNetworkLoginDataSourceSection> dataSource = self.dataSources[indexPath.section];
    if ([dataSource respondsToSelector:@selector(commitEditingStyle:forRow:)]) {
        [dataSource commitEditingStyle:editingStyle forRow:indexPath.row];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *targetIndexPath = indexPath;
    id<VLCNetworkLoginDataSourceSection> dataSource = self.dataSources[indexPath.section];
    if ([dataSource respondsToSelector:@selector(willSelectRow:)]) {
        NSUInteger targetRow = [dataSource willSelectRow:indexPath.row];
        if (targetRow == NSNotFound) {
            targetIndexPath = nil;
        } else if (targetRow != indexPath.row) {
            targetIndexPath = [NSIndexPath indexPathForRow:targetRow inSection:indexPath.section];
        }
    } else if (![dataSource respondsToSelector:@selector(didSelectRow:)]) {
        targetIndexPath = nil;
    }

    return targetIndexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCNetworkLoginDataSourceSection> dataSource = self.dataSources[indexPath.section];
    if ([dataSource respondsToSelector:@selector(didSelectRow:)]) {
        [dataSource didSelectRow:indexPath.row];
    }
}

@end
