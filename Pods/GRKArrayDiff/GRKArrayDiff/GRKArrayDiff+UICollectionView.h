//
//  GRKArrayDiff+UICollectionView.h
//
//  Created by Michael Kessler on April 28, 2016.
//  Copyright (c) 2016-2018 Levi Brown <mailto:levigroker@gmail.com> This work is
//  licensed under the Creative Commons Attribution 4.0 International License. To
//  view a copy of this license, visit https://creativecommons.org/licenses/by/4.0/
//  
//  The above attribution and this license must accompany any version of the source
//  code, binary distributable, or derivatives.
//

#import <Foundation/Foundation.h>
#import "GRKArrayDiff.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface GRKArrayDiff (UICollectionView)

#if TARGET_OS_IPHONE

/**
 * Updates a given collection view based on information contained in this GRKArrayDiff.
 *
 * @param collectionView The target collection view to update.
 * @param section        The target section of the collection view.
 * @param completion     A completion block which will be called once the collection view has been updated. This can be `nil`.
 */
- (void)updateCollectionView:(UICollectionView *)collectionView section:(NSInteger)section completion:(void(^)(void))completion;

#endif

@end
