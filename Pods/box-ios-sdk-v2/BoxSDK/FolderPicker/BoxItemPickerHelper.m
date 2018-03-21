//
//  BoxItemPickerHelper.m
//  BoxSDK
//
//  Created on 5/1/13.
//  Copyright (c) 2013 Box Inc. All rights reserved.
//

#import <BoxSDK/BoxItemPickerHelper.h>
#import <BoxSDK/BoxSDK.h>
#import <BoxSDK/BoxLog.h>
#import <BoxSDK/BoxItem+BoxAdditions.h>

#define B0X_FAILED_OPERATION_MODEL (@"failedOperationModel")
#define B0X_FAILED_OPERATION_REFRESHED_BLOCK (@"failedOperationRefreshedBlock")
#define B0X_FAILED_OPERATION_CACHE_PATH (@"failedOperationCachePath")

#define B0X_IS_RETINA ([UIScreen mainScreen].scale == 2.0)

@interface BoxItemPickerHelper () 

@property (nonatomic, readwrite, strong) NSMutableDictionary *datesStringsCache;
@property (nonatomic, readwrite, strong) NSMutableDictionary *currentOperations;

// Dictionnary only used when the user does not want to store thumbnails on the hard drive, in order no to request several times a thumbnail.
@property (nonatomic, readwrite, strong) NSMutableDictionary *inMemoryCache;
@property (nonatomic, readwrite, strong) NSMutableArray *failedOperationsArguments;

@end

@implementation BoxItemPickerHelper

@synthesize SDK = _SDK;

@synthesize datesStringsCache = _datesStringsCache;
@synthesize currentOperations = _currentOperations;

@synthesize inMemoryCache = _inMemoryCache;
@synthesize failedOperationsArguments = _failedOperationsArguments;

- (id)initWithSDK:(BoxSDK *)SDK
{
    self = [super init];
    if (self != nil)
    {
        _SDK = SDK;
        _datesStringsCache = [NSMutableDictionary dictionary];
        _currentOperations = [NSMutableDictionary dictionary];
        _failedOperationsArguments = [NSMutableArray array];
        _inMemoryCache = [NSMutableDictionary dictionary];
    }

    return self;
}

#pragma mark - Helper Methods


- (NSString *)dateStringForItem:(BoxItem *)item
{
    // Caching the dates string to avoid performance drop while formatting dates.
    NSString *dateString = [self.datesStringsCache objectForKey:item.modelID];
    if (dateString == nil)
    {
        dateString = [NSDateFormatter localizedStringFromDate:item.modifiedAt
                                                    dateStyle:NSDateFormatterShortStyle
                                                    timeStyle:NSDateFormatterShortStyle];
        [self.datesStringsCache setObject:dateString forKey:item.modelID];
    }
    
    return dateString;    
}

- (BOOL)shouldDiplayThumbnailForItem:(BoxItem *)item
{
    NSString *extension = [item.name pathExtension];
    
    return [extension isEqualToString:@"png"] || [extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"] || [extension isEqualToString:@"JPG"]; 
}

- (void)itemNeedsAPICall:(BoxItem *)item cachePath:(NSString *)cachePath completion:(BoxNeedsAPICallCompletionBlock)completionBlock
{
    BOOL needsAPIcall = YES;
    UIImage *image = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        needsAPIcall = NO;
        image = [UIImage imageWithContentsOfFile:cachePath];
        completionBlock (needsAPIcall, image);
    }
    else {
        image = [self inMemoryCachedThumbnailForItem:item];
        if (image) {
            needsAPIcall = NO;
            completionBlock(needsAPIcall, image);
        }
        else {
            if ([item isKindOfClass:[BoxFolder class]])
            {
                needsAPIcall = NO;
            }
            completionBlock(needsAPIcall, [item icon]);
        }
    }
}

#pragma mark - Thumbnail Caching Management

- (void)thumbnailForItem:(BoxItem *)item
               cachePath:(NSString *)cachePath
               refreshed:(BoxThumbnailDownloadBlock)refreshed
{
    BOXAssert([item isKindOfClass:[BoxFile class]], @"We only fetch thumbnails for files, not folders.");
    
    __block UIImage *cachedThumbnail = [self cachedThumbnailForItem:item thumbnailsPath:cachePath];
    
    BOOL thumbnailNeedsDeletion = NO;
    if (cachePath == nil)
    {
        thumbnailNeedsDeletion = YES;
        //The user has not set a path, we will temporarly store the thumbnails in the Documents folder and delete them right away.
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        cachePath = [documentPaths objectAtIndex:0];
    }
    
    NSString *path = [cachePath stringByAppendingPathComponent:item.modelID];
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    BoxDownloadSuccessBlock successBlock = ^(NSString *downloadedFileID, long long expectedContentLength)
    {
        [self.currentOperations removeObjectForKey:downloadedFileID];
        NSError *error;
        NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
        
        //If an error occured, just keep the local thumb
        if (!error)
        {
            cachedThumbnail = [UIImage imageWithData:data];
            
            if (refreshed) {
                refreshed(cachedThumbnail);
            }
            
            if (thumbnailNeedsDeletion)
            {
                // Storing the image in a memory cache that will be cleared once the user dismisses the folder picker.
                [self.inMemoryCache setObject:cachedThumbnail forKey:item.modelID];
                //Deleting the temporary thumbnail on the disk
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
            return ;
        }
    };
    
    
    BoxDownloadFailureBlock infoFailure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
    {
        if ([self.currentOperations.allKeys containsObject:item.modelID])
        {
            [self.currentOperations removeObjectForKey:item.modelID];
        }
        BOXLog(@"error when downloading thumbnail: %@", error);
        
        // 202 HTTP reponse code handling
        if (response.statusCode == 202)
        {
            //Getting the value from the Retry-After header.
            NSTimeInterval retryAfterTimeInterval = [[request valueForHTTPHeaderField:@"Retry-After"] integerValue];
            
            // Wait for the specified delay to be elapsed
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, retryAfterTimeInterval * NSEC_PER_SEC);
            dispatch_after(time, dispatch_get_main_queue(), ^(void){
                
                //the Thumbnail was not ready at the time, we requeue a request to get the thumbnail that should now be generated.
                [self thumbnailForItem:item cachePath:cachePath refreshed:refreshed];
            });
        }
        // Token is invalid or expired.
        else if (response.statusCode == 401)
        {
            // Storing all information needed to rebuild the operation after the token is refreshed
            NSMutableDictionary *dictionnary = [NSMutableDictionary dictionary];
            [dictionnary setObject:item forKey:B0X_FAILED_OPERATION_MODEL];
            [dictionnary setObject:refreshed forKey:B0X_FAILED_OPERATION_REFRESHED_BLOCK];
            [dictionnary setObject:cachePath forKey:B0X_FAILED_OPERATION_CACHE_PATH];
            
            [self.failedOperationsArguments addObject:dictionnary];
        }
    };
    
    BoxThumbnailSize size = B0X_IS_RETINA ? BoxThumbnailSize64 : BoxThumbnailSize32;
    BoxAPIDataOperation *operation  = [self.SDK.filesManager thumbnailForFileWithID:item.modelID outputStream:outputStream thumbnailSize:size success:successBlock failure:infoFailure];
    [self.currentOperations setObject:operation forKey:item.modelID];
}


- (UIImage *)cachedThumbnailForItem:(BoxItem *)item thumbnailsPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *thumbnailPath = [path stringByAppendingPathComponent:item.modelID];
    
    NSData *data = [fileManager contentsAtPath:thumbnailPath];
    
    if (data){
        return [UIImage imageWithData:[fileManager contentsAtPath:thumbnailPath]]; 
    }
    return nil;
}

- (void)cancelThumbnailOperations
{
    NSArray *keys = [self.currentOperations allKeys];
    for (NSString *str in keys) {
        BoxAPIDataOperation *operation = [self.currentOperations objectForKey:str];
        [self.currentOperations removeObjectForKey:str];
        [operation cancel];
    }
}

#pragma mark - purge Management

- (void)purgeInMemoryCache
{
    [self.inMemoryCache removeAllObjects];
}

- (UIImage *)inMemoryCachedThumbnailForItem:(BoxItem *)item
{
    return [self.inMemoryCache objectForKey:item.modelID];
}

#pragma mark - Token Refresh Management

- (void)retryOperationsAfterTokenRefresh
{
    // The token has been refreshed, we can retry the download operations with new credentials.
    
    for (NSDictionary *dict in self.failedOperationsArguments) {
        [self thumbnailForItem:[dict objectForKey:B0X_FAILED_OPERATION_MODEL] 
                     cachePath:[dict objectForKey:B0X_FAILED_OPERATION_CACHE_PATH] 
                     refreshed:[dict objectForKey:B0X_FAILED_OPERATION_REFRESHED_BLOCK]];
    }
    
    [self.failedOperationsArguments removeAllObjects];
}

@end
