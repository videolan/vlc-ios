//
//  GRKArrayDiffInfo.h
//
//  Created by Levi Brown on June 23, 2015.
//  Copyright (c) 2015-2018 Levi Brown <mailto:levigroker@gmail.com> This work is
//  licensed under the Creative Commons Attribution 4.0 International License. To
//  view a copy of this license, visit https://creativecommons.org/licenses/by/4.0/
//
//  The above attribution and this license must accompany any version of the source
//  code, binary distributable, or derivatives.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, GRKArrayDiffInfoIndexType) {
    GRKArrayDiffInfoIndexTypePrevious,
    GRKArrayDiffInfoIndexTypeCurrent
};

@interface GRKArrayDiffInfo : NSObject

@property (nonatomic,copy,readonly) NSString *identity;
@property (nonatomic,strong,readonly) NSNumber *previousIndex;
@property (nonatomic,strong,readonly) NSNumber *currentIndex;

- (instancetype)initWithIdentity:(NSString *)identity previousIndex:(NSNumber *)previousIndex currentIndex:(NSNumber *)currentIndex;

/**
 * A convenience method for obtaining the property value by enumerated type.
 *
 * @param type The `GRKArrayDiffInfoIndexType` specifying the desired return value.
 *
 * @return The `NSNumber` value associated with the given type.
 */
- (NSNumber *)valueForIndexType:(GRKArrayDiffInfoIndexType)type;

/**
 * A convenience method for creating an `NSIndexPath` object representing the value of the indicated index, in the specified section.
 *
 * @param type    The `GRKArrayDiffInfoIndexType` specifying the desired index.
 * @param section The "section" to use for the index set (in UITableView parlance).
 *
 * @return An `NSIndexPath` representing the indicated index, in the specified section (in UITableView parlance).
 */
- (NSIndexPath *)indexPathForIndexType:(GRKArrayDiffInfoIndexType)type withSection:(NSInteger)section;

- (BOOL)isEqualToArrayDiffInfo:(GRKArrayDiffInfo *)diffInfo;

@end
