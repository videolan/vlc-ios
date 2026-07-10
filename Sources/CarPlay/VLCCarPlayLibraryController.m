/*****************************************************************************
 * VLCCarPlayLibraryController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayLibraryController.h"
#import "VLCCarPlayArtistsController.h"
#import "VLCCarPlayAlbumsController.h"
#import "CPListTemplate+Genres.h"
#import "VLCCarPlayFoldersController.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation VLCCarPlayLibraryController
{
    VLCCarPlayArtistsController *_artistsController;
    VLCCarPlayAlbumsController *_albumsController;
    VLCCarPlayFoldersController *_foldersController;
}

- (CPGridTemplate *)libraryTemplate
{
    if (!_artistsController) {
        _artistsController = [[VLCCarPlayArtistsController alloc] init];
        _artistsController.interfaceController = self.interfaceController;
    }
    if (!_albumsController) {
        _albumsController = [[VLCCarPlayAlbumsController alloc] init];
        _albumsController.interfaceController = self.interfaceController;
    }
    if (!_foldersController) {
        _foldersController = [[VLCCarPlayFoldersController alloc] init];
        _foldersController.interfaceController = self.interfaceController;
    }

    NSArray<CPGridButton *> *buttons = @[
        [self buttonWithTitle:NSLocalizedString(@"ARTISTS", nil)
                        image:[self gridTileImageForSymbolNamed:@"music.mic"]
                     template:^{ return [self->_artistsController artistList]; }],
        [self buttonWithTitle:NSLocalizedString(@"ALBUMS", nil)
                        image:[self gridTileImageForSymbolNamed:@"square.stack"]
                     template:^{ return [self->_albumsController albumList]; }],
        [self buttonWithTitle:NSLocalizedString(@"GENRES", nil)
                        image:[self gridTileImageForSymbolNamed:@"tag"]
                     template:^{ return [CPListTemplate genreList]; }],
        [self buttonWithTitle:NSLocalizedString(@"FOLDERS", nil)
                        image:[self gridTileImageForSymbolNamed:@"folder"]
                     template:^{ return [self->_foldersController folderList]; }],
    ];

    CPGridTemplate *template = [[CPGridTemplate alloc] initWithTitle:NSLocalizedString(@"MEDIA_LIBRARY_LABEL", nil)
                                                         gridButtons:buttons];
    template.tabTitle = NSLocalizedString(@"MEDIA_LIBRARY_LABEL", nil);
    template.tabImage = [UIImage systemImageNamed:@"music.note.house"];
    return template;
}

- (CPGridButton *)buttonWithTitle:(NSString *)title
                            image:(UIImage *)image
                         template:(CPListTemplate *(^)(void))templateProvider
{
    return [[CPGridButton alloc] initWithTitleVariants:@[title]
                                                 image:image
                                               handler:^(CPGridButton * _Nonnull button) {
        [self.interfaceController pushTemplate:templateProvider() animated:YES];
    }];
}

- (UIImage *)gridTileImageForSymbolNamed:(NSString *)symbolName
{
    CGSize canvasSize = CGSizeMake(80.0, 80.0);
    if (@available(iOS 14.0, *)) {
        canvasSize = [CPListItem maximumImageSize];
    }

    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:canvasSize.height * 0.55];
    UIImage *symbol = [UIImage systemImageNamed:symbolName withConfiguration:configuration];

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:canvasSize];
    UIImage *paddedImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGSize symbolSize = symbol.size;
        CGRect drawRect = CGRectMake((canvasSize.width - symbolSize.width) / 2.0,
                                     (canvasSize.height - symbolSize.height) / 2.0,
                                     symbolSize.width, symbolSize.height);
        [symbol drawInRect:drawRect];
    }];

    return [paddedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end

#pragma clang diagnostic pop
