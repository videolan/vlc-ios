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


#import "VLCNetworkLoginDataSourceProtocol.h"

static NSString *const VLCNetworkLoginDataSourceProtocolCellIdentifier = @"VLCNetworkLoginDataSourceProtocolCell";

@interface  VLCNetworkLoginDataSourceProtocolCell : UITableViewCell
@property (nonatomic) UISegmentedControl *segmentedControl;
@end

@interface VLCNetworkLoginDataSourceProtocol ()
@property (nonatomic, weak) UITableView *tableView;
@end

@implementation VLCNetworkLoginDataSourceProtocol
@synthesize sectionIndex;
- (void)segmentedControlChanged:(UISegmentedControl *)control
{
    NSInteger selectedIndex = control.selectedSegmentIndex;
    if (selectedIndex < 0 || VLCServerProtocolUndefined < selectedIndex) {
        selectedIndex = VLCServerProtocolUndefined;
    }
    self.protocol = (VLCServerProtocol)selectedIndex;
    [self.delegate protocolDidChange:self];
}

- (void)setProtocol:(VLCServerProtocol)protocol
{
    if (_protocol != protocol) {
        _protocol = protocol;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.sectionIndex]];
        [self configureCell:cell forRow:0];
    }
}

#pragma mark - VLCNetworkLoginDataSourceSection
- (void)configureWithTableView:(UITableView *)tableView
{
    [tableView registerClass:[VLCNetworkLoginDataSourceProtocolCell class] forCellReuseIdentifier:VLCNetworkLoginDataSourceProtocolCellIdentifier];
    self.tableView = tableView;
}

- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    return VLCNetworkLoginDataSourceProtocolCellIdentifier;
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    NSInteger segmentIndex = self.protocol;
    if (segmentIndex == VLCServerProtocolUndefined) {
        segmentIndex = -1;
    }
    VLCNetworkLoginDataSourceProtocolCell *protocolCell = [cell isKindOfClass:[VLCNetworkLoginDataSourceProtocolCell class]] ? (id)cell : nil;
    protocolCell.segmentedControl.selectedSegmentIndex = segmentIndex;
    if (![[protocolCell.segmentedControl allTargets] containsObject:self]) {
        [protocolCell.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

@end


@implementation VLCNetworkLoginDataSourceProtocolCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil),
                               NSLocalizedString(@"FTP_SHORT", nil),
                               NSLocalizedString(@"PLEX_SHORT", nil),
                               ]];
        _segmentedControl.tintColor = [UIColor VLCLightTextColor];
        [self.contentView addSubview:_segmentedControl];
        self.backgroundColor = [UIColor VLCDarkBackgroundColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.segmentedControl.frame = CGRectInset(self.contentView.bounds, 20, 5);
}

@end
