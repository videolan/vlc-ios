/*****************************************************************************
 * VLCDownloadViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCDownloadViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *downloadFieldContainer;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet UITextField *urlField;
@property (weak, nonatomic) IBOutlet UIView *urlBorder;
@property (nonatomic, strong) IBOutlet UITableView *downloadsTable;

@property (nonatomic, strong) IBOutlet UIView *progressContainer;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UILabel *currentDownloadLabel;
@property (nonatomic, strong) IBOutlet UILabel *progressPercent;
@property (nonatomic, strong) IBOutlet UILabel *speedRate;
@property (nonatomic, strong) IBOutlet UILabel *timeDL;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)downloadAction:(id)sender;
- (IBAction)cancelDownload:(id)sender;

@property (nonatomic, readonly, copy) NSString *detailText;
@property (nonatomic, readonly) UIImage *cellImage;

@end
