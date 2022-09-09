/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageTVViewController.h"

@interface VLCCloudStorageTVViewController ()

@end

@implementation VLCCloudStorageTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_activityIndicator];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];

    [self.collectionView reloadData];
}

- (void)updateViewAfterSessionChange
{
    if (![self.controller isAuthorized]) {
        [_activityIndicator stopAnimating];
        return;
    }

    //reload if we didn't come back from streaming
    if (self.currentPath == nil)
        self.currentPath = @"";

    if([self.controller.currentListFiles count] == 0)
        [self requestInformationForCurrentPath];
}

- (void)requestInformationForCurrentPath
{
    [_activityIndicator startAnimating];
    [self.controller requestDirectoryListingAtPath:self.currentPath];
    [_activityIndicator stopAnimating];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.controller.currentListFiles.count;
}

@end
