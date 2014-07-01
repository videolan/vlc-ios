/*****************************************************************************
 * VLCPlexParser.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlexParser.h"

#define kPlexMediaServerDirInit @"library/sections"

@interface VLCPlexParser () <NSXMLParserDelegate>
{
    NSMutableArray *_containerInfo;
    NSMutableDictionary *_dicoInfo;
    NSString *_PlexMediaServerUrl;
}
@end

@implementation VLCPlexParser

- (NSMutableArray *)PlexMediaServerParser:(NSString *)adress port:(NSString *)port navigationPath:(NSString *)path
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

    NSURL *url = [[NSURL alloc] initWithString:mediaServerUrl];
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [xmlparser setDelegate:self];

    if (![xmlparser parse])
        APLog(@"PlexParser url Errors : %@", url);

    return _containerInfo;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString:@"MediaContainer"]) {
        if ([attributeDict objectForKey:@"friendlyName"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"friendlyName"] forKey:@"libTitle"];
        else if ([attributeDict objectForKey:@"title1"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"title1"] forKey:@"libTitle"];
        if ([attributeDict objectForKey:@"title2"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"title2"] forKey:@"libTitle"];
    } else if([elementName isEqualToString:@"Directory"]) {
        [_dicoInfo setObject:@"directory" forKey:@"container"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"key"] forKey:@"key"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
    } else if([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Track"]) {
        [_dicoInfo setObject:@"item" forKey:@"container"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"key"] forKey:@"key"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"ratingKey"] forKey:@"ratingKey"];
        if([attributeDict objectForKey:@"viewCount"])
            [_dicoInfo setObject:@"watched" forKey:@"state"];
        else
            [_dicoInfo setObject:@"unwatched" forKey:@"state"];

    } else if([elementName isEqualToString:@"Part"]) {
        [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@",_PlexMediaServerUrl, [attributeDict objectForKey:@"key"]] forKey:@"keyMedia"];
        if([attributeDict objectForKey:@"file"])
            [_dicoInfo setObject:[[attributeDict objectForKey:@"file"] lastPathComponent] forKey:@"namefile"];
        NSString *duration = [[VLCTime timeWithNumber:[attributeDict objectForKey:@"duration"]] stringValue];
        [_dicoInfo setObject:duration forKey:@"duration"];
        NSString *sizeFile = (NSString *)[attributeDict objectForKey:@"size"];
        [_dicoInfo setObject:sizeFile forKey:@"size"];
    } else if([elementName isEqualToString:@"Stream"]) {
        if([attributeDict objectForKey:@"key"]){
            [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@",_PlexMediaServerUrl, [attributeDict objectForKey:@"key"]] forKey:@"keySubtitle"];
            [_dicoInfo setObject:[attributeDict objectForKey:@"codec"] forKey:@"codecSubtitle"];
            [_dicoInfo setObject:[attributeDict objectForKey:@"language"] forKey:@"languageSubtitle"];
        }
    }

    if ([attributeDict objectForKey:@"thumb"] && ([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Directory"] || [elementName isEqualToString:@"Part"] || [elementName isEqualToString:@"Track"]))
        [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@", _PlexMediaServerUrl, [attributeDict objectForKey:@"thumb"]] forKey:@"thumb"];

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if(([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Track"] || [elementName isEqualToString:@"Directory"] || [elementName isEqualToString:@"MediaContainer"]) && [_dicoInfo count] > 0) {
        [_containerInfo addObject:_dicoInfo];
        _dicoInfo = [[NSMutableDictionary alloc] init];
    }
}

- (NSInteger)MarkWatchedUnwatchedMedia:(NSString *)adress port:(NSString *)port videoRatingKey:(NSString *)ratingKey state:(NSString *)state
{
    NSString *url = nil;

    if ([state isEqualToString:@"watched"])
        url = [NSString stringWithFormat:@"http://%@%@/:/unscrobble?identifier=com.plexapp.plugins.library&key=%@", adress, port, ratingKey];
    else
        url = [NSString stringWithFormat:@"http://%@%@/:/scrobble?identifier=com.plexapp.plugins.library&key=%@", adress, port, ratingKey];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    NSInteger httpStatus = [(NSHTTPURLResponse *)response statusCode];

    if (httpStatus != 200)
        APLog(@"Mark Watched Unwatched Media Error status: %ld at URL : %@", (long)httpStatus, url);

    return httpStatus;
}

@end