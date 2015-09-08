/*****************************************************************************
 * VLCFolderCollectionViewFlowLayout.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFolderCollectionViewFlowLayout.h"
#import <objc/runtime.h>
#import "VLCLibraryViewController.h"

//framrate were motion appears fluent
#define LX_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

static NSString * const kLXScrollingDirectionKey = @"LXScrollingDirection";
static NSString * const kLXCollectionViewKeyPath = @"collectionView";

@interface CADisplayLink (LX_userInfo)
@property (nonatomic, copy) NSDictionary *LX_userInfo;
@end

@implementation CADisplayLink (LX_userInfo)
- (void) setLX_userInfo:(NSDictionary *) LX_userInfo {
    objc_setAssociatedObject(self, "LX_userInfo", LX_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) LX_userInfo {
    return objc_getAssociatedObject(self, "LX_userInfo");
}
@end

@interface UICollectionViewCell (VLCFolderCollectionViewLayout)

- (UIImage *)LX_rasterizedImage;

@end

@implementation UICollectionViewCell (VLCFolderCollectionViewLayout)

- (UIImage *)LX_rasterizedImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface VLCFolderCollectionViewFlowLayout ()
{
    NSIndexPath *_selectedItemIndexPath;
    UIView *_currentView;
    CGPoint _currentViewCenter;
    CGPoint _panTranslationInCollectionView;
    CADisplayLink *_displayLink;
    UIView *_folderView;
    BOOL _didPan;
}

@end

@implementation VLCFolderCollectionViewFlowLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView {
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;

    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }

    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];

    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:_selectedItemIndexPath])
        layoutAttributes.hidden = YES;
}

- (id<VLCFolderCollectionViewDelegateFlowLayout>)delegate {
    return (id<VLCFolderCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

- (void)invalidateLayoutIfNecessary {
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:_currentView.center];
    NSIndexPath *previousIndexPath = _selectedItemIndexPath;

    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        _currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
        [_folderView removeFromSuperview];
        return;
    }

    UICollectionViewCell *cell = [self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:newIndexPath];
    if (!_folderView) {
        _folderView = [[UIView alloc] initWithFrame:cell.frame];
        _folderView.backgroundColor = [UIColor VLCOrangeTintColor];
        _folderView.layer.cornerRadius = 8;
    }
    [self.collectionView insertSubview:_folderView atIndex:0];

    if (!CGPointEqualToPoint(_folderView.center,cell.center))
        _folderView.frame = cell.frame;

    [UIView
     animateWithDuration:0.3
     delay:0.0
     options:UIViewAnimationOptionBeginFromCurrentState
     animations:^{
         _currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
     }
     completion:nil];
}

- (void)invalidatesScrollTimer {
    if (!_displayLink.paused)
        [_displayLink invalidate];
    _displayLink = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
    if (!_displayLink.paused) {
        LXScrollingDirection oldDirection = [_displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];

        if (direction == oldDirection)
            return;
    }

    [self invalidatesScrollTimer];

    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    _displayLink.LX_userInfo = @{ kLXScrollingDirectionKey : @(direction) };

    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Target/Action methods
// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(CADisplayLink *)displayLink {
    LXScrollingDirection direction = (LXScrollingDirection)[displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
    if (direction == LXScrollingDirectionUnknown)
        return;

    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.scrollingSpeed / LX_FRAMES_PER_SECOND);
    CGPoint translation = CGPointZero;

    switch(direction) {
        case LXScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f;

            if ((contentOffset.y + distance) <= minY)
                distance = -contentOffset.y;

            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;

            if ((contentOffset.y + distance) >= maxY)
                distance = maxY - contentOffset.y;

            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionLeft: {

            distance = -distance;
            CGFloat minX = 0.0f;

            if ((contentOffset.x + distance) <= minX)
                distance = -contentOffset.x;

            translation = CGPointMake(distance, 0.0f);
        } break;
        case LXScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;

            if ((contentOffset.x + distance) >= maxX)
                distance = maxX - contentOffset.x;

            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    _currentViewCenter = LXS_CGPointAdd(_currentViewCenter, translation);
    _currentView.center = LXS_CGPointAdd(_currentViewCenter, _panTranslationInCollectionView);
    self.collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    //keeps the controller from dragging while not in editmode
    if (!((VLCLibraryViewController *)self.delegate).isEditing) return;

    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            _selectedItemIndexPath = currentIndexPath;

            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:_selectedItemIndexPath];

            _currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];

            collectionViewCell.highlighted = YES;
            UIImageView *highlightedImageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;

            collectionViewCell.highlighted = NO;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;

            [_currentView addSubview:imageView];
            [_currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:_currentView];

            _currentViewCenter = _currentView.center;

            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 _currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                 highlightedImageView.alpha = 0.0f;
                 imageView.alpha = 1.0f;
             }
             completion:^(BOOL finished) {
                [highlightedImageView removeFromSuperview];
             }];

            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            if (_didPan) return;

            NSIndexPath *currentIndexPath = _selectedItemIndexPath;

            if (currentIndexPath) {
                _selectedItemIndexPath = nil;
                _currentViewCenter = CGPointZero;

                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];

                [UIView
                 animateWithDuration:0.3
                 delay:0.0
                 options:UIViewAnimationOptionBeginFromCurrentState
                 animations:^{
                     _currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                     _currentView.center = layoutAttributes.center;
                 }
                 completion:^(BOOL finished) {

                     [_currentView removeFromSuperview];
                     _currentView = nil;
                     [self invalidateLayout];

                 }];
            }
        } break;

        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            _didPan = YES;
        case UIGestureRecognizerStateChanged: {
            _panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            CGPoint viewCenter = _currentView.center = LXS_CGPointAdd(_currentViewCenter, _panTranslationInCollectionView);
            [self invalidateLayoutIfNecessary];

            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionUp];
                    } else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionDown];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
                case UICollectionViewScrollDirectionHorizontal: {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
                    } else {
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionRight];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
            }
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            _didPan = NO;
            [_folderView removeFromSuperview];
            _folderView = nil;
            NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:_currentView.center];
            NSIndexPath *currentIndexPath = _selectedItemIndexPath;

            if (newIndexPath != nil && ![currentIndexPath isEqual:newIndexPath] && ((VLCLibraryViewController *)self.delegate).isEditing) {
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _currentView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
                    _currentView.center = [self layoutAttributesForItemAtIndexPath:newIndexPath].center;
                } completion:^(BOOL finished) {
                    [self.delegate collectionView:self.collectionView requestToMoveItemAtIndexPath:currentIndexPath intoFolderAtIndexPath:newIndexPath];
                    _selectedItemIndexPath = nil;
                    _currentViewCenter = CGPointZero;
                    [_currentView removeFromSuperview];
                    _currentView = nil;
                }];
            } else if (currentIndexPath) {
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _currentView.center = [self layoutAttributesForItemAtIndexPath:currentIndexPath].center;
                } completion:^(BOOL finished) {
                    _selectedItemIndexPath = nil;
                    _currentViewCenter = CGPointZero;
                    [_currentView removeFromSuperview];
                    _currentView = nil;
                    [self invalidateLayout];
                }];
            }
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewLayout overridden methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];

    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:layoutAttributes];
            } break;
            default: {
                // Do nothing...
            } break;
        }
    }
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];

    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }

    return layoutAttributes;
}
#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (_selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }

    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kLXCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
        }
    }
}
#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

@end
