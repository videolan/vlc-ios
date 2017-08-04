/*****************************************************************************
 * VLCCloudStorageTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageTableViewCell.h"
#import "VLCNetworkImageView.h"

@implementation VLCCloudStorageTableViewCell

+ (VLCCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCCloudStorageTableViewCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCCloudStorageTableViewCell class]], @"meh meh");
    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[nibContentArray lastObject];

    cell.titleLabel.hidden = YES;
    cell.subtitleLabel.hidden = YES;
    cell.folderTitleLabel.hidden = YES;

    return cell;
}

- (void)setDropboxFile:(DBFILESMetadata *)dropboxFile
{
    if (dropboxFile != _dropboxFile)
        _dropboxFile = dropboxFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

#if TARGET_OS_IOS
- (void)setDriveFile:(GTLDriveFile *)driveFile
{
    if (driveFile != _driveFile)
        _driveFile = driveFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}
#endif

- (void)setBoxFile:(BoxItem *)boxFile
{
    if (boxFile != _boxFile)
        _boxFile = boxFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)setOneDriveFile:(VLCOneDriveObject *)oneDriveFile
{
    if (oneDriveFile != _oneDriveFile)
        _oneDriveFile = oneDriveFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)_updatedDisplayedInformation
{
    if (_dropboxFile != nil) {
        if ([_dropboxFile isKindOfClass:[DBFILESFolderMetadata class]]) {
            self.folderTitleLabel.text = self.dropboxFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
            self.downloadButton.hidden = YES;
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
        } else if ([_dropboxFile isKindOfClass:[DBFILESFileMetadata class]]) {
            DBFILESFileMetadata *file = (DBFILESFileMetadata *)_dropboxFile;
            self.titleLabel.text = file.name;
            self.subtitleLabel.text = (file.size.integerValue > 0) ? [NSByteCountFormatter stringFromByteCount:file.size.longLongValue countStyle:NSByteCountFormatterCountStyleFile] : @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
            self.downloadButton.hidden = NO;
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
        }
    }
#if TARGET_OS_IOS
    else if(_driveFile != nil){
        BOOL isDirectory = [self.driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        if (isDirectory) {
            self.folderTitleLabel.text = self.driveFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
        } else {
            NSString *title = self.driveFile.name;
            self.titleLabel.text = title;
            self.subtitleLabel.text = (self.driveFile.size > 0) ? [NSByteCountFormatter stringFromByteCount:[self.driveFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;

            if (_driveFile.thumbnailLink != nil) {
                [self.thumbnailView setImageWithURL:[NSURL URLWithString:_driveFile.thumbnailLink]];
            }
        }
        NSString *iconName = self.driveFile.iconLink;
        if (isDirectory) {
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
#endif
    else if(_boxFile != nil) {
        BOOL isDirectory = [self.boxFile.type isEqualToString:@"folder"];
        if (isDirectory) {
            self.folderTitleLabel.text = self.boxFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
        } else {
            NSString *title = self.boxFile.name;
            self.titleLabel.text = title;
            self.subtitleLabel.text = (self.boxFile.size > 0) ? [NSByteCountFormatter stringFromByteCount:[self.boxFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
            self.downloadButton.hidden = NO;
        }
        //TODO: correct thumbnails
//        if (_boxFile.modelID != nil) {
//            //this request needs a token in the header to work
//            NSString *thumbnailURLString = [NSString stringWithFormat:@"https://api.box.com/2.0/files/%@/thumbnail.png?min_height=32&min_width=32&max_height=64&max_width=64", _boxFile.modelID];
//            [self.thumbnailView setImageWithURL:[NSURL URLWithString:thumbnailURLString]];
//        }
        //TODO:correct icons
        if (isDirectory) {
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
        } else {
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
            APLog(@"missing icon for type '%@'", self.boxFile);
        }
    } else if(_oneDriveFile != nil) {
        if (_oneDriveFile.isFolder) {
            self.downloadButton.hidden = YES;
            self.folderTitleLabel.text = self.oneDriveFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
        } else {
            self.downloadButton.hidden = NO;
            NSString *title = self.oneDriveFile.name;
            self.titleLabel.text = title;
            NSMutableString *subtitle = [[NSMutableString alloc] init];

            if (self.oneDriveFile.isAudio)
                self.thumbnailView.image = [UIImage imageNamed:@"audio"];
            else if (self.oneDriveFile.isVideo) {
                self.thumbnailView.image = [UIImage imageNamed:@"movie"];
                NSString *thumbnailURLString = _oneDriveFile.thumbnailURL;
                if ([thumbnailURLString isKindOfClass:[NSString class]]) {
                    [self.thumbnailView setImageWithURL:[NSURL URLWithString:thumbnailURLString]];
                }
            } else
                self.thumbnailView.image = [UIImage imageNamed:@"blank"];

            if (self.oneDriveFile.size > 0) {
                [subtitle appendString:[NSByteCountFormatter stringFromByteCount:[self.oneDriveFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]];
                if (self.oneDriveFile.duration > 0) {
                    VLCTime *time = [VLCTime timeWithNumber:self.oneDriveFile.duration];
                    [subtitle appendFormat:@" — %@", [time verboseStringValue]];
                }
            } else if (self.oneDriveFile.duration > 0) {
                VLCTime *time = [VLCTime timeWithNumber:self.oneDriveFile.duration];
                [subtitle appendString:[time verboseStringValue]];
            }
            self.subtitleLabel.text = subtitle;
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
        }
    }

    [self setNeedsDisplay];
}

- (IBAction)triggerDownload:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(triggerDownloadForCell:)])
        [self.delegate triggerDownloadForCell:self];
}

+ (CGFloat)heightOfCell
{
#if TARGET_OS_IOS
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 48.;
#else
    return 107.;
#endif
}

- (void)setIsDownloadable:(BOOL)isDownloadable
{
    self.downloadButton.hidden = !isDownloadable;
}

@end
