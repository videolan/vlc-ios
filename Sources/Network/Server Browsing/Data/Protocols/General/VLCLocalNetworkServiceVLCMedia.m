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
#if LIBVLC_VERSION_MAJOR == 3
    return [self.mediaItem metadataForKey:VLCMetaInformationTitle];
#else
    return self.mediaItem.metaData.title;
#endif
}
- (UIImage *)icon {
    UIImage *image;
#if LIBVLC_VERSION_MAJOR == 3
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
#else
    NSURL *artworkURL = self.mediaItem.metaData.artworkURL;
    if (artworkURL) {
        NSData *imageData = [NSData dataWithContentsOfURL:artworkURL];
        if (imageData) {
            image = [UIImage imageWithData:imageData];
        }
    }
#endif
    if (!image) {
        image = [UIImage imageNamed:@"serverIcon"];
    }
    return image;
}

- (NSURL *)iconURL {
#if LIBVLC_VERSION_MAJOR == 3
    NSURL *url;
    NSString *artworkMRL = [self.mediaItem metadataForKey:VLCMetaInformationArtworkURL];
    if (artworkMRL) {
        url = [NSURL URLWithString:artworkMRL];
    }
    return url;
#else
    return self.mediaItem.metaData.artworkURL;
#endif
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
