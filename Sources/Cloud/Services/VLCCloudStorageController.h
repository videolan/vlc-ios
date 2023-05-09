//
//  VLCCloudStorageController.h
//  VLC for iOS
//
//  Created by Carola Nitz on 31/12/14.
//  Copyright (c) 2014 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, VLCCloudSortingCriteria) {
    VLCCloudSortingCriteriaName,
    VLCCloudSortingCriteriaModifiedDate
};

@protocol VLCCloudStorageDelegate <NSObject>

@required
- (void)mediaListUpdated;

@optional
- (void)operationWithProgressInformationStarted;
- (void)currentProgressInformation:(CGFloat)progress;
- (void)updateRemainingTime:(NSString *)time;
- (void)operationWithProgressInformationStopped;
- (void)numberOfFilesWaitingToBeDownloadedChanged;
- (void)sessionWasUpdated;
- (void)updateCurrentPath:(NSString *)path;
@end

@interface VLCCloudStorageController : NSObject

@property (nonatomic, weak) id<VLCCloudStorageDelegate> delegate;
@property (nonatomic, readwrite) BOOL isAuthorized;
@property (nonatomic, readonly) NSArray *currentListFiles;
@property (nonatomic, readonly) BOOL canPlayAll;
@property (nonatomic, readwrite) VLCCloudSortingCriteria sortBy;


+ (instancetype)sharedInstance;

- (void)startSession;
- (void)logout;
- (void)requestDirectoryListingAtPath:(NSString *)path;
- (BOOL)supportSorting;
- (NSString *)createPotentialPathFrom:(NSString *)path;
- (VLCMedia *)setMediaNameMetadata:(VLCMedia *)media withName:(NSString *)name;

@end
