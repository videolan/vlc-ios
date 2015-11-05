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
#if TARGET_OS_TV
#import "MetaDataFetcherKit.h"
#endif

#if TARGET_OS_TV
@interface VLCCloudStorageTableViewCell () <MDFMovieDBFetcherDataRecipient>
{
    MDFMovieDBFetcher *_metadataFetcher;
}
@end
#endif

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

#if TARGET_OS_TV
    [cell prepareForReuse];
#endif

    return cell;
}

#if TARGET_OS_TV
- (void)prepareForReuse
{
    if (_metadataFetcher) {
        [_metadataFetcher cancelAllRequests];
    } else {
        _metadataFetcher = [[MDFMovieDBFetcher alloc] init];
        _metadataFetcher.dataRecipient = self;
        _metadataFetcher.shouldDecrapifyInputStrings = YES;
    }
}
#endif

- (void)setDropboxFile:(DBMetadata *)dropboxFile
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
        if (self.dropboxFile.isDirectory) {
            self.folderTitleLabel.text = self.dropboxFile.filename;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
        } else {
            NSString *title = self.dropboxFile.filename;
            self.titleLabel.text = title;
#if TARGET_OS_TV
            [_metadataFetcher searchForMovie:title];
#endif
            self.subtitleLabel.text = (self.dropboxFile.totalBytes > 0) ? self.dropboxFile.humanReadableSize : @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;
        }

        NSString *iconName = self.dropboxFile.icon;
        if ([iconName isEqualToString:@"folder_user"] || [iconName isEqualToString:@"folder"] || [iconName isEqualToString:@"folder_public"] || [iconName isEqualToString:@"folder_photos"] || [iconName isEqualToString:@"package"]) {
            self.thumbnailView.image = [UIImage imageNamed:@"folder"];
            self.downloadButton.hidden = YES;
        } else if ([iconName isEqualToString:@"page_white"] || [iconName isEqualToString:@"page_white_text"])
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
        else if ([iconName isEqualToString:@"page_white_film"])
            self.thumbnailView.image = [UIImage imageNamed:@"movie"];
        else if ([iconName isEqualToString:@"page_white_sound"])
            self.thumbnailView.image = [UIImage imageNamed:@"audio"];
        else {
            self.thumbnailView.image = [UIImage imageNamed:@"blank"];
            APLog(@"missing icon for type '%@'", self.dropboxFile.icon);
        }
    }
#if TARGET_OS_IOS
    else if(_driveFile != nil){
        BOOL isDirectory = [self.driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        if (isDirectory) {
            self.folderTitleLabel.text = self.driveFile.title;
            self.titleLabel.hidden = self.subtitleLabel.hidden = YES;
            self.folderTitleLabel.hidden = NO;
        } else {
            NSString *title = self.driveFile.title;
            self.titleLabel.text = title;
            self.subtitleLabel.text = (self.driveFile.fileSize > 0) ? [NSByteCountFormatter stringFromByteCount:[self.driveFile.fileSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile]: @"";
            self.titleLabel.hidden = self.subtitleLabel.hidden = NO;
            self.folderTitleLabel.hidden = YES;

            if (_driveFile.thumbnailLink != nil) {
                [self.thumbnailView setImageWithURL:[NSURL URLWithString:_driveFile.thumbnailLink]];
            }
#if TARGET_OS_TV
            else {
                [_metadataFetcher searchForMovie:title];
            }
#endif
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
#if TARGET_OS_TV
            [_metadataFetcher searchForMovie:title];
#endif
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
                if (thumbnailURLString) {
                    [self.thumbnailView setImageWithURL:[NSURL URLWithString:thumbnailURLString]];
                }
#if TARGET_OS_TV
                else {
                    [_metadataFetcher searchForMovie:title];
                }
#endif
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

#if TARGET_OS_TV
- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindMovie:(MDFMovie *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil)
        return;
    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties)
        return;

    if (details.movieDBID == 0) {
        /* we found nothing, let's see if it's a TV show */
        [_metadataFetcher searchForTVShow:searchRequest];
        return;
    }

    NSString *imagePath = details.posterPath;
    if (!imagePath)
        imagePath = details.backdropPath;
    if (!imagePath)
        return;

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    sessionManager.posterSizes.firstObject,
                                    details.posterPath];
    [self.thumbnailView setImageWithURL:[NSURL URLWithString:thumbnailURLString]];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindMovieForSearchRequest:(NSString *)searchRequest
{
    APLog(@"Failed to find a movie for '%@'", searchRequest);
}

-(void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFindTVShow:(MDFTVShow *)details forSearchRequest:(NSString *)searchRequest
{
    if (details == nil)
        return;
    [aFetcher cancelAllRequests];
    MDFMovieDBSessionManager *sessionManager = [MDFMovieDBSessionManager sharedInstance];
    if (!sessionManager.hasFetchedProperties)
        return;

    NSString *imagePath = details.posterPath;
    if (!imagePath)
        imagePath = details.backdropPath;
    if (!imagePath)
        return;

    NSString *thumbnailURLString = [NSString stringWithFormat:@"%@%@%@",
                                    sessionManager.imageBaseURL,
                                    sessionManager.posterSizes.firstObject,
                                    details.posterPath];
    [self.thumbnailView setImageWithURL:[NSURL URLWithString:thumbnailURLString]];
}

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher *)aFetcher didFailToFindTVShowForSearchRequest:(NSString *)searchRequest
{
    APLog(@"failed to find TV show");
}
#endif

@end
