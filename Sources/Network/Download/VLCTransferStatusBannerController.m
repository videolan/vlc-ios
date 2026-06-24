/*****************************************************************************
 * VLCTransferStatusBannerController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTransferStatusBannerController.h"
#import "VLCDownloadStatusBanner.h"
#import "VLCTransferController.h"
#import "VLCTransferItem.h"
#import "VLCAppCoordinator.h"

@interface VLCTransferStatusBannerController ()
{
    __weak UIView *_containerView;
    __weak id<VLCTransferStatusBannerControllerDelegate> _delegate;

    VLCDownloadStatusBanner *_banner;
    NSLayoutConstraint *_bottomConstraint;
    BOOL _hideScheduled;
}
@end

@implementation VLCTransferStatusBannerController

- (instancetype)initWithContainerView:(UIView *)containerView
                             delegate:(id<VLCTransferStatusBannerControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _containerView = containerView;
        _delegate = delegate;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(transferStateDidChange:)
                                   name:VLCTransferControllerStateDidChangeNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(themeDidChange:)
                                   name:kVLCThemeDidChangeNotification
                                 object:nil];
    }
    return self;
}

- (void)transferStateDidChange:(NSNotification *)notification
{
    [self _updateBanner];
}

- (void)themeDidChange:(NSNotification *)notification
{
    [_banner applyTheme];
}

- (void)_updateBanner
{
    VLCTransferController *tc = [[VLCAppCoordinator sharedInstance] transferController];
    NSArray<VLCTransferItem *> *items = tc.inProgressItems;
    NSUInteger totalCount = items.count;

    if (totalCount == 0) {
        [self _scheduleHide];
        return;
    }
    _hideScheduled = NO;
    [self _ensureBannerInstalled];

    long long received = 0, expected = 0;
    BOOL haveActive = NO, allActiveSizeKnown = YES;
    for (VLCTransferItem *item in items) {
        if (!item.active) {
            continue;
        }
        haveActive = YES;
        if (!item.sizeKnown) {
            allActiveSizeKnown = NO;
        }
        received += item.receivedBytes;
        expected += item.expectedBytes;
    }

    if (totalCount > 1) {
        _banner.title = [NSString stringWithFormat:NSLocalizedString(@"TRANSFERS_COUNT_FORMAT", nil), (unsigned long)totalCount];
    } else {
        _banner.title = items.firstObject.displayName ?: NSLocalizedString(@"TRANSFERS_IN_PROGRESS", nil);
    }

    BOOL progressKnown = haveActive && allActiveSizeKnown && expected > 0;
    _banner.progressKnown = progressKnown;
    if (progressKnown) {
        _banner.progress = fmin(fmax((CGFloat)received / (CGFloat)expected, 0.0), 1.0);
    }
    _banner.bytesText = haveActive ? [VLCTransferItem byteProgressStringForReceived:received expected:expected] : nil;
}

- (void)_scheduleHide
{
    if (!_banner || _hideScheduled) {
        return;
    }
    _hideScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self->_hideScheduled) {
            return;
        }
        VLCTransferController *tc = [[VLCAppCoordinator sharedInstance] transferController];
        if (tc.inProgressItems.count > 0) {
            self->_hideScheduled = NO;
            [self _updateBanner];
            return;
        }
        VLCDownloadStatusBanner *banner = self->_banner;
        if (!banner) {
            return;
        }
        [UIView animateWithDuration:0.25 animations:^{
            banner.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (banner.alpha == 0.0) {
                [banner removeFromSuperview];
                if (self->_banner == banner) {
                    self->_banner = nil;
                    self->_bottomConstraint = nil;
                }
            }
            self->_hideScheduled = NO;
        }];
    });
}

- (void)_ensureBannerInstalled
{
    UIView *container = _containerView;
    if (!container) {
        return;
    }
    if (_banner && _banner.superview == container) {
        return;
    }
    if (!_banner) {
        VLCDownloadStatusBanner *banner = [[VLCDownloadStatusBanner alloc] init];
        banner.alpha = 0.0;
        if ([_delegate respondsToSelector:@selector(transferStatusBannerWasTapped:)]) {
            __weak typeof(self) weakSelf = self;
            banner.onTap = ^{
                typeof(self) strongSelf = weakSelf;
                [strongSelf->_delegate transferStatusBannerWasTapped:strongSelf];
            };
        } else {
            banner.userInteractionEnabled = NO;
        }
        _banner = banner;
    }
    [container addSubview:_banner];

#if TARGET_OS_TV
    NSLayoutConstraint *heightConstraint = [_banner.heightAnchor constraintEqualToConstant:120.0];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [_banner.centerXAnchor constraintEqualToAnchor:container.safeAreaLayoutGuide.centerXAnchor],
        [_banner.widthAnchor constraintEqualToAnchor:container.safeAreaLayoutGuide.widthAnchor multiplier:0.5],
        heightConstraint,
    ]];
#else
    NSLayoutConstraint *heightConstraint = [_banner.heightAnchor constraintEqualToConstant:68.0];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [_banner.leadingAnchor constraintEqualToAnchor:container.safeAreaLayoutGuide.leadingAnchor constant:12],
        [_banner.trailingAnchor constraintEqualToAnchor:container.safeAreaLayoutGuide.trailingAnchor constant:-12],
        heightConstraint,
    ]];
#endif
    [self refreshBottomAnchor];
    [container layoutIfNeeded];

    VLCDownloadStatusBanner *banner = _banner;
    [UIView animateWithDuration:0.2 animations:^{
        banner.alpha = 1.0;
    }];
}

- (void)refreshBottomAnchor
{
    UIView *container = _containerView;
    if (!_banner || !container) {
        return;
    }
    _bottomConstraint.active = NO;
    NSLayoutYAxisAnchor *anchor = nil;
    if ([_delegate respondsToSelector:@selector(bottomAnchorForTransferStatusBanner:)]) {
        anchor = [_delegate bottomAnchorForTransferStatusBanner:self];
    }
    if (!anchor) {
        anchor = container.safeAreaLayoutGuide.bottomAnchor;
    }
    _bottomConstraint = [_banner.bottomAnchor constraintEqualToAnchor:anchor constant:-8];
    _bottomConstraint.active = YES;
}

@end
