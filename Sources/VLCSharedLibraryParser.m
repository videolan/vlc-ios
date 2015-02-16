/*****************************************************************************
 * VLCSharedLibraryParser.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSharedLibraryParser.h"

#define kLibraryXmlFile @"libMediaVLC.xml"

@interface VLCSharedLibraryParser () <NSXMLParserDelegate>
{
    NSMutableArray *_containerInfo;
    NSMutableDictionary *_dicoInfo;
    NSString *_libraryServerUrl;
}
@end

@implementation VLCSharedLibraryParser

- (NSMutableArray *)VLCLibraryServerParser:(NSString *)adress port:(NSString *)port
{
    _containerInfo = [[NSMutableArray alloc] init];
    [_containerInfo removeAllObjects];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    _libraryServerUrl = [NSString stringWithFormat:@"http://%@%@", adress, port];

    NSString *mediaServerUrl = [NSString stringWithFormat:@"%@/%@", _libraryServerUrl, kLibraryXmlFile];

    NSURL *url = [[NSURL alloc] initWithString:mediaServerUrl];
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [xmlparser setDelegate:self];

    if (![xmlparser parse])
        APLog(@"VLC Library Parser url Errors : %@", url);

    return _containerInfo;
}

- (BOOL)isVLCMediaServer:(NSString *)adress port:(NSString *)port
{
    NSMutableArray *mutableObjectList = [[NSMutableArray alloc] init];
    mutableObjectList = [self VLCLibraryServerParser:adress port:port];
    if (mutableObjectList.count > 0) {
        NSString *identifier = [[mutableObjectList objectAtIndex:0] objectForKey:@"identifier"];
        if ([identifier isEqualToString:@"org.videolan.vlc-ios"])
            return YES;
    }
    return NO;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString:@"MediaContainer"]) {
        if ([attributeDict objectForKey:@"size"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"size"] forKey:@"size"];
        if ([attributeDict objectForKey:@"identifier"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"identifier"] forKey:@"identifier"];
        if ([attributeDict objectForKey:@"libraryTitle"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"libraryTitle"] forKey:@"libTitle"];
    } else if([elementName isEqualToString:@"Media"]) {
        if([attributeDict objectForKey:@"title"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
        if([attributeDict objectForKey:@"thumb"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"thumb"] forKey:@"thumb"];
        if([attributeDict objectForKey:@"duration"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"duration"] forKey:@"duration"];
        if([attributeDict objectForKey:@"size"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"size"] forKey:@"size"];
        if([attributeDict objectForKey:@"pathfile"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"pathfile"] forKey:@"pathfile"];
        if([attributeDict objectForKey:@"pathSubtitle"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"pathSubtitle"] forKey:@"pathSubtitle"];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if(([elementName isEqualToString:@"Media"] || [elementName isEqualToString:@"MediaContainer"]) && [_dicoInfo count] > 0) {
        [_containerInfo addObject:_dicoInfo];
        _dicoInfo = [[NSMutableDictionary alloc] init];
    }
}

@end
