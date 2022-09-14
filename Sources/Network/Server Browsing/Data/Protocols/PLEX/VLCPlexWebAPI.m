/*****************************************************************************
 * VLCPlexWebAPI.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2019 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlexWebAPI.h"
#import "VLCPlexParser.h"
#import "VLC-Swift.h"
#import "sysexits.h"

#define kPlexMediaServerSignIn @"https://plex.tv/users/sign_in.xml"
//#define kPlexMediaServerSignIn @"https://plex.tv/users/sign_in.json"
#define kPlexURLdeviceInfo @"https://plex.tv/devices.xml"

@implementation VLCPlexWebAPI

#pragma mark - Authentification

- (NSMutableDictionary *)PlexBasicAuthentification:(NSString *)username password:(NSString *)password
{
    NSURL *url = [NSURL URLWithString:kPlexMediaServerSignIn];

    NSString *appVersion = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

    NSMutableDictionary *authDict = [NSMutableDictionary dictionary];
    NSString *clientIdentifier = [NSString stringWithFormat:@"PlexVLC-%@", [[UIDevice currentDevice] model]];
    [authDict setObject:clientIdentifier forKey:@"clientIdentifier"];
    [authDict setObject:@"PlexVLC" forKey:@"product"];
    [authDict setObject:appVersion forKey:@"productVersion"];
    [authDict setObject:[[UIDevice currentDevice] model] forKey:@"device"];
    [authDict setObject:@"" forKey:@"token"];
    [authDict setObject:@"VLC for iOS" forKey:@"name"];
    [authDict setObject:username forKey:@"username"];

    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
    if ([cookies count]) {
        for (NSHTTPCookie *cookie in cookies) {
            if ([cookie.name isEqualToString:@"plexToken"]) {
                [authDict setObject:cookie.value forKey:@"token"];
                return authDict;
            }
        }
    }

    NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *authData = [authString dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authBase64 = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];

    NSString *timeString = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:authBase64 forHTTPHeaderField:@"Authorization"];
    [request setValue:[authDict objectForKey:@"device"] forHTTPHeaderField:@"X-Plex-Device"];
    [request setValue:[authDict objectForKey:@"name"] forHTTPHeaderField:@"X-Plex-Device-Name"];
    [request setValue:[authDict objectForKey:@"clientIdentifier"] forHTTPHeaderField:@"X-Plex-Client-Identifier"];
    [request setValue:[authDict objectForKey:@"product"] forHTTPHeaderField:@"X-Plex-Product"];
    [request setValue:appVersion forHTTPHeaderField:@"X-Plex-Version"];
    [request setValue:timeString forHTTPHeaderField:@"X-Plex-Access-Time"];

    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [self sendSynchronousRequest:request returningResponse:&response error:&error];
    // for debug
    /*if ([response statusCode] == 201) {
        NSLog(@"Plex token : %@", [response allHeaderFields]);
        NSLog(@"Plex token : %@", [NSString stringWithUTF8String:[data bytes]]);
    } else {
        NSLog(@"%ld", (long)response.statusCode);
        NSLog(@"Plex Create Identification Error : %@", [response allHeaderFields]);
        NSLog(@"Plex token error : %@", [NSString stringWithUTF8String:[data bytes]]);
    }*/

    VLCPlexParser *plexParser = [[VLCPlexParser alloc] init];
    NSString *token = [plexParser PlexExtractToken:data];
    if (![token isEqualToString:@""]) {
        [authDict setObject:token forKey:@"token"];
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        [cookieProperties setObject:@"plexToken" forKey:NSHTTPCookieName];
        [cookieProperties setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:@"plex.tv" forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:kPlexMediaServerSignIn forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:token forKey:NSHTTPCookieValue];

        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }

    return authDict;
}

- (NSString *)PlexAuthentification:(NSString *)username password:(NSString *)password
{
    NSString *authentification = @"";

    if ((![username isEqualToString:@""]) && (![password isEqualToString:@""])) {

        NSDictionary *authDict = [self PlexBasicAuthentification:username password:password];

        if (![[authDict objectForKey:@"token"] isEqualToString:@""]) {
            authentification = [[NSString stringWithFormat:@"X-Plex-Product=%@&X-Plex-Version=%@&X-Plex-Client-Identifier=%@&X-Plex-Device=%@&X-Plex-Token=%@&X-Plex-Username=%@",
                                 [authDict objectForKey:@"product"],
                                 [authDict objectForKey:@"productVersion"],
                                 [authDict objectForKey:@"clientIdentifier"],
                                 [authDict objectForKey:@"device"],
                                 [authDict objectForKey:@"token"], username]
                                stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        }
    }

    return authentification;
}

- (NSString *)urlAuth:(NSString *)url authentification:(NSString *)auth 
{
    return [[self class] urlAuth:url authentification:auth];
}

+ (NSString *)urlAuth:(NSString *)url authentification:(NSString *)auth
{
    NSString *key = @"";

    if ((![auth isEqualToString:@""]) && (auth)) {
        NSRange isRange = [url rangeOfString:@"?" options:NSCaseInsensitiveSearch];
        if(isRange.location != NSNotFound)
            key = @"&";
        else
            key = @"?";
    }

    return [NSString stringWithFormat:@"%@%@%@", url, key, auth];
}

#pragma mark - Unofficial API

- (NSInteger)MarkWatchedUnwatchedMedia:(NSString *)address port:(NSString *)port videoRatingKey:(NSString *)ratingKey state:(NSString *)state authentification:(NSString *)auth
{
    NSString *url = nil;

    if ([state isEqualToString:@"watched"])
        url = [NSString stringWithFormat:@"http://%@%@/:/unscrobble?identifier=com.plexapp.plugins.library&key=%@", address, port, ratingKey];
    else
        url = [NSString stringWithFormat:@"http://%@%@/:/scrobble?identifier=com.plexapp.plugins.library&key=%@", address, port, ratingKey];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[[[VLCPlexWebAPI alloc] init] urlAuth:url authentification:auth]] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [self sendSynchronousRequest:request returningResponse:&response error:&error];

    NSInteger httpStatus = [(NSHTTPURLResponse *)response statusCode];

    if (httpStatus != 200)
        APLog(@"Mark Watched Unwatched Media Error status: %ld at URL : %@", (long)httpStatus, url);

    return httpStatus;
}

- (NSString *)getFileSubtitleFromPlexServer:(NSDictionary *)mediaObject modeStream:(BOOL)modeStream error:(NSError *__autoreleasing *)outError
{
    if (!mediaObject)
        return @"";

    NSString *FileSubtitlePath = nil;
    NSString *fileName = [[mediaObject[@"namefile"] stringByDeletingPathExtension] stringByAppendingPathExtension:mediaObject[@"codecSubtitle"]];

    VLCPlexWebAPI *PlexWebAPI = [[VLCPlexWebAPI alloc] init];
    NSURL *url = [[NSURL alloc] initWithString:[PlexWebAPI urlAuth:mediaObject[@"keySubtitle"] authentification:mediaObject[@"authentification"]]];

    NSData *receivedSub = [NSData dataWithContentsOfURL:url];

    if (receivedSub.length < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
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
        NSString *title = NSLocalizedString(@"DISK_FULL", nil);
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), fileName, [[UIDevice currentDevice] model]];

        if (outError) {
            *outError = [NSError errorWithDomain:@"org.videolan.vlc-ios.plex"
                                            code:EX_CANTCREAT
                                        userInfo:@{NSLocalizedDescriptionKey : title,
                                                   NSLocalizedFailureReasonErrorKey : message
                                                   }];
        }

    }

    return FileSubtitlePath;
}

- (void)stopSession:(NSString *)address port:(NSString *)port session:(NSString *)session
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/video/:/transcode/universal/stop?session=%@", address, port, session]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    [self sendSynchronousRequest:request returningResponse:&response error:&error];

    if ([response statusCode] != 200)
        APLog(@"Plex stop Session %@ : %@", session, [response allHeaderFields]);
}

#pragma mark -

- (NSString *)getSession
{
    NSString *session = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    return session;
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
