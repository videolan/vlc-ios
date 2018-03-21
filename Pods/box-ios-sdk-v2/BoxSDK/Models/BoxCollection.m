//
//  BoxCollection.m
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxCollection.h"

#import "BoxModel.h"
#import "BoxFile.h"
#import "BoxFolder.h"
#import "BoxWebLink.h"
#import "BoxUser.h"

#import "BoxLog.h"
#import "BoxSDKConstants.h"

@interface BoxCollection ()

@property (nonatomic, readwrite, strong) NSArray *entriesArray;

- (BoxModel *)modelInstanceFromEntry:(NSDictionary *)entry;

@end

@implementation BoxCollection

@synthesize entriesArray = _entriesArray;

- (id)initWithResponseJSON:(NSDictionary *)responseJSON mini:(BOOL)mini
{
    self = [super initWithResponseJSON:responseJSON mini:mini];
    if (self != nil)
    {
        id entries = [self.rawResponseJSON objectForKey:BoxAPICollectionKeyEntries];
        if (entries == nil)
        {
            _entriesArray = nil;
        }
        else if (![entries isKindOfClass:[NSArray class]])
        {
            BOXAssertFail(@"entries should be an array");
            _entriesArray = nil;
        }
        else
        {
            _entriesArray = [NSArray arrayWithArray:(NSArray *)entries];
        }
    }

    return self;
}

- (NSNumber *)totalCount
{
    id totalCount = [self.rawResponseJSON valueForKey:BoxAPICollectionKeyTotalCount];
    if (totalCount == nil)
    {
        return nil;
    }
    return [NSNumber numberWithDouble:[totalCount doubleValue]];
}

- (NSUInteger)numberOfEntries
{
    return self.entriesArray.count;
}

- (BoxModel *)modelAtIndex:(NSUInteger)index
{
    if (index >= self.numberOfEntries)
    {
        return nil;
    }

    id entry = [self.entriesArray objectAtIndex:index];
    if (entry == nil)
    {
        return nil;
    }
    else if (![entry isKindOfClass:[NSDictionary class]])
    {
        BOXAssertFail(@"collection entry should be a dictionary");
        return nil;
    }

    return [self modelInstanceFromEntry:entry];
}

- (BoxModel *)modelInstanceFromEntry:(NSDictionary *)entry
{
    id type = [entry objectForKey:BoxAPIObjectKeyType];
    if ([BoxAPIItemTypeFile isEqual:type])
    {
        return [[BoxFile alloc] initWithResponseJSON:entry mini:YES];
    }
    else if ([BoxAPIItemTypeFolder isEqual:type])
    {
        return [[BoxFolder alloc] initWithResponseJSON:entry mini:YES];
    }
    else if ([BoxAPIItemTypeWebLink isEqual:type])
    {
        return [[BoxWebLink alloc] initWithResponseJSON:entry mini:YES];
    }
    else if ([BoxAPIItemTypeUser isEqual:type])
    {
        return [[BoxUser alloc] initWithResponseJSON:entry mini:NO];
    }
    else
    {
        return [[BoxModel alloc] initWithResponseJSON:entry mini:YES];
    }
}

@end
