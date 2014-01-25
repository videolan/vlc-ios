/*****************************************************************************
 * VLCCloudStorageTableViewCell.m
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

#import "VLCCloudStorageTableViewCell.h"
@interface VLCCloudStorageTableViewCell ()
{
    NSURL *_iconURL;
}
@end

@implementation VLCCloudStorageTableViewCell

+ (VLCCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCCloudStorageTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCCloudStorageTableViewCell class]], @"meh meh");
    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[nibContentArray lastObject];

    return cell;
}

- (void)setFileMetadata:(DBMetadata *)fileMetadata
{
    if (fileMetadata != _fileMetadata)
        _fileMetadata = fileMetadata;

    [self _updatedDisplayedInformation];
}

- (void)setDriveFile:(GTLDriveFile *)driveFile
{
    if (driveFile != _driveFile)
        _driveFile = driveFile;

    [self _updatedDisplayedInformation];
}

- (void)_updatedDisplayedInformation
{
    if (_fileMetadata != nil) {
        if (self.fileMetadata.isDirectory) {
            self.folderTitleLabel.text = self.fileMetadata.filename;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
        } else {
            self.titleLabel.text = self.fileMetadata.filename;
            self.subtitleLabel.text = (self.fileMetadata.totalBytes > 0) ? self.fileMetadata.humanReadableSize : @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
        }

        NSString *iconName = self.fileMetadata.icon;
        if ([iconName isEqualToString:@"folder_user"] || [iconName isEqualToString:@"folder"] || [iconName isEqualToString:@"folder_public"] || [iconName isEqualToString:@"folder_photos"] || [iconName isEqualToString:@"package"]) {
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
            self.downloadButton.hidden = YES;
        } else if ([iconName isEqualToString:@"page_white"] || [iconName isEqualToString:@"page_white_text"])
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
        else if ([iconName isEqualToString:@"page_white_film"])
            self.thumbnailView.image = [UIImage imageNamed:@"movie"];
        else if ([iconName isEqualToString:@"page_white_sound"])
            self.thumbnailView.image = [UIImage imageNamed:@"audio"];
        else
            APLog(@"missing icon for type '%@'", self.fileMetadata.icon);

    } else if(_driveFile != nil){
        BOOL isDirectory = [self.driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        if (isDirectory) {
            self.folderTitleLabel.text = self.driveFile.title;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
        } else {
            self.titleLabel.text = self.driveFile.title;
            self.subtitleLabel.text = (self.driveFile.fileSize > 0) ? [NSByteCountFormatter stringFromByteCount:[self.driveFile.fileSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
        }
        if (_driveFile.thumbnailLink != nil) {
            _iconURL = [NSURL URLWithString:_driveFile.thumbnailLink];
            [self performSelectorInBackground:@selector(_updateIconFromURL) withObject:@""];
        }
        NSString *iconName = self.driveFile.iconLink;
        if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_shared_collection_list.png"] || [iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_collection_list.png"]) {
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
        } else if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_10_audio_list.png"]) {
            self.thumbnailView.image = [UIImage imageNamed:@"audio"];
        } else if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_video_list.png"]) {
            self.thumbnailView.image = [UIImage imageNamed:@"movie"];
        } else {
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
            APLog(@"missing icon for type '%@'", self.driveFile.iconLink);
        }
    }
    self.downloadButton.hidden = NO;
    [self setNeedsDisplay];
}

- (void)_updateIconFromURL
{
    NSData* imageData = [[NSData alloc]initWithContentsOfURL:_iconURL];
    UIImage* image = [[UIImage alloc] initWithData:imageData];
    self.thumbnailView.image = image;
}

- (IBAction)triggerDownload:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(triggerDownloadForCell:)])
        [self.delegate triggerDownloadForCell:self];
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 48.;
}

@end
