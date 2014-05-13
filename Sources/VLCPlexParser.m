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
    } else if([elementName isEqualToString:@"Directory"]) {
        [_dicoInfo setObject:@"directory" forKey:@"container"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"key"] forKey:@"key"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
    } else if([elementName isEqualToString:@"Video"]) {
        [_dicoInfo setObject:@"item" forKey:@"container"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"key"] forKey:@"key"];
        [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
    } else if([elementName isEqualToString:@"Part"]) {
        [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@",_PlexMediaServerUrl, [attributeDict objectForKey:@"key"]] forKey:@"keyMedia"];
        if([attributeDict objectForKey:@"file"])
            [_dicoInfo setObject:[[attributeDict objectForKey:@"file"] lastPathComponent] forKey:@"namefile"];
        NSString *duration = [self timeFormatted:[[attributeDict objectForKey:@"duration"] intValue]];
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

    if ([attributeDict objectForKey:@"thumb"] && ([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Directory"] || [elementName isEqualToString:@"Part"]))
        [_dicoInfo setObject:[NSString stringWithFormat:@"%@%@", _PlexMediaServerUrl, [attributeDict objectForKey:@"thumb"]] forKey:@"thumb"];

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if(([elementName isEqualToString:@"Video"] || [elementName isEqualToString:@"Directory"] || [elementName isEqualToString:@"MediaContainer"]) && [_dicoInfo count] > 0) {
        [_containerInfo addObject:_dicoInfo];
        _dicoInfo = [[NSMutableDictionary alloc] init];
    }
}

- (NSString *)timeFormatted:(int)mSeconds
{
    mSeconds = (int)(mSeconds / 1000);
    int seconds = (int)(mSeconds % 60);
    int minutes = (int)((mSeconds / 60) % 60);
    int hours = (int)(mSeconds / 3600);
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

@end