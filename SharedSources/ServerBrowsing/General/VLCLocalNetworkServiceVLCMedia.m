/*****************************************************************************
 * VLCLocalNetworkServiceVLCMedia.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCNetworkServerLoginInformation.h"
#import "VLCNetworkServerBrowserVLCMedia+FTP.h"

@interface VLCLocalNetworkServiceVLCMedia()
@property (nonatomic) VLCMedia *mediaItem;
@end

@implementation VLCLocalNetworkServiceVLCMedia
@synthesize serviceName = _serviceName;
- (instancetype)initWithMediaItem:(VLCMedia *)mediaItem serviceName:(nonnull NSString *)serviceName
{
    self = [super init];
    if (self) {
        _mediaItem = mediaItem;
        _serviceName = serviceName;
    }
    return self;
}
- (NSString *)title {
    return [self.mediaItem metadataForKey:VLCMetaInformationTitle];
}
- (UIImage *)icon {
    UIImage *image;
    NSString *artworkMRL = [self.mediaItem metadataForKey:VLCMetaInformationArtworkURL];
    if (artworkMRL) {
        NSURL *url = [NSURL URLWithString:artworkMRL];
        if (url) {
            NSData *imageData = [NSData dataWithContentsOfURL:url];
            if (imageData) {
                image = [UIImage imageWithData:imageData];
            }
        }
    }
    if (!image) {
        image = [UIImage imageNamed:@"serverIcon"];
    }
    return image;
}

- (NSURL *)iconURL {
    NSURL *url;
    NSString *artworkMRL = [self.mediaItem metadataForKey:VLCMetaInformationArtworkURL];
    if (artworkMRL) {
        url = [NSURL URLWithString:artworkMRL];
    }
    return url;
}

- (VLCNetworkServerLoginInformation *)loginInformation {
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory) {
        return nil;
    }

    if ([_serviceName isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:VLCNetworkServerProtocolIdentifierFTP];
        login.address = self.mediaItem.url.host;
        return login;
    }

    return nil;
}

@end
