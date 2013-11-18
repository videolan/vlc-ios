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

@class VLCLinearProgressIndicator;
@interface VLCPlaylistTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet VLCLinearProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet UIView *mediaIsUnreadView;
@property (nonatomic, strong) IBOutlet UILabel *artistNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *albumNameLabel;

@property (nonatomic, strong) NSManagedObject *mediaObject;

+ (VLCPlaylistTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

@end
