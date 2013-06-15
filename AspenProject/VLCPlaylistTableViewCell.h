//
//  VLCPlaylistTableViewCell.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 01.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <Foundation/Foundation.h>
#import "VLCLinearProgressIndicator.h"

@interface VLCPlaylistTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet VLCLinearProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *mediaIsUnreadView;

@property (nonatomic, retain) MLFile *mediaObject;

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

@end
