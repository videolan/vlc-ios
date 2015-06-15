/*****************************************************************************
 * VLCDownloadViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
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

+ (instancetype)sharedInstance;

@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet UITextField *urlField;
@property (nonatomic, strong) IBOutlet UILabel *whatToDownloadHelpLabel;
@property (nonatomic, strong) IBOutlet UITableView *downloadsTable;

@property (nonatomic, strong) IBOutlet UIView *progressContainer;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UILabel *currentDownloadLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel *progressPercent;
@property (nonatomic, strong) IBOutlet UILabel *speedRate;
@property (nonatomic, strong) IBOutlet UILabel *timeDL;

- (IBAction)downloadAction:(id)sender;
- (IBAction)cancelDownload:(id)sender;

- (void)addURLToDownloadList:(NSURL *)aURL fileNameOfMedia:(NSString*) fileName;;
@end
