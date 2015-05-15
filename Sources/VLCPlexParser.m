/*****************************************************************************
 * VLCPlexParser.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlexParser.h"
#import "VLCPlexWebAPI.h"
#import "UIDevice+VLC.h"
#import "VLCAlertView.h"
#import "VLCConstants.h"

#define kPlexMediaServerDirInit @"library/sections"
#define kPlexVLCDeviceName @"VLC for iOS"

@interface VLCPlexParser () <NSXMLParserDelegate>
{
    NSMutableArray *_containerInfo;
    NSMutableDictionary *_dicoInfo;
    NSString *_PlexMediaServerUrl;
}
@end

@implementation VLCPlexParser

- (NSMutableArray *)PlexMediaServerParser:(NSString *)adress port:(NSString *)port navigationPath:(NSString *)path authentification:(NSString *)auth
{
    _containerInfo = [[NSMutableArray alloc] init];
    [_containerInfo removeAllObjects];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    _PlexMediaServerUrl = [NSString stringWithFormat:@"http://%@%@",adress, port];
    NSString *mediaServerUrl;

    if ([path isEqualToString:@""])
        mediaServerUrl = [NSString stringWithFormat:@"%@/%@",_PlexMediaServerUrl, kPlexMediaServerDirInit];
    else {
        if ([path rangeOfString:@"library"].location != NSNotFound)
            mediaServerUrl = [NSString stringWithFormat:@"%@%@",_PlexMediaServerUrl, path];
        else
            mediaServerUrl = [NSString stringWithFormat:@"%@/%@/%@",_PlexMediaServerUrl, kPlexMediaServerDirInit, path];
    }

    VLCPlexWebAPI *PlexWebAPI = [[VLCPlexWebAPI alloc] init];
    NSURL *url = [[NSURL alloc] initWithString:[PlexWebAPI urlAuth:mediaServerUrl autentification:auth]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if ([response statusCode] != 200) {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if([responseString rangeOfString:@"Unauthorized"].location != NSNotFound) {

            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSString *username = [prefs stringForKey:kVLCPLEXLogin];
            NSString *password = [prefs stringForKey:kVLCPLEXPassword];

            if ((username && password) && ((![username isEqualToString:@""]) && (![password isEqualToString:@""]))) {
                auth = [PlexWebAPI PlexAuthentification:username password:password];
                url = [NSURL URLWithString:[PlexWebAPI urlAuth:mediaServerUrl autentification:auth]];
                request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
                response = nil;
                error = nil;
                data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                if ([response statusCode] != 200) {
                    VLCAlertView *alertView = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"PLEX_ERROR_ACCOUNT", nil) message:NSLocalizedString(@"PLEX_CHECK_ACCOUNT", nil) cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
                    [alertView show];
                }
                [_containerInfo removeAllObjects];
                [_dicoInfo removeAllObjects];
            } else {
                VLCAlertView *alertView = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"UNAUTHORIZED", nil) message:NSLocalizedString(@"PLEX_CHECK_ACCOUNT", nil) cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
                [alertView show];
            }
        } else
            APLog(@"PlexParser url Errors : %ld", (long)[response statusCode]);
    }

    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:data];
    [xmlparser setDelegate:self];

    if (![xmlparser parse])
        APLog(@"PlexParser url Errors : %@", url);

    [_containerInfo setValue:auth forKey:@"authentification"];

    return _containerInfo;
}

- (NSMutableArray *)PlexExtractDeviceInfo:(NSData *)data
{
    _containerInfo = [[NSMutableArray alloc] init];
    [_containerInfo removeAllObjects];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:data];
    [xmlparser setDelegate:self];

    if (![xmlparser parse])
        NSLog(@"PlexParser data Errors : %@", data);

    return _containerInfo;
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

#pragma mark - API

- (NSInteger)MarkWatchedUnwatchedMedia:(NSString *)adress port:(NSString *)port videoRatingKey:(NSString *)ratingKey state:(NSString *)state authentification:(NSString *)auth
{
    NSString *url = nil;

    if ([state isEqualToString:@"watched"])
        url = [NSString stringWithFormat:@"http://%@%@/:/unscrobble?identifier=com.plexapp.plugins.library&key=%@", adress, port, ratingKey];
    else
        url = [NSString stringWithFormat:@"http://%@%@/:/scrobble?identifier=com.plexapp.plugins.library&key=%@", adress, port, ratingKey];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[[[VLCPlexWebAPI alloc] init] urlAuth:url autentification:auth]] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    NSInteger httpStatus = [(NSHTTPURLResponse *)response statusCode];

    if (httpStatus != 200)
        APLog(@"Mark Watched Unwatched Media Error status: %ld at URL : %@", (long)httpStatus, url);

    return httpStatus;
}

- (NSString *)getFileSubtitleFromPlexServer:(NSMutableArray *)mutableMediaObject modeStream:(BOOL)modeStream
{
    NSString *FileSubtitlePath = nil;
    NSString *fileName = [[[[mutableMediaObject objectAtIndex:0] objectForKey:@"namefile"] stringByDeletingPathExtension] stringByAppendingPathExtension:[[mutableMediaObject objectAtIndex:0] objectForKey:@"codecSubtitle"]];

    VLCPlexWebAPI *PlexWebAPI = [[VLCPlexWebAPI alloc] init];
    NSURL *url = [[NSURL alloc] initWithString:[PlexWebAPI urlAuth:[[mutableMediaObject objectAtIndex:0] objectForKey:@"keySubtitle"] autentification:[[mutableMediaObject objectAtIndex:0] objectForKey:@"authentification"]]];

    NSData *receivedSub = [NSData dataWithContentsOfURL:url];

    if (receivedSub.length < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        NSArray *searchPaths =  nil;
        if (modeStream)
            searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        else
            searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

        NSString *directoryPath = [searchPaths objectAtIndex:0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:fileName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
            [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:FileSubtitlePath])
                APLog(@"file creation failed, no data was saved");
        }
        [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), fileName, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }

    return FileSubtitlePath;
}

@end