/*****************************************************************************
 * VLCPlexWebAPI.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlexWebAPI.h"
#import "VLCPlexParser.h"
#import "UIDevice+VLC.h"

#define kPlexMediaServerSignIn @"https://plex.tv/users/sign_in.xml"
#define kPlexURLdeviceInfo @"https://plex.tv/devices.xml"

@interface VLCPlexWebAPI ()
{

}
@end

@implementation VLCPlexWebAPI

#pragma mark - Authentification

- (NSArray *)PlexBasicAuthentification:(NSString *)username password:(NSString *)password
{
    NSArray *authToken = nil;
    NSURL *url = [NSURL URLWithString:kPlexMediaServerSignIn];

    NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *authData = [authString dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authBase64 = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];

    NSString *timeString = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:authBase64 forHTTPHeaderField:@"Authorization"];
    [request setValue:timeString forHTTPHeaderField:@"X-Plex-Access-Time"];

    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    authToken = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[NSURL URLWithString:@""]];

    return authToken;
}

- (BOOL)PlexCreateIdentification:(NSString *)username password:(NSString *)password
{
    NSURL *url = [NSURL URLWithString:kPlexMediaServerSignIn];

    NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *authData = [authString dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authBase64 = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];

    NSString *appVersion = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *timeString = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:authBase64 forHTTPHeaderField:@"Authorization"];
    [request setValue:@"iOS" forHTTPHeaderField:@"X-Plex-Platform"];
    [request setValue:[[UIDevice currentDevice] systemVersion] forHTTPHeaderField:@"X-Plex-Platform-Version"];
    [request setValue:@"client" forHTTPHeaderField:@"X-Plex-Provides"];
    [request setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forHTTPHeaderField:@"X-Plex-Client-Identifier"];
    [request setValue:@"PlexVLC" forHTTPHeaderField:@"X-Plex-Product"];
    [request setValue:appVersion forHTTPHeaderField:@"X-Plex-Version"];
    [request setValue:@"VLC for iOS" forHTTPHeaderField:@"X-Plex-Device-Name"];
    [request setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"X-Plex-Device"];
    [request setValue:timeString forHTTPHeaderField:@"X-Plex-Access-Time"];

    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if ([response statusCode] == 201)
        return YES;
    else {
        APLog(@"Plex Create Identification Error : %@", [response allHeaderFields]);
        return NO;
    }
}

- (NSData *)HttpRequestWithCookie:(NSURL *)url cookies:(NSArray *)authToken HTTPMethod:(NSString *)method
{
    NSString *timeString = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:authToken];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:headers];
    [request setValue:timeString forHTTPHeaderField:@"X-Plex-Access-Time"];

    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    // for debug
    //NSString *debugStr = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    //APLog(@"data : %@", debugStr);

    return urlData;
}

- (NSString *)PlexAuthentification:(NSString *)username password:(NSString *)password
{
    NSString *authentification = @"";

    if ((![username isEqualToString:@""]) && (![password isEqualToString:@""])) {
        NSMutableArray *deviceInfo = [[NSMutableArray alloc] init];
        NSString *appVersion = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

        NSArray *authToken = [self PlexBasicAuthentification:username password:password];
        NSData *data = [self PlexDeviceInfo:authToken];

        VLCPlexParser *plexParser = [[VLCPlexParser alloc] init];
        deviceInfo = [plexParser PlexExtractDeviceInfo:data];

        if ((deviceInfo.count == 0) || ((![[[deviceInfo objectAtIndex:0] objectForKey:@"productVersion"] isEqualToString:appVersion]) || (![[[deviceInfo objectAtIndex:0] objectForKey:@"platformVersion"] isEqualToString:[[UIDevice currentDevice] systemVersion]]))) {
            [deviceInfo removeAllObjects];
            [self PlexCreateIdentification:username password:password];
            data = [self PlexDeviceInfo:authToken];
            deviceInfo = [plexParser PlexExtractDeviceInfo:data];
        }

        if (deviceInfo.count != 0)
            authentification = [[NSString stringWithFormat:@"X-Plex-Product=%@&X-Plex-Version=%@&X-Plex-Client-Identifier=%@&X-Plex-Platform=iOS&X-Plex-Platform-Version=%@&X-Plex-Device=%@&X-Plex-Device-Name=%@&X-Plex-Token=%@&X-Plex-Username=%@", [[deviceInfo objectAtIndex:0] objectForKey:@"product"], [[deviceInfo objectAtIndex:0] objectForKey:@"productVersion"], [[deviceInfo objectAtIndex:0] objectForKey:@"clientIdentifier"], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] model], [[deviceInfo objectAtIndex:0] objectForKey:@"name"], [[deviceInfo objectAtIndex:0] objectForKey:@"token"], username] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    }

    return authentification;
}

- (NSString *)urlAuth:(NSString *)url autentification:(NSString *)auth
{
    NSString *key = @"";

    if (![auth isEqualToString:@""]) {
        NSRange isRange = [url rangeOfString:@"?" options:NSCaseInsensitiveSearch];
        if(isRange.location != NSNotFound)
            key = @"&";
        else
            key = @"?";
    }

    return [NSString stringWithFormat:@"%@%@%@", url, key, auth];
}

#pragma mark - Unofficial API

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
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), fileName, [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }

    return FileSubtitlePath;
}

- (NSURL *)CreatePlexStreamingURL:(NSString *)adress port:(NSString *)port videoKey:(NSString *)key username:(NSString *)username deviceInfo:(NSMutableArray *)deviceInfo session:(NSString *)session
{
    /* it starts video transcoding but without sound !!! why ? */

    NSString *authentification = [[NSString stringWithFormat:@"&X-Plex-Product=%@&X-Plex-Version=%@&X-Plex-Client-Identifier=%@&X-Plex-Platform=iOS&X-Plex-Platform-Version=%@&X-Plex-Device=%@&X-Plex-Device-Name=%@&X-Plex-Token=%@&X-Plex-Username=%@", [[deviceInfo objectAtIndex:0] objectForKey:@"product"], [[deviceInfo objectAtIndex:0] objectForKey:@"productVersion"], [[deviceInfo objectAtIndex:0] objectForKey:@"clientIdentifier"], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] model], [[deviceInfo objectAtIndex:0] objectForKey:@"name"], [[deviceInfo objectAtIndex:0] objectForKey:@"token"], username] stringByReplacingOccurrencesOfString:@" " withString:@"+"];

    NSString *unescaped = [NSString stringWithFormat:@"http://127.0.0.1:32400%@", key];
    NSString *escapedString = [unescaped stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];

    NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://%@%@/video/:/transcode/universal/start.m3u8?path=%@&mediaIndex=0&partIndex=0&protocol=hls&offset=0&fastSeek=1&directPlay=0&directStream=1&subtitleSize=100&audioBoost=100&session=%@&subtitles=burn", adress, port, escapedString, session] stringByAppendingString:authentification]];

    return url;
}

- (void)stopSession:(NSString *)adress port:(NSString *)port session:(NSString *)session
{

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/video/:/transcode/universal/stop?session=%@", adress, port, session]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if ([response statusCode] != 200)
        APLog(@"Plex stop Session %@ : %@", session, [response allHeaderFields]);
}

#pragma mark -

- (NSString *)getSession
{
    NSString *session = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    return session;
}

- (NSData *)PlexDeviceInfo:(NSArray *)cookies
{
    NSURL *url = [NSURL URLWithString:kPlexURLdeviceInfo];
    NSData *data = [self HttpRequestWithCookie:url cookies:cookies HTTPMethod:@"GET"];
    return data;
}

@end