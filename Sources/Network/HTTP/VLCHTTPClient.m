/*****************************************************************************
 * VLCHTTPClient.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCHTTPClient.h"

NSString *const VLCHTTPClientErrorDomain = @"VLCHTTPClientErrorDomain";
NSString *const VLCHTTPClientResponseBodyErrorKey = @"VLCHTTPClientResponseBody";

@interface VLCHTTPClient()
{
    NSURLSession *_session;
    NSCharacterSet *_allowedQueryCharacters;
}
@end

@implementation VLCHTTPClient

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    self = [super init];
    if (self) {
        _baseURL = baseURL;
        NSMutableCharacterSet *mutSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [mutSet removeCharactersInString:@":#[]@!$&'()*+,;="];
        _allowedQueryCharacters = mutSet;
        _userAgent = [self defaultUserAgent];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

- (void)dealloc
{
    [_session invalidateAndCancel];
}

- (CGFloat)displayScale
{
#if TARGET_OS_VISION
    return [UITraitCollection currentTraitCollection].displayScale;
#else
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        return [UITraitCollection currentTraitCollection].displayScale;
    }
    return [UIScreen mainScreen].scale;
#endif
}

- (NSString *)defaultUserAgent
{
    NSBundle *bundle = [NSBundle mainBundle];
    UIDevice *device = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"%@/%@ (%@; %@ %@; Scale/%0.2f)",
            [bundle objectForInfoDictionaryKey:@"CFBundleName"],
            [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            device.model,
            device.systemName,
            device.systemVersion,
            [self displayScale]];
}

#pragma mark - convenience methods

- (NSURLSessionDataTask *)GET:(NSString *)path
                   parameters:(NSDictionary *)parameters
                      headers:(NSDictionary<NSString *, NSString *> *)headers
                      success:(VLCHTTPClientSuccessBlock)success
                      failure:(VLCHTTPClientFailureBlock)failure
{
    return [self performRequestWithMethod:@"GET"
                                     path:path
                               parameters:parameters
                                  headers:headers
                                  success:success
                                  failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)path
                    parameters:(NSDictionary *)parameters
                       headers:(NSDictionary<NSString *, NSString *> *)headers
                       success:(VLCHTTPClientSuccessBlock)success
                       failure:(VLCHTTPClientFailureBlock)failure
{
    return [self performRequestWithMethod:@"POST"
                                     path:path
                               parameters:parameters
                                  headers:headers
                                  success:success
                                  failure:failure];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)path
                      parameters:(NSDictionary *)parameters
                         headers:(NSDictionary<NSString *, NSString *> *)headers
                         success:(VLCHTTPClientSuccessBlock)success
                         failure:(VLCHTTPClientFailureBlock)failure
{
    return [self performRequestWithMethod:@"DELETE"
                                     path:path
                               parameters:parameters
                                  headers:headers
                                  success:success
                                  failure:failure];
}

#pragma mark - parameter encoding

- (NSString *)escapedString:(NSString *)string
{
    return [string stringByAddingPercentEncodingWithAllowedCharacters:_allowedQueryCharacters];
}

- (void)appendPairs:(NSMutableArray *)pairs forKey:(NSString *)key value:(id)value
{
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSArray *sortedKeys = [[value allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *nestedKey in sortedKeys) {
            NSString *nestedPath = key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey;
            [self appendPairs:pairs forKey:nestedPath value:value[nestedKey]];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSString *nestedPath = [key stringByAppendingString:@"[]"];
        for (id nestedValue in value) {
            [self appendPairs:pairs forKey:nestedPath value:nestedValue];
        }
    } else if (value == nil || value == [NSNull null]) {
        [pairs addObject:[self escapedString:key]];
    } else {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@",
                          [self escapedString:key],
                          [self escapedString:[value description]]]];
    }
}

- (NSString *)encodedStringForParameters:(NSDictionary *)parameters
{
    NSMutableArray *pairs = [NSMutableArray array];
    [self appendPairs:pairs forKey:nil value:parameters];
    return [pairs componentsJoinedByString:@"&"];
}

#pragma mark - request handling

- (NSURLSessionDataTask *)performRequestWithMethod:(NSString *)method
                                              path:(NSString *)path
                                        parameters:(NSDictionary *)parameters
                                           headers:(NSDictionary<NSString *, NSString *> *)headers
                                           success:(VLCHTTPClientSuccessBlock)success
                                           failure:(VLCHTTPClientFailureBlock)failure
{
    NSString *encodedParameters = parameters.count > 0 ? [self encodedStringForParameters:parameters] : nil;
    BOOL carriesBody = [method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"PATCH"];

    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:path relativeToURL:_baseURL]
                                            resolvingAgainstBaseURL:YES];
    if (encodedParameters && !carriesBody) {
        NSString *existingQuery = components.percentEncodedQuery;
        components.percentEncodedQuery = existingQuery.length > 0 ? [existingQuery stringByAppendingFormat:@"&%@", encodedParameters] : encodedParameters;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.HTTPMethod = method;
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    if (carriesBody) {
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [encodedParameters dataUsingEncoding:NSUTF8StringEncoding];
    }
    for (NSString *field in headers) {
        [request setValue:headers[field] forHTTPHeaderField:field];
    }

    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *jsonResponse = nil;
        if (data.length > 0) {
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                jsonResponse = parsed;
            }
        }

        NSError *resultError = error;
        if (!resultError) {
            NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
            if (statusCode < 200 || statusCode > 299) {
                resultError = [self errorForStatusCode:statusCode body:jsonResponse];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (resultError) {
                if (failure) {
                    failure(resultError);
                }
            } else if (success) {
                success(jsonResponse ? jsonResponse : @{});
            }
        });
    }];
    [task resume];
    return task;
}

- (NSError *)errorForStatusCode:(NSInteger)statusCode body:(NSDictionary *)body
{
    NSString *message;
    NSDictionary *errorDict = body[@"error"];
    if ([errorDict isKindOfClass:[NSDictionary class]]) {
        message = errorDict[@"message"];
    }
    if (![message isKindOfClass:[NSString class]]) {
        message = body[@"message"];
    }
    if (![message isKindOfClass:[NSString class]]) {
        message = body[@"description"];
    }
    if (![message isKindOfClass:[NSString class]]) {
        message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    if (body) {
        userInfo[VLCHTTPClientResponseBodyErrorKey] = body;
    }
    return [NSError errorWithDomain:VLCHTTPClientErrorDomain code:statusCode userInfo:userInfo];
}

@end
