/*****************************************************************************
 * VLCCloudStorageTableViewCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors:  Carola Nitz <nitz.carola # googlemail.com>
 *        Felix Paul Kühne <fkuehne # videolan.org>
 *        Eshan Singh <eeeshan789 # gmail.com>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageTableViewCell.h"
#import "VLCNetworkImageView.h"

#import "VLC-Swift.h"

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
    
    cell.isFavourite = NO;
    cell.isFavourable = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:cell selector:@selector(updateAppearanceForColorScheme) name:kVLCThemeDidChangeNotification object:nil];
    [cell updateAppearanceForColorScheme];

    return cell;
}

- (IBAction)didTapFavorite:(id)sender
{
    self.isFavourite = !self.isFavourite;
   [self.delegate triggerFavoriteForCell: self];
    
}

- (void)setDropboxFile:(DBFILESMetadata *)dropboxFile
{
    if (dropboxFile != _dropboxFile)
        _dropboxFile = dropboxFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)setDriveFile:(GTLRDrive_File *)driveFile
{
    if (driveFile != _driveFile)
        _driveFile = driveFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)setBoxFile:(BoxItem *)boxFile
{
    if (boxFile != _boxFile)
        _boxFile = boxFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)setPcloudFile:(VLCPCloudCellContentWrapper *)pcloudFile {
    if (pcloudFile != _pcloudFile)
        _pcloudFile = pcloudFile;

    [self performSelectorOnMainThread:@selector(_updatedDisplayedInformation)
                           withObject:nil waitUntilDone:NO];
}

- (void)updateOneDriveDisplayAsFolder
{
    _downloadButton.hidden = YES;
    _folderTitleLabel.text = _oneDriveFile.name;
    _titleLabel.hidden = _subtitleLabel.hidden = YES;
    _folderTitleLabel.hidden = NO;
    _thumbnailView.image = [UIImage imageNamed:@"folder"];
}

- (void)loadThumbnail
{
    // The onedrive Api has no way to cancel a request and the ODThumbnail has no back reference to it's item
    // so this might lead to wrong thumbnails if the cell is reused since we have no way of cancelling requests or check if the completion is still for the set item
    ODDriveRequestBuilder *drive = [[ODClient loadCurrentClient] drive];
    ODThumbnailRequest *request = [[[[drive items:_oneDriveFile.id] thumbnails:@"0"] medium] request];
    __weak typeof(self) weakSelf = self;
    [request getWithCompletion:^(ODThumbnail *response, NSError *error) {
        if (error == nil && response.url) {// we don't care about errors for thumbnails
            dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf.thumbnailView setImageWithURL:[NSURL URLWithString:response.url]];
            });
        }
    }];
}

- (void)updateOneDriveDisplayAsItem
{
    int64_t duration = 0;
    NSString *title = self.oneDriveFile.name;
    NSMutableString *subtitle = [[NSMutableString alloc] init];

    _downloadButton.hidden = NO;
    _titleLabel.text = title;

    if (_oneDriveFile.audio) {
        _thumbnailView.image = [UIImage imageNamed:@"audioFile"];
        duration = _oneDriveFile.audio.duration;
        [self loadThumbnail];
    } else if (_oneDriveFile.video) {
        _thumbnailView.image = [UIImage imageNamed:@"movie"];
        duration = _oneDriveFile.video.duration;
        [self loadThumbnail];
    } else {
        _thumbnailView.image = [UIImage imageNamed:@"blank"];
    }

    if (duration > 0) {
        VLCTime *time = [VLCTime timeWithNumber:[NSNumber numberWithLongLong:duration]];
        [subtitle appendString:[time verboseStringValue]];
    }

    if (_oneDriveFile.size > 0) {
        subtitle = [NSMutableString stringWithString:[NSByteCountFormatter
                                                      stringFromByteCount:_oneDriveFile.size
                                                      countStyle:NSByteCountFormatterCountStyleFile]];
        if (duration > 0) {
            VLCTime *time = [VLCTime timeWithNumber:[NSNumber numberWithLongLong:duration]];
            [subtitle appendFormat:@" — %@", [time verboseStringValue]];
        }
    }

    _subtitleLabel.text = subtitle;
    _titleLabel.hidden = _subtitleLabel.hidden = NO;
    _folderTitleLabel.hidden = YES;
}

- (void)updateOneDriveDisplayedInformation
{
    _oneDriveFile.folder ? [self updateOneDriveDisplayAsFolder] : [self updateOneDriveDisplayAsItem];
}

- (void)setOneDriveFile:(ODItem *)oneDriveFile
{
    if (oneDriveFile != _oneDriveFile) {
        _oneDriveFile = oneDriveFile;
        [self updateOneDriveDisplayedInformation];
    }
}

- (void)_updatedDisplayedInformation
{
    if (_dropboxFile != nil) {
        if ([_dropboxFile isKindOfClass:[DBFILESFolderMetadata class]]) {
            self.folderTitleLabel.text = self.dropboxFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
            self.downloadButton.hidden = NO;
            self.isFavourable = YES;
        
            VLCFavoriteService *service =  [VLCAppCoordinator sharedInstance].favoriteService;
            
            NSString *selectedFilePath = _dropboxFile.pathLower;
            NSString *urlString = [NSString stringWithFormat:@"file://DropBox/%@", selectedFilePath];
            NSURL *url = [NSURL URLWithString:urlString];
            self.isFavourite = [service isFavoriteURL:url];
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
        } else if ([_dropboxFile isKindOfClass:[DBFILESFileMetadata class]]) {
            DBFILESFileMetadata *file = (DBFILESFileMetadata *)_dropboxFile;
            self.titleLabel.text = file.name;
            self.subtitleLabel.text = (file.size.integerValue > 0) ? [NSByteCountFormatter stringFromByteCount:file.size.longLongValue countStyle:NSByteCountFormatterCountStyleFile] : @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
            self.downloadButton.hidden = NO;
            self.isFavourable = NO;
            self.favouriteButton.hidden = YES;
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
        }
    }
    else if(_driveFile != nil) {
        BOOL isDirectory = [self.driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        if (isDirectory) {
            self.folderTitleLabel.text = self.driveFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
            self.isFavourable = YES;
            
            VLCFavoriteService *service =  [VLCAppCoordinator sharedInstance].favoriteService;
            
            NSString *selectedFilePath = _driveFile.identifier;
            NSString *urlString = [NSString stringWithFormat:@"file://Drive/%@", selectedFilePath];
            NSURL *url = [NSURL URLWithString:urlString];
            
            self.isFavourite = [service isFavoriteURL:url];
        } else {
            NSString *title = self.driveFile.name;
            self.titleLabel.text = title;
            self.subtitleLabel.text = (self.driveFile.size > 0) ? [NSByteCountFormatter stringFromByteCount:[self.driveFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
            self.favouriteButton.hidden = YES;
            
            if (_driveFile.thumbnailLink != nil) {
                [self.thumbnailView setImageWithURL:[NSURL URLWithString:_driveFile.thumbnailLink]];
            }
        }

        if (!self.thumbnailView.image) {
            NSString *iconName = self.driveFile.iconLink;
            if (isDirectory) {
                self.thumbnailView.image = [UIImage imageNamed:@"folder"];
            } else if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_10_audio_list.png"]) {
                self.thumbnailView.image = [UIImage imageNamed:@"audioFile"];
            } else if ([iconName isEqualToString:@"https://ssl.gstatic.com/docs/doclist/images/icon_11_video_list.png"]) {
                self.thumbnailView.image = [UIImage imageNamed:@"movie"];
            } else {
                self.thumbnailView.image = [UIImage imageNamed:@"blank"];
                APLog(@"missing icon for type '%@'", self.driveFile.iconLink);
            }
        }
    }
    else if(_boxFile != nil) {
        BOOL isDirectory = [self.boxFile.type isEqualToString:@"folder"];
        if (isDirectory) {
            self.folderTitleLabel.text = self.boxFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
            self.downloadButton.hidden = NO;
            self.isFavourable = YES;
            
            VLCFavoriteService *service =  [VLCAppCoordinator sharedInstance].favoriteService;
            NSString *selectedFilePath = _boxFile.modelID;
            NSString *urlString = [NSString stringWithFormat:@"file://Box/%@", selectedFilePath];
            NSURL *url = [NSURL URLWithString:urlString];
            
            self.isFavourite = [service isFavoriteURL:url];
        } else {
            NSString *title = self.boxFile.name;
            self.titleLabel.text = title;
            self.subtitleLabel.text = (self.boxFile.size > 0) ? [NSByteCountFormatter stringFromByteCount:[self.boxFile.size longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
            self.downloadButton.hidden = NO;
            self.favouriteButton.hidden = YES;
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
        [self updateOneDriveDisplayedInformation];
    } else if(_pcloudFile != nil) {
        BOOL isDirectory = self.pcloudFile.isDirectory;

        if (isDirectory) {
            self.folderTitleLabel.text = self.pcloudFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
            self.downloadButton.hidden = YES;
            self.isFavourable = YES;

            VLCFavoriteService *service =  [VLCAppCoordinator sharedInstance].favoriteService;
            NSNumber *folderIDNumber = _pcloudFile.folderID;
            NSString *selectedFilePath = [folderIDNumber stringValue];
            NSString *urlString = [NSString stringWithFormat:@"file://PCloud/%@", selectedFilePath];
            NSURL *url = [NSURL URLWithString:urlString];
            self.isFavourite = [service isFavoriteURL:url];
        } else {
            self.titleLabel.text = self.pcloudFile.name;
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.subtitleLabel.text = (self.pcloudFile.fileSize > 0) ? [NSByteCountFormatter stringFromByteCount:[self.pcloudFile.fileSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.folderTitleLabel.hidden = YES;
            self.downloadButton.hidden = NO;
        }

        if (isDirectory) {
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
        } else {
            // TO DO : FETCH THUMBNAIL
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
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
    return 8. * 4. + [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] lineHeight] + [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2] lineHeight];
}

- (void)setIsDownloadable:(BOOL)isDownloadable
{
    self.downloadButton.hidden = !isDownloadable;
}

- (void)setIsFavourite:(BOOL)isFavourite
{
    if (@available(iOS 13.0, *)) {
        _favouriteButton.hidden = !isFavourite;
        if (isFavourite) {
            [_favouriteButton setImage:[UIImage imageNamed:@"heart.fill"] forState:UIControlStateNormal];
        }
    } else {
        _favouriteButton.hidden = NO;
        if (isFavourite) {
            [_favouriteButton setImage:[UIImage imageNamed:@"heart"] forState:UIControlStateNormal];
        } else {
            [_favouriteButton setImage:[UIImage imageNamed:@"heart.fill"] forState:UIControlStateNormal];
        }
    }
       
    _isFavourite = isFavourite;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _thumbnailView.image = nil;
}

- (void)updateAppearanceForColorScheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.backgroundColor = colors.cellBackgroundA;
    self.titleLabel.textColor = colors.cellTextColor;
    self.folderTitleLabel.textColor = colors.cellTextColor;
    self.subtitleLabel.textColor = colors.cellDetailTextColor;
}

@end
