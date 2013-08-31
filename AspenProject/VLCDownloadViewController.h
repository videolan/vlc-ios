//
//  VLCDownloadViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 16.06.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

@interface VLCDownloadViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet UITextField *urlField;
@property (nonatomic, strong) IBOutlet UILabel *whatToDownloadHelpLabel;
@property (nonatomic, strong) IBOutlet UITableView *downloadsTable;

@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UILabel *currentDownloadLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)downloadAction:(id)sender;
- (IBAction)cancelDownload:(id)sender;

- (void)addURLToDownloadList:(NSURL *)aURL;
@end
