//
//  VLCSubtitleDownloader.m
//  Puttio
//
//  Created by orta therox on 08/12/2012.
//  Modified by İbrahim Çetin on 19/06/2024.
//  Copyright (c) 2012 ortatherox.com. All rights reserved.
//

#import "VLCOpenSubtitlesDownloader.h"
#import "NSURLSession+sharedMPTCPSession.h"

#define kVLCOpenSubtitlesDownloaderApiKey @""

static NSString * const OROpenSubtitleURL  = @"https://api.opensubtitles.com/api/v1/";

static NSString * const kLanguagesPath = @"infos/languages";
static NSString * const kSubtitlesPath = @"subtitles";
static NSString * const kDownloadPath = @"download";

static NSString * const kDomain = @"org.videolan.vlc-ios.openSubtitlesDownloader";

@interface VLCOpenSubtitlesDownloader () {
    NSURLSession *_session;

    NSString *_userAgent;
    NSString *_apiKey;
}
@end

@implementation VLCOpenSubtitlesDownloader

#pragma mark -
#pragma mark Init

- (instancetype)init {
    return [self initWithUserAgent:[self generateUserAgent] apiKey:kVLCOpenSubtitlesDownloaderApiKey];
}

- (instancetype)initWithUserAgent:(nonnull NSString *)userAgent {
    return [self initWithUserAgent:userAgent apiKey:kVLCOpenSubtitlesDownloaderApiKey];
}

- (instancetype)initWithUserAgent:(nonnull NSString *)userAgent apiKey:(nonnull NSString *)apiKey
{
    self = [super init];
    if (!self) return nil;

    _session = [NSURLSession sharedMPTCPSession];

    _userAgent = userAgent;
    _apiKey = apiKey;

    _languageCode = @"en";

    return self;
}

#pragma mark -
#pragma mark API

- (void)setLanguageCode:(nonnull NSString *)languageCode {
    _languageCode = languageCode;
}

- (void)supportedLanguagesList:(void(^)(NSArray *languages, NSError *error))languagesHandler
{
    // Generate URL and Request to fetch languages
    NSURL *languagesURL = [NSURL URLWithString:[OROpenSubtitleURL stringByAppendingString:kLanguagesPath]];
    NSMutableURLRequest *request = [self generateRequest:languagesURL];

    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                languagesHandler(nil, error);
            });
            return;
        }

        // Check the response
        NSError *responseError;
        [self checkResponse:(NSHTTPURLResponse *)response error:&responseError];
        if (responseError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                languagesHandler(nil, responseError);
            });
            return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

        if (jsonError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                languagesHandler(nil, error);
            });
            return;
        }
        
        NSArray *jsonData = json[@"data"];
        NSMutableArray *languages = [NSMutableArray array];
        for (NSDictionary *result in jsonData) {
            OpenSubtitleLanguageResult *language = [OpenSubtitleLanguageResult resultFromDictionary:result];
            [languages addObject:language];
        }

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"languageName" ascending:YES];
        [languages sortUsingDescriptors:@[sortDescriptor]];

        dispatch_async(dispatch_get_main_queue(), ^{
            languagesHandler(languages, nil);
        });
    }];
    [task resume];
}

- (void)searchForSubtitlesWithHash:(nonnull NSString *)hash :(void(^) (NSArray *subtitles, NSError *error))searchHandler
{
    if (!hash || !_languageCode) { return; }

    // Create parameteres and url
    NSDictionary *params = @{
        @"languages" : _languageCode,
        @"moviehash" : hash,
    };
    NSURL *subtitlesURL = [NSURL URLWithString:[OROpenSubtitleURL stringByAppendingString:kSubtitlesPath]];

    // Generate request with url and its parameters
    NSMutableURLRequest *request = [self generateRequest:subtitlesURL withParameters:params];

    [self searchForSubtitlesWithRequest:request :searchHandler];
}

- (void)searchForSubtitlesWithQuery:(nonnull NSString *)query :(void(^) (NSArray *subtitles, NSError *error))searchHandler
{
    if (!query || !_languageCode) { return; }

    // Create parameteres and url
    NSDictionary *params = @{
        @"languages" : _languageCode,
        @"query" : query
    };
    NSURL *subtitlesURL = [NSURL URLWithString:[OROpenSubtitleURL stringByAppendingString:kSubtitlesPath]];
    
    // Generate request with url and its parameters
    NSMutableURLRequest *request = [self generateRequest:subtitlesURL withParameters:params];

    [self searchForSubtitlesWithRequest:request :searchHandler];
}

/// Private common api to search subtitles from a url request
- (void)searchForSubtitlesWithRequest:(nonnull NSURLRequest *)request :(void(^) (NSArray *subtitles, NSError *error))searchHandler {
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // If any error occured, return
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                searchHandler(nil, error);
            });
            return;
        }

        // Check the response
        NSError *responseError;
        [self checkResponse:(NSHTTPURLResponse *)response error:&responseError];
        if (responseError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                searchHandler(nil, responseError);
            });
            return;
        }

        // Decode json object
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

        // If any error occured while json decoding, return
        if (jsonError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                searchHandler(nil, error);
            });
            return;
        }

        NSArray *results = jsonData[@"data"];
        NSMutableArray *subtitles = [NSMutableArray array];
        for (NSDictionary *result in results) {
            OpenSubtitleSearchResult *subtitle = [OpenSubtitleSearchResult resultFromDictionary:result];
            [subtitles addObject:subtitle];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            searchHandler(subtitles, nil);
        });
    }];
    [task resume];
}

- (void)downloadSubtitlesForResult:(nonnull OpenSubtitleSearchResult *)result toDirectory:(nonnull NSURL *)directory :(void(^)(NSURL *location, NSError *error))completionHandler
{
    // Generate download request
    NSURL *downloadURL = [NSURL URLWithString:[OROpenSubtitleURL stringByAppendingString:kDownloadPath]];
    NSMutableURLRequest *request = [self generateRequest:downloadURL];

    // Make it a POST request and add Accept header
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    // Create request body
    NSDictionary *requestBody = @{
        @"file_id": result.subtitleID
    };

    // Encode request body as json
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&jsonError];

    // If any error occured while encoding, return
    if (jsonError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(nil, jsonError);
        });
        return;
    }

    // Set encoded json data to request body
    [request setHTTPBody:jsonData];

    // Send post request to get subtitle's download url and file name
    [self fetchSubtitleDownloadURL:request :^(NSURL *downloadURL, NSString *fileName, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }

        // Create save location of subtitle
        NSURL *fileURL = [directory URLByAppendingPathComponent:fileName];

        // Download the subtitle from returned download url to fileURL
        [self downloadSubtitle:downloadURL toURL:fileURL :^(NSURL *location, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(nil, error);
                });
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(location, nil);
            });
        }];
    }];
}

- (void)fetchSubtitleDownloadURL:(nonnull NSURLRequest *)request :(void(^)(NSURL *downloadURL, NSString *fileName, NSError *error))completionHandler
{
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Check if an error occured
        if (error) {
            completionHandler(nil, nil, error);
            return;
        }

        // Check the response
        NSError *responseError;
        [self checkResponse:(NSHTTPURLResponse *)response error:&responseError];
        if (responseError) {
            completionHandler(nil, nil, responseError);
            return;
        }

        // Decode json
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

        if (jsonError) {
            completionHandler(nil, nil, error);
            return;
        }

        // Call the handler with subtitle's download url and its file name
        completionHandler([NSURL URLWithString:jsonData[@"link"]], jsonData[@"file_name"], nil);
    }];
    [dataTask resume];
}

- (void)downloadSubtitle:(nonnull NSURL *)subtitleURL toURL:(nonnull NSURL *)fileURL :(void(^)(NSURL *location, NSError *error))completionHandler
{
    // Generate a request from given subtitle's download url
    NSURLRequest *request = [self generateRequest:subtitleURL];

    NSURLSessionDownloadTask *downloadTask = [_session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }

        // Check the response
        NSError *responseError;
        [self checkResponse:(NSHTTPURLResponse *)response error:&responseError];
        if (responseError) {
            completionHandler(nil, responseError);
            return;
        }

        NSError *fileOperationError;

        // Remove file if it is already exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&fileOperationError];
            
            // If any error occured or remove operation didn't success, return
            if (fileOperationError) {
                completionHandler(nil, fileOperationError);
                return;
            }
        }

        // Move the downloaded file to the destination
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&fileOperationError];

        // If any error occured or move operation didn't success, return
        if (fileOperationError) {
            completionHandler(nil, fileOperationError);
            return;
        }

        // Call completionHandler with the file's download location
        completionHandler(fileURL, nil);
    }];
    [downloadTask resume];
}

#pragma mark -
#pragma mark Utilities

- (NSMutableURLRequest *)generateRequest:(nonnull NSURL*)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];

    [request setURL:url];

    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:_apiKey forHTTPHeaderField:@"Api-Key"];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];

    return request;
}

- (NSMutableURLRequest *)generateRequest:(nonnull NSURL *)url withParameters:(nonnull NSDictionary *)params {
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in [params allKeys]) {
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:params[key]];
        [queryItems addObject:item];
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    [components setQueryItems:queryItems];

    return [self generateRequest:[components URL]];
}

- (NSString *)generateUserAgent {
    NSString *appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *appName    = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];

#if TARGET_OS_IPHONE
    NSString *device     = [[UIDevice currentDevice] model];
    NSString *osVersion  = [[UIDevice currentDevice] systemVersion];
    return [NSString stringWithFormat:@"%@ v%@ ( %@ - %@ ) ", appName, appVersion, device, osVersion];
#elif TARGET_OS_OSX
    NSString *osVersion  = [[[NSProcessInfo processInfo] operatingSystemVersionString] componentsSeparatedByString:@" "][1];
    return [NSString stringWithFormat:@"%@ v%@ ( macOS %@ ) ", appName, appVersion, osVersion];
#else
    return [NSString stringWithFormat:@"%@ v%@", appName, appVersion];
#endif
}

/// Returns status code of given response
///
/// If status code is not equal 200 and error pointer provided, puts localized status code message to error.
- (NSInteger)checkResponse:(nonnull NSHTTPURLResponse *)response error:(NSError **)error {
    if (response.statusCode != 200 && error) {
        NSString *localizedStatusCodeMessage = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];

        *error = [
            NSError errorWithDomain:kDomain
                    code:response.statusCode
                    userInfo:@{
                        NSLocalizedDescriptionKey: localizedStatusCodeMessage
                    }
        ];
    }

    return response.statusCode;
}

@end

@implementation OpenSubtitleLanguageResult

+ (instancetype)resultFromDictionary:(NSDictionary *)dictionary {
    OpenSubtitleLanguageResult *object = [[OpenSubtitleLanguageResult alloc] init];

    object.languageCode = dictionary[@"language_code"];
    object.languageName = dictionary[@"language_name"];

    return object;
}

@end

@interface OpenSubtitleSearchResult ()
@property (class, readonly) NSDateFormatter *dateFormatter;
@end

@implementation OpenSubtitleSearchResult

+ (NSDateFormatter *) dateFormatter {
    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];

        // Set the date format
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        // Set the time zone to UTC
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    }

    return dateFormatter;
}

+ (instancetype)resultFromDictionary:(NSDictionary *)dictionary {
    OpenSubtitleSearchResult *object = [[OpenSubtitleSearchResult alloc] init];

    NSDictionary *attributes = dictionary[@"attributes"];

    // Set file id as subtitle id.
    // File id is used to download the subtitle.
    object.subtitleID = attributes[@"files"][0][@"file_id"];

    object.subtitleName = attributes[@"release"];
    object.subtitleLanguage = attributes[@"language"];
    object.subtitleRating = attributes[@"ratings"];
    object.subtitleVoteCount = attributes[@"votes"];
    object.subtitleFPS = attributes[@"fps"];
    object.subtitleIsHD = [(NSNumber*)attributes[@"hd"] boolValue];
    object.subtitleNewDownloadCount = attributes[@"new_download_count"];
    object.subtitleTotalDownloadCount = attributes[@"download_count"];
    object.subtitleUploadDate = [OpenSubtitleSearchResult.dateFormatter dateFromString:attributes[@"upload_date"]];
    object.subtitleWebpage = attributes[@"url"];

    NSDictionary *details = attributes[@"feature_details"];

    object.contentTitle = details[@"title"];
    object.contentYear = details[@"year"];
    object.contentImdbID = details[@"imdb_id"];
    object.contentType = details[@"feature_type"];

    return object;
}

@end
