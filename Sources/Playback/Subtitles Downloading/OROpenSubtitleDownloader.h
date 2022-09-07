//
//  ORSubtitleDownloader.h
//  Puttio
//
//  Created by orta therox on 08/12/2012.
//  Copyright (c) 2012 ortatherox.com. All rights reserved.
//

#import <xmlrpc/XMLRPC.h>

@class OROpenSubtitleDownloader, OpenSubtitleSearchResult;

typedef enum {
    OROpenSubtitleStateLoggingIn,
    OROpenSubtitleStateLoggedIn,
    OROpenSubtitleStateSearching,
    OROpenSubtitleStateDownloading,
    OROpenSubtitleStateDownloaded
} OROpenSubtitleState;

/// Simple authentication delegate callback protocol

@protocol OROpenSubtitleDownloaderDelegate <NSObject>
@optional
/// Called when the subtitler has logged in via XMLRPC
- (void)openSubtitlerDidLogIn:(OROpenSubtitleDownloader *)downloader;

@end

/// OROpenSubtitleDownloader makes it easier to handle downloading and searching
/// for subtitles via the opensubtitles.org API

@interface OROpenSubtitleDownloader : NSObject <XMLRPCConnectionDelegate>

/// By using init the object will create it's own user agent based on bundle info
- (OROpenSubtitleDownloader *)init;

/// Use a custom user agent
- (OROpenSubtitleDownloader *)initWithUserAgent:(NSString *)userAgent;

/// Use a custom user agent
- (OROpenSubtitleDownloader *)initWithUserAgent:(NSString *)userAgent delegate:(id<OROpenSubtitleDownloaderDelegate>) delegate NS_DESIGNATED_INITIALIZER;

/// The object that recieves notifications for new subtitles
@property (nonatomic, weak) NSObject <OROpenSubtitleDownloaderDelegate> *delegate;

/// Internal state of subtitle downloader
@property (nonatomic, readonly) OROpenSubtitleState state;

/// Language string, defaults to "eng",
/// See: http://www.opensubtitles.org/addons/export_languages.php for full list
@property (nonatomic, strong) NSString *languageString;

/// Get the opensubtitles supported language list localized in system's locale
/// @return an array of `OpenSubtitleLanguageResult` instances
- (void)supportedLanguagesList:(void(^)(NSArray *languages, NSError *error))languagesResult;

/// Search and get a return block with an array of OpenSubtitleSearchResult
- (void)searchForSubtitlesWithHash:(NSString *)hash andFilesize:(NSNumber *)filesize :(void(^) (NSArray *subtitles, NSError *error))searchResult;

/// Search with a text query and get a return block with an array of OpenSubtitleSearchResult
- (void)searchForSubtitlesWithQuery:(NSString *)query :(void(^) (NSArray *subtitles, NSError *error))searchResult;

/// Downloads a subtitle result to a file after being unzipped
- (void)downloadSubtitlesForResult:(OpenSubtitleSearchResult *)result toPath:(NSString *)path :(void(^)(NSString *path, NSError *error))onResultsFound;
@end


/// A result object for a SRT language search
@interface OpenSubtitleLanguageResult : NSObject

/// ORM wrapper for the results
+ (OpenSubtitleLanguageResult *)resultFromDictionary:(NSDictionary *)dictionary;

/// The language ID that we get from Open Subtitles
@property (copy) NSString *subLanguageID;
/// The language's name in it's own language
@property (copy) NSString *localizedLanguageName;
/// The ISO639 formatted id
@property (copy) NSString *iso639Language;

@end

/// A result for a search for a hash / filesize
@interface OpenSubtitleSearchResult : NSObject

/// Simple ORM solution for getting native objects from JSON
+ (OpenSubtitleSearchResult *)resultFromDictionary:(NSDictionary *)dictionary;

/// The Open Subtitles ID for the result
@property (copy) NSString *subtitleID;

/// The imdb ID for the result
@property (copy) NSString *imdbID;

/// The subtitle language in English ( I think )
@property (copy) NSString *subtitleLanguage;

/// The name of the subtitle, usually the scour who released it
@property (copy) NSString *subtitleName;

/// The rating of the subtitles from open subtitles
@property (copy) NSString *subtitleRating;

/// The file format of the subtitles
@property (copy) NSString *subtitleFormat;

/// When the media content came out
@property (copy) NSString *movieYear;

/// The standard for the language
@property (copy) NSString *iso639Language;

/// The download address accesible via HTTP
@property (copy) NSString *subtitleDownloadAddress;

@end
