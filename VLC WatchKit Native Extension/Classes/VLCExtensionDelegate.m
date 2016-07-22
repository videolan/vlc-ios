/*****************************************************************************
 * VLCExtensionDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCExtensionDelegate.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <CoreData/CoreData.h>
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "VLCWatchMessage.h"
#import "VLCBaseInterfaceController.h"

@interface VLCExtensionDelegate() <NSFileManagerDelegate, WCSessionDelegate>

@end

@implementation VLCExtensionDelegate 

- (void)applicationDidFinishLaunching
{
    MLMediaLibrary *library = [MLMediaLibrary sharedMediaLibrary];
    library.additionalPersitentStoreOptions = @{ NSReadOnlyPersistentStoreOption : @(YES) };

    WCSession *wcsession = [WCSession defaultSession];
    wcsession.delegate = self;
    [wcsession activateSession];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message
{
    VLCWatchMessage *msg = [[VLCWatchMessage alloc] initWithDictionary:message];
    if ([msg.name isEqualToString: VLCWatchMessageNameNotification]) {
        NSDictionary *payloadDict = (NSDictionary *)msg.payload;
        NSString *name = payloadDict[@"name"];
        if (name) {
            [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                                object:self
                                                              userInfo:payloadDict[@"userInfo"]];
        }
    }
}

- (void)session:(WCSession *)session didReceiveFile:(WCSessionFile *)file
{
    NSString *fileType = file.metadata[@"filetype"];
    if ([fileType isEqualToString:@"coredata"]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self copyUpdatedCoreDataDBFromURL:file.fileURL];
        });
    }
    if ([fileType isEqualToString:@"thumbnail"]) {
        [self copyThumbnailToDatabase:file];
    }
}

- (void)copyUpdatedCoreDataDBFromURL:(NSURL *)url
{
    MLMediaLibrary *library = [MLMediaLibrary sharedMediaLibrary];
    [library overrideLibraryWithLibraryFromURL:url];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCDBUpdateNotification
                                                        object:self];
}

- (void)copyThumbnailToDatabase:(WCSessionFile *)file
{
    NSData *data = [NSData dataWithContentsOfURL:file.fileURL];
    if (!data) {
        return;
    }
    UIImage *image = [UIImage imageWithData:data];
    if (!image) {
        return;
    }
    NSString *uriRepresentation = file.metadata[@"URIRepresentation"];
    NSURL *objectIDURL = [NSURL URLWithString:uriRepresentation];
    if (objectIDURL) {
        MLMediaLibrary *library = [MLMediaLibrary sharedMediaLibrary];
        MLFile *file = (MLFile *)[library objectForURIRepresentation:objectIDURL];
        file.computedThumbnail = image;
    }
}

@end
