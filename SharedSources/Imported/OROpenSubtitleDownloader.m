//
//  ORSubtitleDownloader.m
//  Puttio
//
//  Created by orta therox on 08/12/2012.
//  Copyright (c) 2012 ortatherox.com. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <zlib.h>

#import "OROpenSubtitleDownloader.h"

static NSString *OROpenSubtitleURL  = @"http://api.opensubtitles.org/";
static NSString *OROpenSubtitlePath = @"xml-rpc";

static NSString * const kRequest_GetSubLanguages = @"GetSubLanguages";
static NSString * const kRequest_SearchSubtitles = @"SearchSubtitles";

@interface OROpenSubtitleDownloader(){
    NSString *_authToken;
    NSString *_userAgent;

    NSMutableDictionary *_blockResponses;
}
@end

@implementation OROpenSubtitleDownloader


#pragma mark -
#pragma mark Init

- (OROpenSubtitleDownloader *)init {
    return [self initWithUserAgent:[self generateUserAgent] delegate:nil];
}

- (OROpenSubtitleDownloader *)initWithUserAgent:(NSString *)userAgent {
    return [self initWithUserAgent:userAgent delegate:nil];
}

- (OROpenSubtitleDownloader *)initWithUserAgent:(NSString *)userAgent delegate:(id<OROpenSubtitleDownloaderDelegate>) delegate
{
    self = [super init];
    if (!self) return nil;

    _delegate = delegate;
    _userAgent = userAgent;
    _blockResponses = [NSMutableDictionary dictionary];
    _state = OROpenSubtitleStateLoggingIn;

    if(!_languageString) {
        // one day, for now no.
        _languageString = @"eng";
    }

    [self login];
    return self;
}

#pragma mark -
#pragma mark API

- (void)setLanguageString:(NSString *)languageString {
    if (!languageString) {
        languageString = @"eng";
    }
    _languageString = languageString;
}

- (void)login {
    // Log in in the background.
    XMLRPCRequest *request = [self generateRequest];
    [request setMethod: @"LogIn" withParameters:@[@"", @"" , @"" , _userAgent]];

    // Start up the xmlrpc engine
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
}

- (void)supportedLanguagesList:(void(^)(NSArray *languages, NSError *error))languagesResult
{
    XMLRPCRequest *request = [self generateRequest];

    NSString *currentLocaleCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    NSDictionary *params = @{@"language" : currentLocaleCode};

    [request setMethod:kRequest_GetSubLanguages withParameters:@[params]];

    [_blockResponses setObject:[languagesResult copy] forKey:kRequest_GetSubLanguages];

    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
}

- (void)searchForSubtitlesWithHash:(NSString *)hash andFilesize:(NSNumber *)filesize :(void(^) (NSArray *subtitles, NSError *error))searchResult  {
    XMLRPCRequest *request = [self generateRequest];
    NSDecimalNumber *decimalFilesize = [NSDecimalNumber decimalNumberWithString:filesize.stringValue];

    if (decimalFilesize &&hash && _languageString && _authToken){
        NSDictionary *params = @{
            @"moviebytesize" : decimalFilesize,
            @"moviehash" : hash,
            @"sublanguageid" : _languageString
        };

        [request setMethod:kRequest_SearchSubtitles withParameters:@[_authToken, @[params] ]];

        NSString *searchHashCompleteID  = [NSString stringWithFormat:@"Search%@Complete", hash];
        [_blockResponses setObject:[searchResult copy] forKey:searchHashCompleteID];

        XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
        [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
    }
}

- (void)searchForSubtitlesWithQuery:(NSString *)query :(void(^) (NSArray *subtitles, NSError *error))searchResult
{
    XMLRPCRequest *request = [self generateRequest];

    if (query && _languageString && _authToken)
    {
        NSDictionary *params = @{
                                 @"query" : query,
                                 @"sublanguageid" : _languageString
                                 };

        [request setMethod:kRequest_SearchSubtitles withParameters:@[_authToken, @[params] ]];

        NSString *searchQueryCompleteID  = [NSString stringWithFormat:@"Search%@Complete", query];
        [_blockResponses setObject:[searchResult copy] forKey:searchQueryCompleteID];

        XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
        [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
    }
}


- (void)downloadSubtitlesForResult:(OpenSubtitleSearchResult *)result toPath:(NSString *)path :(void(^)(NSString *path, NSError *error))onResultsFound
{
    // Download the subtitles using the HTTP request method
    // as doing it through XMLRPC was proving unpredictable

    NSURL *dURL = [NSURL URLWithString:result.subtitleDownloadAddress];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSURLRequest *request = [NSURLRequest requestWithURL:dURL];

    BOOL requireUnzipping = [[dURL pathExtension] isEqualToString:@"gz"] || [[dURL pathExtension] isEqualToString:@"zip"];

    __typeof__(self) __weak weakSelf = self;
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request
                                                                     progress:nil
                                                                  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
                                              {
                                                  NSString *suggestedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[response suggestedFilename]];

                                                  return requireUnzipping? [NSURL fileURLWithPath:suggestedPath] : [NSURL fileURLWithPath:path];
                                              }
                                                            completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error)
                                              {
                                                  if(requireUnzipping && !error)
                                                  {
                                                      [weakSelf unzipFileAtPath:[filePath path] toPath:path];

                                                      NSError *rError = nil;
                                                      [[NSFileManager defaultManager] removeItemAtURL:filePath error:&rError];
                                                      if(rError) { NSLog(@"[Warning] Error while removing tmp downloaded zip file: %@", rError); }

                                                      if(onResultsFound) { onResultsFound(path, rError); }
                                                  }
                                                  else if(onResultsFound) { onResultsFound(path, error); }
                                              }];

    [downloadTask resume];
}

#pragma mark -
#pragma mark Utilities

#define ZIP_CHUNK 16384

- (void)unzipFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
    gzFile gZipFileRef = gzopen([fromPath UTF8String], "rb");
    FILE *fileRef = fopen([toPath UTF8String], "w");

    if (fileRef == NULL
        || gZipFileRef == NULL) {
        return;
    }

    unsigned char buffer[ZIP_CHUNK];
    int uncompressedLength;
    while ((uncompressedLength = gzread(gZipFileRef, buffer, ZIP_CHUNK))) {
        if(fwrite(buffer, 1, uncompressedLength, fileRef) != uncompressedLength || ferror(fileRef)) {
            NSLog(@"error writing data");
        }
    }

    fclose(fileRef);
    gzclose(gZipFileRef);
}

- (XMLRPCRequest *)generateRequest {
    NSURL *URL = [NSURL URLWithString: [OROpenSubtitleURL stringByAppendingString:OROpenSubtitlePath]];
    return [[XMLRPCRequest alloc] initWithURL:URL];
}

- (NSString *)generateUserAgent {
    NSString *appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *appName    = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    NSString *osVersion  = [[UIDevice currentDevice] systemVersion];
    NSString *device     = [[UIDevice currentDevice] model];
    return [NSString stringWithFormat:@"%@ v%@ ( %@ - %@ ) ", appName, appVersion, device, osVersion];
#else
    NSString *osVersion  = [[[NSProcessInfo processInfo] operatingSystemVersionString] componentsSeparatedByString:@" "][1];
    return [NSString stringWithFormat:@"%@ v%@ ( Mac OS X %@ ) ", appName, appVersion, osVersion];
#endif
}

#pragma mark -
#pragma mark XMLRPC delegate methods

- (void)request: (XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response {
    // Nothing will work without a valid user agent.
    NSString *status = response.object[@"status"];

    if ([status hasPrefix:@"4"]) {
        APLog(@"%s: status failure %@", __func__, status);
        NSArray *components = [status componentsSeparatedByString:@" "];
        [self request:request didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:[(NSString *)components.firstObject intValue] userInfo:@{@"userinfo" : components}]];
        return;
    }

    // Logged in successfully, let the delegate know
    if ([request.method isEqualToString:@"LogIn"]) {
        _authToken = response.object[@"token"];
        _state = OROpenSubtitleStateLoggedIn;

        if (_delegate && [_delegate respondsToSelector:@selector(openSubtitlerDidLogIn:)]) {
            [_delegate openSubtitlerDidLogIn:self];
        }
    }

    // Languages search
    if([request.method isEqualToString:kRequest_GetSubLanguages])
    {
        NSMutableArray *languages = [NSMutableArray new];

        if ([response.object[@"data"] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dictionary in response.object[@"data"]) {
                [languages addObject:[OpenSubtitleLanguageResult resultFromDictionary:dictionary]];
            }
        }

        void (^resultsBlock)(NSArray *languages, NSError *error) = [_blockResponses objectForKey:kRequest_GetSubLanguages];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            resultsBlock(languages, nil);
        });
    }

    // Searched, convert to objects and pass back
    if ([request.method isEqualToString:kRequest_SearchSubtitles])
    {
        _state = OROpenSubtitleStateDownloading;
        NSMutableArray *searchResults = [NSMutableArray array];

        // When we get 0 results data is an NSNumber with 0
        if ([response.object[@"data"] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dictionary in response.object[@"data"]) {
                [searchResults addObject:[OpenSubtitleSearchResult resultFromDictionary:dictionary]];
            }
        }

        NSString *hash = request.parameters[1][0][@"moviehash"];
        if(!hash) hash = request.parameters[1][0][@"query"];
        NSString *searchHashCompleteID  = [NSString stringWithFormat:@"Search%@Complete", hash];

        void (^resultsBlock)(NSArray *subtitles, NSError *error) = [_blockResponses objectForKey:searchHashCompleteID];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            resultsBlock(searchResults, nil);
        });
    }
}

- (void)request: (XMLRPCRequest *)request didFailWithError: (NSError *)error {
    NSLog(@"%@ - %@", NSStringFromSelector(_cmd), error.localizedDescription);

    // Languages search
    if([request.method isEqualToString:kRequest_GetSubLanguages])
    {
        void (^resultsBlock)(NSArray *languages, NSError *error) = [_blockResponses objectForKey:kRequest_GetSubLanguages];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            resultsBlock(nil, error);
        });
    }

    // Search requests
    if([request.method isEqualToString:kRequest_SearchSubtitles])
    {
        NSString *hash = request.parameters[1][0][@"moviehash"];
        if(!hash) hash = request.parameters[1][0][@"query"];
        NSString *searchHashCompleteID  = [NSString stringWithFormat:@"Search%@Complete", hash];

        void (^resultsBlock)(NSArray *subtitles, NSError *error) = [_blockResponses objectForKey:searchHashCompleteID];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            resultsBlock(nil, error);
        });
    }
}

- (BOOL)request: (XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace {
    return YES;
}

- (void)request: (XMLRPCRequest *)request didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
    NSLog(@"%@ - %@", NSStringFromSelector(_cmd), challenge);
}

- (void)request: (XMLRPCRequest *)request didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
    NSLog(@"%@ - %@", NSStringFromSelector(_cmd), challenge);
}

@end

@implementation OpenSubtitleLanguageResult

+ (OpenSubtitleLanguageResult *)resultFromDictionary:(NSDictionary *)dictionary {
    OpenSubtitleLanguageResult *object = [[OpenSubtitleLanguageResult alloc] init];

    object.subLanguageID         = dictionary[@"SubLanguageID"];
    object.localizedLanguageName = dictionary[@"LanguageName"];
    object.iso639Language        = dictionary[@"ISO639"];

    return object;
}

@end

@implementation OpenSubtitleSearchResult

+ (OpenSubtitleSearchResult *)resultFromDictionary:(NSDictionary *)dictionary {
    OpenSubtitleSearchResult *object = [[OpenSubtitleSearchResult alloc] init];

    object.subtitleID = dictionary[@"IDSubtitleFile"];
    object.imdbID = dictionary[@"IDMovieImdb"];
    object.subtitleLanguage = dictionary[@"SubLanguageID"];
    object.subtitleName = dictionary[@"SubFileName"];
    object.subtitleRating = dictionary[@"SubRating"];
    object.subtitleFormat = dictionary[@"SubFormat"];
    object.imdbID = dictionary[@"IDMovieImdb"];
    object.movieYear = dictionary[@"MovieYear"];
    object.iso639Language = dictionary[@"ISO639"];
    object.subtitleDownloadAddress = dictionary[@"SubDownloadLink"];

    return object;
}

@end
