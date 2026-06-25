/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTopShelfContentProvider.h"
#import "VLCTopShelfConstants.h"
#import <UIKit/UIKit.h>

@implementation VLCTopShelfContentProvider

- (void)loadTopShelfContentWithCompletionHandler:(void (^)(id<TVTopShelfContent> _Nullable))completionHandler
{
    NSString *groupIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MLKitGroupIdentifier"];
    if (groupIdentifier.length == 0) {
        completionHandler(nil);
        return;
    }

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:groupIdentifier];
    NSData *data = [defaults objectForKey:kVLCTopShelfDefaultsKey];
    id raw = [data isKindOfClass:[NSData class]] ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![raw isKindOfClass:[NSDictionary class]]) {
        completionHandler(nil);
        return;
    }
    NSDictionary *snapshot = raw;

    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    NSURL *imageDirectory = [containerURL URLByAppendingPathComponent:kVLCTopShelfImageDirectory isDirectory:YES];

    NSArray *entries = snapshot[kVLCTopShelfItemsKey];
    if (![entries isKindOfClass:[NSArray class]]) {
        completionHandler(nil);
        return;
    }

    NSMutableArray<TVTopShelfSectionedItem *> *items = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        if (![entry isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        NSNumber *identifier = entry[kVLCTopShelfItemIdentifierKey];
        NSString *itemTitle = entry[kVLCTopShelfItemTitleKey];
        if (![identifier isKindOfClass:[NSNumber class]] || itemTitle.length == 0) {
            continue;
        }

        TVTopShelfSectionedItem *item = [[TVTopShelfSectionedItem alloc] initWithIdentifier:identifier.stringValue];
        item.title = itemTitle;
        item.imageShape = TVTopShelfSectionedItemImageShapeHDTV;

        NSString *imageName = entry[kVLCTopShelfItemImageKey];
        if (imageName.length > 0 && imageDirectory != nil) {
            NSURL *imageURL = [imageDirectory URLByAppendingPathComponent:imageName];
            [item setImageURL:imageURL forTraits:TVTopShelfItemImageTraitScreenScale1x | TVTopShelfItemImageTraitScreenScale2x];
        }

        NSURL *deepLink = [self deepLinkForIdentifier:identifier.stringValue];
        item.playAction = [[TVTopShelfAction alloc] initWithURL:deepLink];
        item.displayAction = [[TVTopShelfAction alloc] initWithURL:deepLink];

        [items addObject:item];
    }

    if (items.count == 0) {
        completionHandler(nil);
        return;
    }

    NSString *sectionTitle = snapshot[kVLCTopShelfSectionTitleKey];
    TVTopShelfItemCollection *collection = [[TVTopShelfItemCollection alloc] initWithItems:items];
    collection.title = [sectionTitle isKindOfClass:[NSString class]] ? sectionTitle : @"";
    TVTopShelfSectionedContent *content = [[TVTopShelfSectionedContent alloc] initWithSections:@[collection]];
    completionHandler(content);
}

- (NSURL *)deepLinkForIdentifier:(NSString *)identifier
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"vlc";
    components.host = @"topshelf";
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"id" value:identifier]];
    return components.URL;
}

@end
