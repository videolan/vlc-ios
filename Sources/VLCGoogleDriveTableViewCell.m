/*****************************************************************************
 * VLCGoogleDriveTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCGoogleDriveTableViewCell.h"

@implementation VLCGoogleDriveTableViewCell

+ (VLCGoogleDriveTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCGoogleDriveTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCGoogleDriveTableViewCell class]], @"meh meh");
    VLCGoogleDriveTableViewCell *cell = (VLCGoogleDriveTableViewCell *)[nibContentArray lastObject];

    return cell;
}

- (void)setDriveFile:(GTLDriveFile *)driveFile
{
    if (driveFile != _driveFile)
        _driveFile = driveFile;

    [self _updatedDisplayedInformation];
}

- (void)_updatedDisplayedInformation
{
    BOOL isDirectory = [self.driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
    if (isDirectory) {
        self.folderTitleLabel.text = self.driveFile.title;
        self.titleLabel.text = @"";
        self.subtitleLabel.text = @"";
    } else {
        self.titleLabel.text = self.driveFile.title;
        self.subtitleLabel.text = (self.driveFile.fileSize > 0) ? [NSByteCountFormatter stringFromByteCount:[self.driveFile.fileSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
        self.folderTitleLabel.text = @"";
    }

    NSString *iconName = self.driveFile.iconLink;
    if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_shared_collection_list.png"] || [iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_collection_list.png"]) {
        self.thumbnailView.image = [UIImage imageNamed:@"folder"];
    } else if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_10_audio_list.png"]) {
        self.thumbnailView.image = [UIImage imageNamed:@"blank"];
    } else if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_video_list.png"]) {
        self.thumbnailView.image = [UIImage imageNamed:@"movie"];
    } else {
        self.thumbnailView.image = [UIImage imageNamed:@"blank"];
        APLog(@"missing icon for type '%@'", self.driveFile.iconLink);
    }
    [self setNeedsDisplay];
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 48.;
}

@end
