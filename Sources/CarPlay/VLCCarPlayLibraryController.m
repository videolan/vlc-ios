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
#import "CPInterfaceController+VLCTemplateStack.h"
#import "VLCCarPlayArtistsController.h"
#import "VLCCarPlayAlbumsController.h"
#import "CPListTemplate+Genres.h"
#import "VLCCarPlayFoldersController.h"
#import "VLC-Swift.h"

@implementation VLCCarPlayLibraryController
{
    VLCCarPlayArtistsController *_artistsController;
    VLCCarPlayAlbumsController *_albumsController;
    VLCCarPlayFoldersController *_foldersController;
}

- (CPGridTemplate *)libraryTemplate
{
    _artistsController = [[VLCCarPlayArtistsController alloc] init];
    _artistsController.interfaceController = self.interfaceController;
    _albumsController = [[VLCCarPlayAlbumsController alloc] init];
    _albumsController.interfaceController = self.interfaceController;
    _foldersController = [[VLCCarPlayFoldersController alloc] init];
    _foldersController.interfaceController = self.interfaceController;

    NSArray<CPGridButton *> *buttons = @[
        [self buttonWithTitle:NSLocalizedString(@"ARTISTS", nil)
                       symbol:@"music.mic"
                     template:^{ return [self->_artistsController artistList]; }],
        [self buttonWithTitle:NSLocalizedString(@"ALBUMS", nil)
                       symbol:@"square.stack"
                     template:^{ return [self->_albumsController albumList]; }],
        [self buttonWithTitle:NSLocalizedString(@"GENRES", nil)
                       symbol:@"tag"
                     template:^{ return [CPListTemplate genreList]; }],
        [self buttonWithTitle:NSLocalizedString(@"FOLDERS", nil)
                       symbol:@"folder"
                     template:^{ return [self->_foldersController folderList]; }],
    ];

    CPGridTemplate *template = [[CPGridTemplate alloc] initWithTitle:NSLocalizedString(@"MEDIA_LIBRARY_LABEL", nil)
                                                         gridButtons:buttons];
    template.tabTitle = NSLocalizedString(@"MEDIA_LIBRARY_LABEL", nil);
    template.tabImage = [UIImage systemImageNamed:@"music.note.house"];
    return template;
}

- (CPGridButton *)buttonWithTitle:(NSString *)title
                           symbol:(NSString *)symbol
                         template:(CPListTemplate *(^)(void))templateProvider
{
    return [[CPGridButton alloc] initWithTitleVariants:@[title]
                                                 image:[VLCCarPlayBrowserController placeholderForSymbol:symbol]
                                               handler:^(CPGridButton * _Nonnull button) {
        [self.interfaceController pushTemplateWithinDepthLimit:templateProvider() animated:YES];
    }];
}

@end
