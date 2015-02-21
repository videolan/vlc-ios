/*****************************************************************************
 * VLCPlexMediaInformationViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCPlexMediaInformationViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIImageView *thumb;
@property (nonatomic, strong) IBOutlet UILabel *mediaTitle;
@property (nonatomic, strong) IBOutlet UILabel *codec;
@property (nonatomic, strong) IBOutlet UILabel *size;
@property (nonatomic, strong) IBOutlet UITextView *summary;
@property (nonatomic, strong) IBOutlet UIImageView *badgeUnread;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *markMediaButton;

- (IBAction)play:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)markMedia:(id)sender;

- (id)initPlexMediaInformation:(NSMutableArray *)mediaInformation serverAddress:(NSString *)serverAddress portNumber:(NSString *)portNumber atPath:(NSString *)path;

@end
