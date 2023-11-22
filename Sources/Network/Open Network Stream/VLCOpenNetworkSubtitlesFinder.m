/*****************************************************************************
 * VLCOpenNetworkSubtitlesFinder.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOpenNetworkSubtitlesFinder.h"
#import "VLCPlaybackService.h"

@implementation VLCOpenNetworkSubtitlesFinder

+ (void)tryToFindSubtitleOnServerForURL:(NSURL *)url
{
    if (([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self lookupSubtitlesForURL:url];
        });
    }
}

+ (void)lookupSubtitlesForURL:(NSURL *)url
{
    NSCharacterSet *characterFilter = [NSCharacterSet characterSetWithCharactersInString:@"\\.():$"];
    NSString *subtitleFileExtensions = [[kSupportedSubtitleFileExtensions componentsSeparatedByCharactersInSet:characterFilter] componentsJoinedByString:@""];
    NSArray *arraySubtitleFileExtensions = [subtitleFileExtensions componentsSeparatedByString:@"|"];
    NSURL *urlWithoutExtension = [url URLByDeletingPathExtension];
    NSUInteger count = arraySubtitleFileExtensions.count;
    NSURL *matchedURL = nil;

    for (int i = 0; i < count; i++) {
        matchedURL = [urlWithoutExtension URLByAppendingPathExtension:arraySubtitleFileExtensions[i]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:matchedURL];
        request.HTTPMethod = @"HEAD";

        NSURLResponse *response = nil;
        NSError *error = nil;
        [self sendSynchronousRequest:request returningResponse:&response error:&error];
        NSInteger httpStatus = [(NSHTTPURLResponse *)response statusCode];

        if (httpStatus == 200) {
            APLog(@"%s:found matching spu file: %@", __PRETTY_FUNCTION__, matchedURL);
            break;
        }
    }

    if (matchedURL) {
        [[VLCPlaybackService sharedInstance] addSubtitlesToCurrentPlaybackFromURL:matchedURL];
    }
}

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    NSError __block *erreur = NULL;
    NSData __block *data;
    NSURLResponse __block *urlResponse;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable _error) {
        urlResponse = _response;
        erreur = _error;
        data = _data;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    *response = urlResponse;
    *error = erreur;
    return data;
}

@end
