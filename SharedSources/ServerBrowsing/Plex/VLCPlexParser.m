/*****************************************************************************
 * VLCPlexParser.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2017 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlexParser.h"
#import "VLCPlexWebAPI.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>

static NSString *const kPlexMediaServerDirInit = @"/library/sections";
static NSString *const kPlexVLCDeviceName = @"VLC for iOS";

@interface VLCPlexParser () <NSXMLParserDelegate>
{
    NSMutableArray *_containerInfo;
    NSMutableDictionary *_dicoInfo;
    NSString *_PlexMediaServerUrl;
}
@end

@implementation VLCPlexParser

- (NSArray *)PlexMediaServerParser:(NSString *)address port:(NSNumber *)port navigationPath:(NSString *)path authentification:(NSString *)auth error:(NSError *__autoreleasing *)outError
{
    _containerInfo = [[NSMutableArray alloc] init];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = @"http";
    urlComponents.host = address;
    urlComponents.port = port;

    _PlexMediaServerUrl = [urlComponents URL].absoluteString;

    NSString *mediaServerUrl;

    if ([path length] == 0) {
        urlComponents.path = kPlexMediaServerDirInit;
    } else {
        if ([path rangeOfString:@"library"].location != NSNotFound) {
            urlComponents.path = [@"/" stringByAppendingPathComponent:path];
        } else {
            urlComponents.path = [kPlexMediaServerDirInit stringByAppendingPathComponent:path];
        }
    }

    mediaServerUrl = [[urlComponents URL].absoluteString stringByRemovingPercentEncoding];

    VLCPlexWebAPI *PlexWebAPI = [[VLCPlexWebAPI alloc] init];
    NSURL *url = [[NSURL alloc] initWithString:[PlexWebAPI urlAuth:mediaServerUrl authentification:auth]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [self sendSynchronousRequest:request returningResponse:&response error:&error];

    if ([response statusCode] != 200) {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if([responseString rangeOfString:@"Unauthorized"].location != NSNotFound) {
            NSString *serviceString = [NSString stringWithFormat:@"plex://%@:%@", address, port];
            XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemsForService:serviceString error:nil].firstObject;
            if (!keychainItem) {
                serviceString = [NSString stringWithFormat:@"plex://Account:%@", port];
                keychainItem = [XKKeychainGenericPasswordItem itemsForService:serviceString error:nil].firstObject;
            }
            if (keychainItem) {
                NSString *username = keychainItem.account;
                NSString *password = keychainItem.secret.stringValue;

                auth = [PlexWebAPI PlexAuthentification:username password:password];
                url = [NSURL URLWithString:[PlexWebAPI urlAuth:mediaServerUrl authentification:auth]];
                request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
                response = nil;
                error = nil;
                data = [self sendSynchronousRequest:request returningResponse:&response error:&error];
                if ([response statusCode] != 200) {
                    if (outError) {

                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:
                                                         @{
                                                           NSLocalizedDescriptionKey : NSLocalizedString(@"PLEX_ERROR_ACCOUNT", nil),
                                                           NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"PLEX_CHECK_ACCOUNT", nil),
                                                           }];
                        if (error) {
                            userInfo[NSUnderlyingErrorKey] = error;
                        }
                        *outError = [NSError errorWithDomain:@"org.videolan.vlc-ios.plexParser"
                                                       code:response.statusCode
                                                   userInfo:userInfo];
                    }
                }
                [_containerInfo removeAllObjects];
                [_dicoInfo removeAllObjects];
            } else {

                if (outError) {

                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:
                                                     @{
                                                       NSLocalizedDescriptionKey : NSLocalizedString(@"UNAUTHORIZED", nil),
                                                       NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"PLEX_CHECK_ACCOUNT", nil),
                                                       }];
                    if (error) {
                        userInfo[NSUnderlyingErrorKey] = error;
                    }
                    *outError = [NSError errorWithDomain:@"org.videolan.vlc-ios.plexParser"
                                                    code:response.statusCode
                                                userInfo:userInfo];
                }
            }
        } else
            APLog(@"PlexParser url Errors : %ld", (long)[response statusCode]);
    }

    if (error) {
        APLog(@"PlexParser url Error: %@", error);
    }
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:data];
    [xmlparser setDelegate:self];

    if (![xmlparser parse])
        APLog(@"PlexParser url Errors : %@", url);

    [_containerInfo setValue:auth forKey:@"authentification"];

    return [NSArray arrayWithArray:_containerInfo];
}

- (NSArray *)PlexExtractDeviceInfo:(NSData *)data
{
    _containerInfo = [[NSMutableArray alloc] init];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:data];
    [xmlparser setDelegate:self];

    if (![xmlparser parse])
        APLog(@"PlexParser data Errors : %@", data);

    return [NSArray arrayWithArray:_containerInfo];
}

#pragma mark - Parser

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"MediaContainer"]) {
        if ([attributeDict objectForKey:@"friendlyName"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"friendlyName"] forKey:@"libTitle"];
        else if ([attributeDict objectForKey:@"title1"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"title1"] forKey:@"libTitle"];
        if ([attributeDict objectForKey:@"title2"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"title2"] forKey:@"libTitle"];
        if ([attributeDict objectForKey:@"grandparentTitle"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"grandparentTitle"] forKey:@"grandparentTitle"];

    } else if ([elementName isEqualToString:@"Directory"]) {
        [_dicoInfo setObject:@"directory" forKey:@"container"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"key"] forKey:@"key"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];

    } else if ([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Track"]) {
        [_dicoInfo setObject:@"item" forKey:@"container"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"key"] forKey:@"key"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"ratingKey"] forKey:@"ratingKey"];
        if ([attributeDict objectForKey:@"summary"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"summary"] forKey:@"summary"];
        if ([attributeDict objectForKey:@"viewCount"])
            [_dicoInfo setObject:@"watched" forKey:@"state"];
        else
            [_dicoInfo setObject:@"unwatched" forKey:@"state"];

    } else if ([elementName isEqualToString:@"Media"]) {
        if ([attributeDict objectForKey:@"audioCodec"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"audioCodec"] forKey:@"audioCodec"];
        if ([attributeDict objectForKey:@"videoCodec"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"videoCodec"] forKey:@"videoCodec"];

    } else if ([elementName isEqualToString:@"Part"]) {
        [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@",_PlexMediaServerUrl, [attributeDict objectForKey:@"key"]] forKey:@"keyMedia"];
        if([attributeDict objectForKey:@"file"])
            [_dicoInfo setObject:[[attributeDict objectForKey:@"file"] lastPathComponent] forKey:@"namefile"];
        NSString *duration = [[VLCTime timeWithNumber:[attributeDict objectForKey:@"duration"]] stringValue];
        [_dicoInfo setObject:duration forKey:@"duration"];
        NSString *sizeFile = (NSString *)[attributeDict objectForKey:@"size"];
        if (sizeFile)
            [_dicoInfo setObject:sizeFile forKey:@"size"];

    } else if ([elementName isEqualToString:@"Stream"]) {
        if ([attributeDict objectForKey:@"key"])
            [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@",_PlexMediaServerUrl, [attributeDict objectForKey:@"key"]] forKey:@"keySubtitle"];
        if ([attributeDict objectForKey:@"codec"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"codec"] forKey:@"codecSubtitle"];
        if ([attributeDict objectForKey:@"language"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"language"] forKey:@"languageSubtitle"];
        if ([attributeDict objectForKey:@"languageCode"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"languageCode"] forKey:@"languageCode"];

    } else if ([elementName isEqualToString:@"Device"] && [[attributeDict objectForKey:@"name"] isEqualToString:kPlexVLCDeviceName]) {
        if ([attributeDict objectForKey:@"name"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"name"] forKey:@"name"];
        if ([attributeDict objectForKey:@"product"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"product"] forKey:@"product"];
        if ([attributeDict objectForKey:@"productVersion"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"productVersion"] forKey:@"productVersion"];
        if ([attributeDict objectForKey:@"platformVersion"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"platformVersion"] forKey:@"platformVersion"];
        if ([attributeDict objectForKey:@"token"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"token"] forKey:@"token"];
        if ([attributeDict objectForKey:@"clientIdentifier"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"clientIdentifier"] forKey:@"clientIdentifier"];
        if ([attributeDict objectForKey:@"id"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"id"] forKey:@"id"];
    }

    if ([attributeDict objectForKey:@"thumb"] && ([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Directory"] || [elementName isEqualToString:@"Part"] || [elementName isEqualToString:@"Track"]))
        [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@", _PlexMediaServerUrl, [attributeDict objectForKey:@"thumb"]] forKey:@"thumb"];

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Track"] || [elementName isEqualToString:@"Directory"] || [elementName isEqualToString:@"MediaContainer"] || [elementName isEqualToString:@"Device"]) && [_dicoInfo count] > 0) {
        [_containerInfo addObject:_dicoInfo];
        _dicoInfo = [[NSMutableDictionary alloc] init];
    }
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    NSError __block *erreur = NULL;
    NSData __block *data;
    BOOL __block reqProcessed = false;
    NSURLResponse __block *urlResponse;

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable _error) {
        urlResponse = _response;
        erreur = _error;
        data = _data;
        reqProcessed = true;
    }] resume];

    while (!reqProcessed) {
        [NSThread sleepForTimeInterval:0];
    }

    *response = urlResponse;
    *error = erreur;
    return data;
}

@end
