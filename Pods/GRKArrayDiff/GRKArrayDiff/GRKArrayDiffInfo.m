//
//  GRKArrayDiffInfo.m
//
//  Created by Levi Brown on June 23, 2015.
//  Copyright (c) 2015-2018 Levi Brown <mailto:levigroker@gmail.com> This work is
//  licensed under the Creative Commons Attribution 4.0 International License. To
//  view a copy of this license, visit https://creativecommons.org/licenses/by/4.0/
//
//  The above attribution and this license must accompany any version of the source
//  code, binary distributable, or derivatives.
//

#import "GRKArrayDiffInfo.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

@implementation GRKArrayDiffInfo

#pragma mark - Lifecycle

- (instancetype)initWithIdentity:(NSString *)identity previousIndex:(NSNumber *)previousIndex currentIndex:(NSNumber *)currentIndex
{
    if ((self = [super init]))
    {
        _identity = [identity copy];
        _previousIndex = previousIndex;
        _currentIndex = currentIndex;
    }
    
    return self;
}

#pragma mark - Implementation

- (NSNumber *)valueForIndexType:(GRKArrayDiffInfoIndexType)type
{
    NSNumber *retVal = nil;
    
    switch (type) {
        case GRKArrayDiffInfoIndexTypePrevious:
            retVal = self.previousIndex;
            break;
        case GRKArrayDiffInfoIndexTypeCurrent:
            retVal = self.currentIndex;
            break;
        default:
            NSLog(@"[ERROR] GRKArrayDiffInfo: Unhandled case (%d) for `valueForIndexType:`", (int)type);
            break;
    }
    
    return retVal;
}

- (NSIndexPath *)indexPathForIndexType:(GRKArrayDiffInfoIndexType)type withSection:(NSInteger)section;
{
    NSIndexPath *retVal = nil;
    
    NSNumber *index = [self valueForIndexType:type];
    
    if (index != nil)
    {
        NSUInteger indicies[] = {section, index.integerValue};
        retVal = [NSIndexPath indexPathWithIndexes:indicies length:2];
    }
    
    return retVal;
}

- (BOOL)isEqualToArrayDiffInfo:(GRKArrayDiffInfo *)diffInfo
{
    BOOL retVal = NO;
    
    if ([diffInfo isKindOfClass:GRKArrayDiffInfo.class])
    {
        NSUInteger ourHash = self.hash;
        NSUInteger theirHash = diffInfo.hash;
        retVal = ourHash == theirHash;
    }
    
    return retVal;
}

#pragma mark - Overrides

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, identity '%@', previousIndex '%@', currentIndex '%@'>", NSStringFromClass([self class]), self, self.identity, self.previousIndex, self.currentIndex];
}

- (NSUInteger)hash
{
    __block NSUInteger contributionCount = 0;
    __block NSUInteger builtHash = 0;
    
    void(^buildHash)(id obj) = ^(id obj) {
        NSUInteger hash = [obj hash];
        if (hash == 0)
        {
            //Account for nil values as well.
            hash = 31;
        }
        
        if (builtHash == 0)
        {
            builtHash = hash;
            contributionCount = 1;
        }
        else
        {
            ++contributionCount;
            builtHash = NSUINTROTATE(hash, NSUINT_BIT / contributionCount) ^ builtHash;
        }
    };
    
    buildHash(self.identity);
    buildHash(self.previousIndex);
    buildHash(self.currentIndex);
    
    return builtHash;
}

- (BOOL)isEqual:(id)object
{
    BOOL retVal = [self isEqualToArrayDiffInfo:object];
    return retVal;
}

@end
