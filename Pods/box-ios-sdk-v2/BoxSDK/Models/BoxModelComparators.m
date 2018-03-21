//
//  BoxModelComparators.m
//  BoxSDK
//
//  Created on 8/4/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxModelComparators.h"

#import "BoxLog.h"
#import "BoxModel.h"
#import "BoxItem.h"
#import "BoxFile.h"

@implementation BoxModelComparators

+ (NSComparator)modelByTypeAndID
{
    static NSComparator modelByTypeAndID = nil;
    static dispatch_once_t modelByTypeAndIDPred;
    dispatch_once(&modelByTypeAndIDPred, ^{
        modelByTypeAndID = ^NSComparisonResult (id obj1, id obj2)
        {
            BOXAssert([obj1 isKindOfClass:[BoxModel class]], @"obj1 should be a BoxModel");
            BOXAssert([obj2 isKindOfClass:[BoxModel class]], @"obj2 should be a BoxModel");
            BoxModel *model1 = (BoxModel *)obj1;
            BoxModel *model2 = (BoxModel *)obj2;

            NSComparisonResult comparisonResult = [model1.type compare:model2.type];
            if (comparisonResult == NSOrderedSame)
            {
                comparisonResult = [model1.modelID compare:model2.modelID options:NSNumericSearch];
            }

            return comparisonResult;
        };
    });

    return modelByTypeAndID;
}

+ (NSComparator)itemByName
{
    static NSComparator itemByName = nil;
    static dispatch_once_t itemByNamePred;
    dispatch_once(&itemByNamePred, ^{
        itemByName = ^NSComparisonResult (id obj1, id obj2)
        {
            BOXAssert([obj1 isKindOfClass:[BoxItem class]], @"obj1 should be a BoxItem");
            BOXAssert([obj2 isKindOfClass:[BoxItem class]], @"obj2 should be a BoxItem");
            BoxItem *model1 = (BoxItem *)obj1;
            BoxItem *model2 = (BoxItem *)obj2;

            NSComparisonResult comparisonResult = [model1.name compare:model2.name options:NSNumericSearch];

            return comparisonResult;
        };
    });

    return itemByName;
}

+ (NSComparator)itemByCreatedAt
{
    static NSComparator itemByCreatedAt = nil;
    static dispatch_once_t itemByCreatedAtPred;
    dispatch_once(&itemByCreatedAtPred, ^{
        itemByCreatedAt = ^NSComparisonResult (id obj1, id obj2)
        {
            BOXAssert([obj1 isKindOfClass:[BoxItem class]], @"obj1 should be a BoxItem");
            BOXAssert([obj2 isKindOfClass:[BoxItem class]], @"obj2 should be a BoxItem");
            BoxItem *model1 = (BoxItem *)obj1;
            BoxItem *model2 = (BoxItem *)obj2;

            NSComparisonResult comparisonResult = [model1.createdAt compare:model2.createdAt];

            return comparisonResult;
        };
    });

    return itemByCreatedAt;
}

+ (NSComparator)itemByModifiedAt
{
    static NSComparator itemByModifiedAt = nil;
    static dispatch_once_t itemByModifiedAtPred;
    dispatch_once(&itemByModifiedAtPred, ^{
        itemByModifiedAt = ^NSComparisonResult (id obj1, id obj2)
        {
            BOXAssert([obj1 isKindOfClass:[BoxItem class]], @"obj1 should be a BoxItem");
            BOXAssert([obj2 isKindOfClass:[BoxItem class]], @"obj2 should be a BoxItem");
            BoxItem *model1 = (BoxItem *)obj1;
            BoxItem *model2 = (BoxItem *)obj2;

            NSComparisonResult comparisonResult = [model1.modifiedAt compare:model2.modifiedAt];

            return comparisonResult;
        };
    });

    return itemByModifiedAt;
}

+ (NSComparator)itemBySize
{
    static NSComparator itemBySize = nil;
    static dispatch_once_t itemBySizePred;
    dispatch_once(&itemBySizePred, ^{
        itemBySize = ^NSComparisonResult (id obj1, id obj2)
        {
            BOXAssert([obj1 isKindOfClass:[BoxItem class]], @"obj1 should be a BoxItem");
            BOXAssert([obj2 isKindOfClass:[BoxItem class]], @"obj2 should be a BoxItem");
            BoxItem *model1 = (BoxItem *)obj1;
            BoxItem *model2 = (BoxItem *)obj2;

            NSComparisonResult comparisonResult = [model1.size compare:model2.size];

            return comparisonResult;
        };
    });

    return itemBySize;
}

+ (NSComparator)fileBySHA1
{
    static NSComparator fileBySHA1 = nil;
    static dispatch_once_t fileBySHA1Pred;
    dispatch_once(&fileBySHA1Pred, ^{
        fileBySHA1 = ^NSComparisonResult (id obj1, id obj2)
        {
            BOXAssert([obj1 isKindOfClass:[BoxFile class]], @"obj1 should be a BoxFile");
            BOXAssert([obj2 isKindOfClass:[BoxFile class]], @"obj2 should be a BoxFile");
            BoxFile *model1 = (BoxFile *)obj1;
            BoxFile *model2 = (BoxFile *)obj2;

            NSComparisonResult comparisonResult = [model1.SHA1 compare:model2.SHA1];

            return comparisonResult;
        };
    });

    return fileBySHA1;
}

@end
