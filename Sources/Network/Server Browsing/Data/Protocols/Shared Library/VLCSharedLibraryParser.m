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

@interface VLCIndividualLibraryParser : NSObject  <NSXMLParserDelegate>
{
    NSMutableArray *_containerInfo;
    NSMutableDictionary *_dicoInfo;
}

- (NSArray *)downloadAndProcessDataFromServer:(NSString*)hostnamePort;

@end

NSString *const VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance = @"VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance";

@implementation VLCSharedLibraryParser

- (void)checkNetserviceForVLCService:(NSNetService *)aNetService
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *hostnamePort = [NSString stringWithFormat:@"%@:%ld", [aNetService hostName], (long)[aNetService port]];
        VLCIndividualLibraryParser *libraryParser = [[VLCIndividualLibraryParser alloc] init];
        NSArray *parsedContents = [libraryParser downloadAndProcessDataFromServer:hostnamePort];

        if (parsedContents.count > 0) {
            id firstObject = parsedContents.firstObject;
            if ([firstObject isKindOfClass:[NSDictionary class]]) {
                if ([[firstObject objectForKey:@"identifier"] isEqualToString:@"org.videolan.vlc-ios"]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance
                                                                        object:self
                                                                      userInfo:@{@"aNetService" : aNetService}];
                }
            }
        }
    });
}

- (void)fetchDataFromServer:(NSString *)hostname port:(long)port
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *hostnamePort = [NSString stringWithFormat:@"%@:%ld", hostname, port];
        VLCIndividualLibraryParser *libraryParser = [[VLCIndividualLibraryParser alloc] init];
        NSArray *parsedContents = [libraryParser downloadAndProcessDataFromServer:hostnamePort];

        __weak typeof(self) weakSelf = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            id delegate = weakSelf.delegate;
            if ([delegate respondsToSelector:@selector(sharedLibraryDataProcessings:)]) {
                [delegate sharedLibraryDataProcessings:parsedContents];
            }
        }];
    });
}

@end

@implementation VLCIndividualLibraryParser

- (NSArray *)downloadAndProcessDataFromServer:(NSString *)hostnamePort
{
    _containerInfo = [[NSMutableArray alloc] init];
    _dicoInfo = [[NSMutableDictionary alloc] init];
    NSString *serverURL = [NSString stringWithFormat:@"http://%@/%@", hostnamePort, kLibraryXmlFile];

    NSURL *url = [[NSURL alloc] initWithString:serverURL];
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [xmlparser setDelegate:self];

    if (![xmlparser parse]) {
        APLog(@"VLC Library parsing failed for %@ with error %@", url, xmlparser.parserError);
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
        if ([attributeDict objectForKey:@"title"]) {
            NSString *encodedTitle = [attributeDict objectForKey:@"title"];
            NSString *title = [encodedTitle stringByRemovingPercentEncoding];
            [_dicoInfo setObject:title forKey:@"title"];
        }
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
