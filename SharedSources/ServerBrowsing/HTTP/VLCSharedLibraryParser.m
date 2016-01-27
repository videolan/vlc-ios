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

NSString *const VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance = @"VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance";

@interface VLCSharedLibraryParser () <NSXMLParserDelegate>
{
    NSMutableArray *_containerInfo;
    NSMutableDictionary *_dicoInfo;
}
@end

@implementation VLCSharedLibraryParser

- (void)checkNetserviceForVLCService:(NSNetService *)aNetService
{
    [self performSelectorInBackground:@selector(parseNetServiceOnBackgroundThread:) withObject:aNetService];
}

- (void)parseNetServiceOnBackgroundThread:(NSNetService *)aNetService
{
    NSString *hostnamePort = [NSString stringWithFormat:@"%@:%ld", [aNetService hostName], (long)[aNetService port]];
    NSArray *parsedContents = [self downloadAndProcessDataFromServer:hostnamePort];

    if (parsedContents.count > 0) {
        if ([[parsedContents.firstObject objectForKey:@"identifier"] isEqualToString:@"org.videolan.vlc-ios"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance
                                                                object:self
                                                              userInfo:@{@"aNetService" : aNetService}];
        }
    }
}

- (void)fetchDataFromServer:(NSString *)hostname port:(long)port
{
    NSString *hostnamePort = [NSString stringWithFormat:@"%@:%ld", hostname, port];
    [self performSelectorInBackground:@selector(processDataOnBackgroundThreadFromHostnameAndPort:) withObject:hostnamePort];
}

- (void)processDataOnBackgroundThreadFromHostnameAndPort:(NSString *)hostnameAndPort
{
    NSArray *parsedContents = [self downloadAndProcessDataFromServer:hostnameAndPort];

    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        id delegate = weakSelf.delegate;
        if ([delegate respondsToSelector:@selector(sharedLibraryDataProcessings:)]) {
            [delegate sharedLibraryDataProcessings:parsedContents];
        }
    }];

}

- (NSArray *)downloadAndProcessDataFromServer:(NSString *)hostnamePort
{
    _containerInfo = [[NSMutableArray alloc] init];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    NSString *serverURL = [NSString stringWithFormat:@"http://%@/%@", hostnamePort, kLibraryXmlFile];

    NSURL *url = [[NSURL alloc] initWithString:serverURL];
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [xmlparser setDelegate:self];

    if (![xmlparser parse]) {
        APLog(@"VLC Library Parser url Errors : %@", url);
        return [NSArray array];
    }

    return [_containerInfo copy];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"MediaContainer"]) {
        if ([attributeDict objectForKey:@"size"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"size"] forKey:@"size"];
        if ([attributeDict objectForKey:@"identifier"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"identifier"] forKey:@"identifier"];
        if ([attributeDict objectForKey:@"libraryTitle"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"libraryTitle"] forKey:@"libTitle"];
    } else if ([elementName isEqualToString:@"Media"]) {
        if ([attributeDict objectForKey:@"title"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"title"] forKey:@"title"];
        if ([attributeDict objectForKey:@"thumb"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"thumb"] forKey:@"thumb"];
        if ([attributeDict objectForKey:@"duration"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"duration"] forKey:@"duration"];
        if ([attributeDict objectForKey:@"size"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"size"] forKey:@"size"];
        if ([attributeDict objectForKey:@"pathfile"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"pathfile"] forKey:@"pathfile"];
        if ([attributeDict objectForKey:@"pathSubtitle"])
            [_dicoInfo setObject:[attributeDict objectForKey:@"pathSubtitle"] forKey:@"pathSubtitle"];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (([elementName isEqualToString:@"Media"] || [elementName isEqualToString:@"MediaContainer"]) && [_dicoInfo count] > 0) {
        [_containerInfo addObject:_dicoInfo];
        _dicoInfo = [[NSMutableDictionary alloc] init];
    }
}

@end
