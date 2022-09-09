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
#import "VLC-Swift.h"

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
                               NSLocalizedString(@"NFS_SHORT", nil),
                               NSLocalizedString(@"SFTP_SHORT", nil)
                               ]];
        _segmentedControl.tintColor = PresentationTheme.current.colors.orangeUI;

        UIFont *segmentedControlFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        if (@available(iOS 13.0, *)) {
            [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                                                PresentationTheme.current.colors.cellDetailTextColor,
                                                            NSFontAttributeName: segmentedControlFont
                                                          }
                                                 forState:UIControlStateNormal];

            // Always use black since the background is always white.
            [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                                                UIColor.blackColor,
                                                            NSFontAttributeName: segmentedControlFont
                                                          }
                                                 forState:UIControlStateSelected];
        } else {
            [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName: segmentedControlFont} forState:UIControlStateNormal];
        }
        [self.contentView addSubview:_segmentedControl];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
        [self themeDidChange];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.segmentedControl.frame = CGRectInset(self.contentView.bounds, 0, 5);
}

- (void)themeDidChange
{
    self.backgroundColor = PresentationTheme.current.colors.background;
}

@end
