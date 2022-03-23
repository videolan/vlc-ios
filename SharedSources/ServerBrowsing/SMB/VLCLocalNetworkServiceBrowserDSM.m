/*****************************************************************************
 * VLCLocalNetworkServiceBrowserDSM.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCNetworkServerLoginInformation.h"

@interface VLCLocalNetworkServiceDSM ()
+ (void)registerLoginInformation;
@end

@implementation VLCLocalNetworkServiceBrowserDSM

- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil);
#else
    NSString *name = NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil);
#endif

    return [super initWithName:name
            serviceServiceName:@"dsm"];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceDSM alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

+ (void)initialize
{
    [super initialize];
    [VLCLocalNetworkServiceDSM registerLoginInformation];
}

@end


NSString *const VLCNetworkServerProtocolIdentifierSMB = @"smb";
static NSString *const VLCLocalNetworkServiceDSMWorkgroupIdentifier = @"VLCLocalNetworkServiceDSMWorkgroup";

@implementation VLCLocalNetworkServiceDSM

+ (void)registerLoginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierSMB;
    VLCNetworkServerLoginInformationField *workgroupField = [[VLCNetworkServerLoginInformationField alloc] initWithType:VLCNetworkServerLoginInformationFieldTypeText
                                                                                                             identifier:VLCLocalNetworkServiceDSMWorkgroupIdentifier
                                                                                                                  label:NSLocalizedString(@"DSM_WORKGROUP", nil)
                                                                                                              textValue:@"WORKGROUP"];
    login.additionalFields = @[workgroupField];


    [VLCNetworkServerLoginInformation registerTemplateLoginInformation:login];
}

- (VLCNetworkServerLoginInformation *)loginInformation {

    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:VLCNetworkServerProtocolIdentifierSMB];
    login.address = self.mediaItem.url.host;
    return login;
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (SMB)

+ (instancetype)SMBNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSString *path = [NSString stringWithFormat:@"//%@", login.address];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:path];
    components.scheme = @"smb";
    components.port = login.port;
    NSURL *url = components.URL;

    __block NSString *workgroup = nil;
    [login.additionalFields enumerateObjectsUsingBlock:^(VLCNetworkServerLoginInformationField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:VLCLocalNetworkServiceDSMWorkgroupIdentifier])
        {
            workgroup = obj.textValue;
        }
    }];

    return [self SMBNetworkServerBrowserWithURL:url
                                       username:login.username
                                       password:login.password
                                      workgroup:workgroup];
}

+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password workgroup:(NSString *)workgroup
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSMutableDictionary *mediaOptions = @{
        @"smb-user" : username ?: @"",
        @"smb-pwd" : password ?: @"",
        @"smb-domain" : workgroup?: @"WORKGROUP",
    }.mutableCopy;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCForceSMBV1]) {
        mediaOptions[kVLCForceSMBV1] = [NSNull null];
    }
	[media addOptions:mediaOptions];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end
