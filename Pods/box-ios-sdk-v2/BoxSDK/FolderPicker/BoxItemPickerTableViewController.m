//
//  BoxItemPickerTableViewController.m
//  BoxSDK
//
//  Created on 5/1/13.
//  Copyright (c) 2013 Box Inc. All rights reserved.
//

#define kCellHeight 58.0

#import <BoxSDK/BoxItemPickerTableViewController.h>
#import <BoxSDK/BoxSDK.h>
#import <BoxSDK/BoxOAuth2Session.h>
#import <BoxSDK/BoxItemPickerTableViewCell.h>
#import <BoxSDK/UIImage+BoxAdditions.h>
#import <BoxSDK/NSString+BoxAdditions.h>
#import <BoxSDK/BOXItem+BoxAdditions.h>

@implementation BoxItemPickerTableViewController

@synthesize itemPicker = _itemPicker;
@synthesize delegate = _delegate;
@synthesize helper = _helper;

- (id)initWithFolderPickerHelper:(BoxItemPickerHelper *)helper
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil)
    {
        _helper = helper;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // UI Setup
    self.tableView.alpha = 0.0;
    self.tableView.rowHeight = kCellHeight;
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
#if TARGET_OS_IOS
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
#endif

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 1.0)];
    tableHeaderView.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    self.tableView.tableHeaderView = tableHeaderView;
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.helper cancelThumbnailOperations];
    [super viewWillDisappear:animated];
}

#pragma mark - Data Management

- (void)refreshData
{
    [self.tableView reloadData];
    [UIView animateWithDuration:0.4 animations:^{
        self.tableView.alpha = 1.0;
    }];
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    NSUInteger count = [self.delegate currentNumberOfItems];
    NSUInteger total = [self.delegate totalNumberOfItems];
    
    // +1 for the "load more" cell at the bottom.
    return (count < total) ? count + 1 : count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BoxCell";
    static NSString *FooterIdentifier = @"BoxFooterCell";
    
    BOXItemPickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[BOXItemPickerTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
    }

    cell.helper = self.helper;
    
    if (indexPath.row < [self.delegate currentNumberOfItems])
    {
        BoxItem *item = [self.delegate itemAtIndex:indexPath.row];
        
        if (![self.delegate fileSelectionEnabled] && ![item isKindOfClass:[BoxFolder class]]) {
            cell.enabled = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else {
            cell.enabled = YES;
        }
        
        cell.cachePath = [self.delegate thumbnailPath];
        cell.showThumbnails = [self.delegate thumbnailsEnabled];     
        cell.item = item;
        
        cell.textLabel.text = item.name;
        NSString * desc = [NSString stringWithFormat:NSLocalizedString(@"%@ - Last update : %@", @"Title: File size and last modified timestamp (example: 5MB - Last Update : 2013-09-06 03:55)"), [NSString box_humanReadableStringForByteSize:item.size], [self.helper dateStringForItem:item]];        
        cell.detailTextLabel.text = desc;
        cell.imageView.image = [item icon];        
    }
    else 
    {
        UITableViewCell *footerCell = [tableView dequeueReusableCellWithIdentifier:FooterIdentifier];
        if (!footerCell) {
            footerCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FooterIdentifier];
            footerCell.textLabel.textColor = [UIColor colorWithRed:86.0f/255.0f green:86.0f/255.0f blue:86.0f/255.0f alpha:1.0];
        }
        footerCell.textLabel.text =  NSLocalizedString(@"Load more files ...", @"Title : Cell allowing the user to load the next page of items");
        footerCell.imageView.image = nil;
        footerCell.detailTextLabel.text = nil;
        
        return footerCell;
    }
    
    if (!cell.enabled) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.textLabel.textColor = [UIColor colorWithRed:86.0f/255.0f green:86.0f/255.0f blue:86.0f/255.0f alpha:1.0f];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:150.0f/255.0f green:150.0f/255.0f blue:150.0f/255.0f alpha:1.0f];
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOXItemPickerTableViewCell *cell = (BOXItemPickerTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    return (cell.enabled) ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.delegate currentNumberOfItems])
    {
        BoxItem *item = (BoxItem *)[self.delegate itemAtIndex:indexPath.row];
        
        if ([item isKindOfClass:[BoxFolder class]])
        {
            BoxItemPickerViewController *childFolderPicker = [[BoxItemPickerViewController alloc] initWithSDK:[self.delegate currentSDK]
                                                                                                     rootFolderID:item.modelID 
                                                                                            thumbnailsEnabled:[self.delegate thumbnailsEnabled] 
                                                                                         cachedThumbnailsPath:[self.delegate thumbnailPath] 
                                                                                         selectableObjectType:self.itemPicker.selectableObjectType];
            childFolderPicker.delegate = self.itemPicker.delegate;
            [self.navigationController pushViewController:childFolderPicker animated:YES];
        }
        else if ([item isKindOfClass:[BoxFile class]])
        {
            if ([self.delegate fileSelectionEnabled]) {
                [self.helper purgeInMemoryCache];
                
                id delegate = self.itemPicker.delegate;
                
                if ([delegate respondsToSelector:@selector(itemPickerController:didSelectBoxFile:)]) {
                    
                    BoxFile *file = (BoxFile *)item;
                    [delegate itemPickerController:self.itemPicker didSelectBoxFile:file];
                    
                }
                
            }
        }
    }
    else 
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell setSelected:NO animated:YES];
        [self.delegate loadNextSetOfItems];
    }
}

@end
