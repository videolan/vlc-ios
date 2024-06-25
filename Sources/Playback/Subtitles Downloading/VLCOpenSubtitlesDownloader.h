//
//  VLCSubtitleDownloader.h
//  Puttio
//
//  Created by orta therox on 08/12/2012.
//  Modified by İbrahim Çetin on 19/06/2024.
//  Copyright (c) 2012 ortatherox.com. All rights reserved.
//

@class VLCOpenSubtitlesDownloader, OpenSubtitleSearchResult;

/// VLCOpenSubtitlesDownloader makes it easier to handle downloading and searching
/// for subtitles via the opensubtitles.org API

@interface VLCOpenSubtitlesDownloader : NSObject

/// By using init the object will create it's own user agent based on bundle info
- (instancetype)init;

/// Use a custom user agent
- (instancetype)initWithUserAgent:(NSString *)userAgent;

/// Use a custom user agent and api key
- (instancetype)initWithUserAgent:(NSString *)userAgent apiKey:(NSString *)apiKey NS_DESIGNATED_INITIALIZER;

/// Language string, defaults to "en",
@property (nonatomic, strong) NSString *languageCode;

/// Get the opensubtitles supported language list localized in system's locale
/// @return an array of `OpenSubtitleLanguageResult` instances
- (void)supportedLanguagesList:(void(^)(NSArray *languages, NSError *error))languagesHandler;

/// Search and get a return block with an array of OpenSubtitleSearchResult
- (void)searchForSubtitlesWithHash:(NSString *)hash :(void(^) (NSArray *subtitles, NSError *error))searchHandler;

/// Search with a text query and get a return block with an array of OpenSubtitleSearchResult
- (void)searchForSubtitlesWithQuery:(NSString *)query :(void(^) (NSArray *subtitles, NSError *error))searchHandler;

/// Downloads a subtitle result to a file after being unzipped
- (void)downloadSubtitlesForResult:(OpenSubtitleSearchResult *)result toDirectory:(NSURL *)directory :(void(^)(NSURL *location, NSError *error))completionHandler;
@end


/// A result object for a SRT language search
@interface OpenSubtitleLanguageResult : NSObject

/// ORM wrapper for the results
+ (instancetype)resultFromDictionary:(NSDictionary *)dictionary;

/// The language ID that we get from Open Subtitles
@property (copy) NSString *languageCode;
/// The language's name in it's own language
@property (copy) NSString *languageName;

@end

/// A result for a search for a hash / filesize
@interface OpenSubtitleSearchResult : NSObject

/// Simple ORM solution for getting native objects from JSON
+ (OpenSubtitleSearchResult *)resultFromDictionary:(NSDictionary *)dictionary;

/// The subtitle's file ID
@property (copy) NSNumber *subtitleID;

/// The name of the subtitle, usually the scour who released it
@property (copy) NSString *subtitleName;

/// The subtitle language
@property (copy) NSString *subtitleLanguage;

/// The rating of the subtitles from open subtitles
@property (copy) NSNumber *subtitleRating;

/// The number of votes of the subtitle
@property (copy) NSNumber *subtitleVoteCount;

/// The FPS of the subtitle
@property (copy) NSNumber *subtitleFPS;

/// The subtitle for high-definition movie
@property BOOL subtitleIsHD;

/// Recent download count of the subtitle
@property (copy) NSNumber *subtitleNewDownloadCount;

/// Total download count of the subtitle
@property (copy) NSNumber *subtitleTotalDownloadCount;

/// The date when the subtitle uploaded
@property (copy) NSDate *subtitleUploadDate;

/// The opensubtitles webpage for the subtitle
@property (copy) NSURL *subtitleWebpage;

/// The title of movie or series
@property (copy) NSString *contentTitle;

/// When the media content came out
@property (copy) NSString *contentYear;

/// The imdb ID for the result
@property (copy) NSString *contentImdbID;

/// The content type can be movie or episode
@property (copy) NSString *contentType;


@end
