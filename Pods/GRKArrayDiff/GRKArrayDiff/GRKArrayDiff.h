//
//  GRKArrayDiff.h
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
#import "GRKArrayDiffInfo.h"

typedef NS_ENUM(NSUInteger, GRKArrayDiffType) {
    GRKArrayDiffTypeDeletions,
    GRKArrayDiffTypeInsertions,
    GRKArrayDiffTypeMoves,
    GRKArrayDiffTypeModifications
};

@interface GRKArrayDiff : NSObject

/**
 * A NSSet of `GRKArrayDiffInfo` objects describing the elements which were deleted from the previous array.
 */
@property (nonnull,nonatomic,strong,readonly) NSSet *deletions;
/**
 * A NSSet of `GRKArrayDiffInfo` objects describing the elements which were inserted into the current array.
 */
@property (nonnull,nonatomic,strong,readonly) NSSet *insertions;
/**
 * A NSSet of `GRKArrayDiffInfo` objects describing the elements whose indicies changed in the current array from the previous array, but not as a result of deletions or insertions.
 */
@property (nonnull,nonatomic,strong,readonly) NSSet *moves;
/**
 * A NSSet of `GRKArrayDiffInfo` objects describing the elements whose indicies did not change but whose contents are considered modified.
 */
@property (nonnull,nonatomic,strong,readonly) NSSet *modifications;

/**
 * Create and populate a new instance of a GRKArrayDiff with the given previous and current arrays, and supporting blocks.
 *
 * @param previousArray The previous array.
 * @param currentArray  The current array.
 * @param identityBlock A block which is to provide a unique identifier for a given object in either the previous array or current array. This identifier should be the same for elements in the arrays which are to be considered the same, and different for those elements which are to be considered different from eachother.
 * @param modifiedBlock A block used to determine if a given element is to be considered as modified.
 *
 * @return A newly created instance with all properties populated with the appropriate diff information.
 */
- (nonnull instancetype)initWithPreviousArray:(nullable NSArray *)previousArray currentArray:(nullable NSArray *)currentArray identityBlock:(nullable  NSString * __nullable (^)(id __nonnull obj))identityBlock modifiedBlock:(nullable BOOL(^)(id __nonnull previousObj, id __nonnull currentObj))modifiedBlock;

/**
 * A convenience method to return the diff set by type.
 * This returns the same value as accessing the properties.
 *
 * @param type The `GRKArrayDiffType` whcih specifies the set to return.
 *
 * @return An `NSSet` containing `GRKArrayDiffInfo` objects for the specified type, or `nil` if the `type` was not understood.
 */
- (nullable NSSet *)diffInfoSetForType:(GRKArrayDiffType)type;

/**
 * A convenience method to provide `NSIndexSet`s for the indicies of a specified diff set.
 *
 * @param diffType The diff type for which to create index sets. This can be any of
 * `GRKArrayDiffTypeDeletions`, `GRKArrayDiffTypeInsertions`, `GRKArrayDiffTypeMoves`, or `GRKArrayDiffTypeModifications`,
 * but if `GRKArrayDiffTypeMoves` is specified, the returned index sets will only contain
 * indicies for the current indcies (moved to, not moved from).
 * @param section  The "section" to use for the index set (in UITableView parlance).
 *
 * @return An array of `NSIndexSet` objects representing the indicies of the specified set, in the given section, or `nil` if the `diffType` was not understood.
 */
- (nullable NSArray *)indexPathsForDiffType:(GRKArrayDiffType)diffType withSection:(NSInteger)section;

@end
