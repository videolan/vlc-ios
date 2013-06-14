//
//  VLCDropboxTableViewCell.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 24.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCDropboxTableViewCell.h"

@implementation VLCDropboxTableViewCell

+ (VLCDropboxTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCDropboxTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCDropboxTableViewCell class]], @"meh meh");
    VLCDropboxTableViewCell *cell = (VLCDropboxTableViewCell *)[nibContentArray lastObject];

    return cell;
}

- (void)setFileMetadata:(DBMetadata *)fileMetadata
{
    if (fileMetadata != _fileMetadata)
        _fileMetadata = fileMetadata;

    [self _updatedDisplayedInformation];
}

- (void)_updatedDisplayedInformation
{
    if (self.fileMetadata.isDirectory) {
        self.folderTitleLabel.text = self.fileMetadata.filename;
        self.titleLabel.text = @"";
        self.subtitleLabel.text = @"";
    } else {
        self.titleLabel.text = self.fileMetadata.filename;
        self.subtitleLabel.text = (self.fileMetadata.totalBytes > 0) ? self.fileMetadata.humanReadableSize : @"";
        self.folderTitleLabel.text = @"";
    }

    NSString *iconName = self.fileMetadata.icon;
    if ([iconName isEqualToString:@"folder_user"] || [iconName isEqualToString:@"folder"] || [iconName isEqualToString:@"folder_public"] || [iconName isEqualToString:@"folder_photos"] || [iconName isEqualToString:@"package"])
        self.thumbnailView.image = [UIImage imageNamed:@"folder"];
    else if ([iconName isEqualToString:@"page_white"] || [iconName isEqualToString:@"page_white_text"])
        self.thumbnailView.image = [UIImage imageNamed:@"blank"];
    else if ([iconName isEqualToString:@"page_white_film"])
        self.thumbnailView.image = [UIImage imageNamed:@"movie"];
    else
        APLog(@"missing icon for type '%@'", self.fileMetadata.icon);

    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 48.;
}

@end
