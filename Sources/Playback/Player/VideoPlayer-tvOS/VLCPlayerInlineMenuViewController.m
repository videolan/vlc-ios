/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlayerInlineMenuViewController.h"
#import "VLCAppCoordinator.h"
#import "VLC-Swift.h"

static const CGFloat VLCInlineMenuItemHeight = 64.0;
static const CGFloat VLCInlineMenuItemSpacing = 4.0;
static const CGFloat VLCInlineMenuWidth = 620.0;
static const CGFloat VLCInlineMenuScreenMargin = 80.0;
static const CGFloat VLCInlineMenuInset = 24.0;
static const CGFloat VLCInlineMenuTitleHeight = 70.0;
static const CGFloat VLCInlineMenuStepperRowHeight = 64.0;
static const CGFloat VLCInlineMenuQueueRowHeight = 92.0;

static NSString *const VLCInlineMenuCellIdentifier = @"VLCPlayerInlineMenuCell";

static CGFloat VLCInlineMenuContentWidth(void)
{
    return VLCInlineMenuWidth - 2 * VLCInlineMenuInset;
}

static UIVisualEffect *VLCInlineMenuBackgroundEffect(void)
{
    if (@available(tvOS 26.0, *)) {
        return [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
}

@implementation VLCPlayerMenuItem

+ (instancetype)itemWithTitle:(NSString *)title selected:(BOOL)selected
{
    VLCPlayerMenuItem *item = [[VLCPlayerMenuItem alloc] init];
    item.title = title;
    item.selected = selected;
    return item;
}

@end

#pragma mark - menu cell

@interface VLCPlayerInlineMenuCell : UICollectionViewCell
{
    UILabel *_titleLabel;
    UIImageView *_checkmarkView;
    BOOL _itemSelected;
}
- (void)configureWithItem:(VLCPlayerMenuItem *)item;
@end

@implementation VLCPlayerInlineMenuCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 12.0;
        self.contentView.clipsToBounds = YES;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:29.0];
        [self.contentView addSubview:_titleLabel];

        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:24.0];
        _checkmarkView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark" withConfiguration:configuration]];
        _checkmarkView.translatesAutoresizingMaskIntoConstraints = NO;
        _checkmarkView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_checkmarkView];

        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_checkmarkView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18.0],
            [_checkmarkView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_checkmarkView.leadingAnchor constant:-8.0],
        ]];
    }
    return self;
}

- (void)configureWithItem:(VLCPlayerMenuItem *)item
{
    _itemSelected = item.selected;
    _titleLabel.text = item.title;
    _checkmarkView.hidden = !item.selected;
    [self updateColors];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.darkTheme.colors;
    UIColor *accent = colors.orangeUI;
    if (self.focused) {
        self.contentView.backgroundColor = colors.lightTextColor;
        _titleLabel.textColor = colors.cellSelectedTextColor;
        _checkmarkView.tintColor = colors.cellSelectedTextColor;
    } else {
        self.contentView.backgroundColor = UIColor.clearColor;
        _titleLabel.textColor = _itemSelected ? accent : colors.lightTextColor;
        _checkmarkView.tintColor = accent;
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        [self updateColors];
    } completion:nil];
}

@end

#pragma mark - focusable card

@interface VLCFocusableCardView : UIView
@end

@implementation VLCFocusableCardView
- (BOOL)canBecomeFocused
{
    return YES;
}
@end

#pragma mark - stepper button

@interface VLCStepperButton : UIButton
@end

@implementation VLCStepperButton

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        if (self.focused) {
            ColorPalette *colors = PresentationTheme.darkTheme.colors;
            self.backgroundColor = colors.lightTextColor;
            self.tintColor = colors.cellSelectedTextColor;
        } else {
            self.backgroundColor = UIColor.clearColor;
            self.tintColor = UIColor.whiteColor;
        }
    } completion:nil];
}

@end

#pragma mark - queue toggle button

@interface VLCQueueToggleButton : UIButton
@property (nonatomic, getter=isActive) BOOL active;
@end

@implementation VLCQueueToggleButton

- (void)setActive:(BOOL)active
{
    _active = active;
    [self updateColors];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.darkTheme.colors;
    UIColor *accent = colors.orangeUI;
    if (self.focused) {
        self.backgroundColor = colors.lightTextColor;
        self.tintColor = colors.cellSelectedTextColor;
    } else {
        self.backgroundColor = UIColor.clearColor;
        self.tintColor = _active ? accent : UIColor.whiteColor;
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        [self updateColors];
    } completion:nil];
}

@end

#pragma mark - queue cell

@interface VLCPlayerQueueCell : UICollectionViewCell
{
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UIImageView *_nowPlayingView;
    BOOL _current;
}
- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle current:(BOOL)current;
@end

@implementation VLCPlayerQueueCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 12.0;
        self.contentView.clipsToBounds = YES;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:29.0];
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = [UIFont systemFontOfSize:23.0];
        [self.contentView addSubview:_subtitleLabel];

        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:24.0];
        _nowPlayingView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"speaker.wave.2.fill" withConfiguration:configuration]];
        _nowPlayingView.translatesAutoresizingMaskIntoConstraints = NO;
        _nowPlayingView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_nowPlayingView];

        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
            [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4.0],
            [_nowPlayingView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18.0],
            [_nowPlayingView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_nowPlayingView.leadingAnchor constant:-8.0],
            [_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_nowPlayingView.leadingAnchor constant:-8.0],
        ]];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle current:(BOOL)current
{
    _current = current;
    _titleLabel.text = title;
    _subtitleLabel.text = subtitle;
    _subtitleLabel.hidden = subtitle.length == 0;
    _nowPlayingView.hidden = !current;
    [self updateColors];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.darkTheme.colors;
    UIColor *accent = colors.orangeUI;
    if (self.focused) {
        self.contentView.backgroundColor = colors.lightTextColor;
        _titleLabel.textColor = colors.cellSelectedTextColor;
        _subtitleLabel.textColor = colors.cellSelectedTextColor;
        _nowPlayingView.tintColor = colors.cellSelectedTextColor;
    } else {
        self.contentView.backgroundColor = UIColor.clearColor;
        _titleLabel.textColor = _current ? accent : colors.lightTextColor;
        _subtitleLabel.textColor = [colors.lightTextColor colorWithAlphaComponent:0.7];
        _nowPlayingView.tintColor = accent;
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        [self updateColors];
    } completion:nil];
}

@end

#pragma mark - panel base

@interface VLCPlayerPanelViewController ()
{
    NSString *_panelTitle;
    UIVisualEffectView *_panelEffectView;
    UILabel *_titleLabel;
    UIView *_contentContainer;
    CGRect _sourceFrameInWindow;
    NSLayoutConstraint *_panelLeadingConstraint;
    NSLayoutConstraint *_panelTopConstraint;
    NSLayoutConstraint *_panelHeightConstraint;
}
@property (nonatomic, readonly) UIView *panelContentView;
- (void)populatePanelContent;
- (CGFloat)panelContentHeight;
- (NSArray<id<UIFocusEnvironment>> *)panelPreferredFocusEnvironments;
@end

@implementation VLCPlayerPanelViewController

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _panelTitle = title;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)presentFromButton:(UIButton *)button
         inViewController:(UIViewController *)presenter
{
    _sourceFrameInWindow = [button.superview convertRect:button.frame toView:nil];
    [presenter presentViewController:self animated:YES completion:nil];
}

- (UIView *)panelContentView
{
    return _contentContainer;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColor.clearColor;
    self.view = view;

    _panelEffectView = [[UIVisualEffectView alloc] initWithEffect:VLCInlineMenuBackgroundEffect()];
    _panelEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    _panelEffectView.layer.cornerRadius = 22.0;
    _panelEffectView.layer.cornerCurve = kCACornerCurveContinuous;
    _panelEffectView.clipsToBounds = YES;
    [view addSubview:_panelEffectView];

    UIView *content = _panelEffectView.contentView;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.text = _panelTitle;
    _titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    _titleLabel.textColor = PresentationTheme.darkTheme.colors.lightTextColor;
    [content addSubview:_titleLabel];

    _contentContainer = [[UIView alloc] init];
    _contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _contentContainer.backgroundColor = UIColor.clearColor;
    [content addSubview:_contentContainer];

    _panelLeadingConstraint = [_panelEffectView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor];
    _panelTopConstraint = [_panelEffectView.topAnchor constraintEqualToAnchor:view.topAnchor];
    _panelHeightConstraint = [_panelEffectView.heightAnchor constraintEqualToConstant:0.0];

    [NSLayoutConstraint activateConstraints:@[
        _panelLeadingConstraint,
        _panelTopConstraint,
        _panelHeightConstraint,
        [_panelEffectView.widthAnchor constraintEqualToConstant:VLCInlineMenuWidth],

        [_titleLabel.topAnchor constraintEqualToAnchor:content.topAnchor constant:VLCInlineMenuInset],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:VLCInlineMenuInset],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-VLCInlineMenuInset],
        [_titleLabel.heightAnchor constraintEqualToConstant:VLCInlineMenuTitleHeight - VLCInlineMenuInset],

        [_contentContainer.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor],
        [_contentContainer.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:VLCInlineMenuInset],
        [_contentContainer.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-VLCInlineMenuInset],
        [_contentContainer.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-VLCInlineMenuInset],
    ]];

    [self populatePanelContent];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(dismissPanel)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    const CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    const CGFloat anchorY = CGRectGetMinY(_sourceFrameInWindow) - 40.0;
    const CGFloat maxHeight = anchorY - VLCInlineMenuScreenMargin;

    CGFloat contentHeight = VLCInlineMenuTitleHeight + [self panelContentHeight] + VLCInlineMenuInset;
    _panelHeightConstraint.constant = MIN(contentHeight, maxHeight);
    _panelTopConstraint.constant = anchorY - _panelHeightConstraint.constant;

    CGFloat desiredX = CGRectGetMidX(_sourceFrameInWindow) - VLCInlineMenuWidth / 2.0;
    CGFloat maxX = viewWidth - VLCInlineMenuWidth - VLCInlineMenuScreenMargin;
    _panelLeadingConstraint.constant = MAX(VLCInlineMenuScreenMargin, MIN(desiredX, maxX));
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return [self panelPreferredFocusEnvironments];
}

- (void)dismissPanel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    if (((UIPress *)[presses anyObject]).type == UIPressTypeMenu) {
        [self dismissPanel];
        return;
    }
    [super pressesBegan:presses withEvent:event];
}

#pragma mark - subclassing hooks

- (void)populatePanelContent
{
}

- (CGFloat)panelContentHeight
{
    return 0.0;
}

- (NSArray<id<UIFocusEnvironment>> *)panelPreferredFocusEnvironments
{
    return @[];
}

@end

#pragma mark - menu

@interface VLCPlayerInlineMenuViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray<VLCPlayerMenuItem *> *_items;
    NSInteger _itemCount;
    NSInteger _selectedIndex;
    BOOL _hasValuedItems;
    UICollectionView *_collectionView;
    float _value;
    UILabel *_valueLabel;
}
@end

@implementation VLCPlayerInlineMenuViewController

- (instancetype)initWithTitle:(NSString *)title
                        items:(NSArray<VLCPlayerMenuItem *> *)items
{
    self = [super initWithTitle:title];
    if (self) {
        _items = items;
        _itemCount = _items.count;
        _selectedIndex = NSNotFound;
        for (NSInteger i = 0; i < _itemCount; i++) {
            if (_selectedIndex == NSNotFound && _items[i].selected) {
                _selectedIndex = i;
            }
            if (_items[i].value != nil) {
                _hasValuedItems = YES;
            }
        }
    }
    return self;
}

- (void)populatePanelContent
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = VLCInlineMenuItemSpacing;
    layout.minimumInteritemSpacing = 0.0;
    layout.itemSize = CGSizeMake(VLCInlineMenuContentWidth(), VLCInlineMenuItemHeight);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.remembersLastFocusedIndexPath = YES;
    [_collectionView registerClass:[VLCPlayerInlineMenuCell class]
        forCellWithReuseIdentifier:VLCInlineMenuCellIdentifier];

    UIView *container = self.panelContentView;
    [container addSubview:_collectionView];

    NSMutableArray<NSLayoutConstraint *> *constraints = [@[
        [_collectionView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [_collectionView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [_collectionView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
    ] mutableCopy];

    if (_showsStepperControl) {
        _value = _currentValue;
        UIView *stepperRow = [self makeStepperRow];
        [container addSubview:stepperRow];
        [constraints addObjectsFromArray:@[
            [stepperRow.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
            [stepperRow.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
            [stepperRow.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
            [stepperRow.heightAnchor constraintEqualToConstant:VLCInlineMenuStepperRowHeight],
            [_collectionView.bottomAnchor constraintEqualToAnchor:stepperRow.topAnchor constant:-VLCInlineMenuInset],
        ]];
    } else {
        [constraints addObject:[_collectionView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (UIView *)makeStepperRow
{
    ColorPalette *colors = PresentationTheme.darkTheme.colors;
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:29.0];
    titleLabel.textColor = colors.lightTextColor;
    titleLabel.text = _stepperTitle;
    [row addSubview:titleLabel];

    _valueLabel = [[UILabel alloc] init];
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.font = [UIFont systemFontOfSize:29.0];
    _valueLabel.textColor = colors.lightTextColor;
    _valueLabel.textAlignment = NSTextAlignmentCenter;
    [row addSubview:_valueLabel];

    UIButton *decreaseButton = [self makeStepperButtonWithImageName:@"minus"
                                                accessibilityLabel:NSLocalizedString(@"DECREASE_BUTTON", nil)
                                                            action:@selector(decreaseValue)];
    UIButton *increaseButton = [self makeStepperButtonWithImageName:@"plus"
                                                accessibilityLabel:NSLocalizedString(@"INCREASE_BUTTON", nil)
                                                            action:@selector(increaseValue)];
    UIButton *resetButton = [self makeStepperButtonWithImageName:@"arrow.counterclockwise"
                                             accessibilityLabel:NSLocalizedString(@"BUTTON_RESET", nil)
                                                         action:@selector(resetValue)];
    [row addSubview:decreaseButton];
    [row addSubview:increaseButton];
    [row addSubview:resetButton];

    [self updateValueLabel];

    const CGFloat side = 56.0;
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],

        [resetButton.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [resetButton.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [resetButton.widthAnchor constraintEqualToConstant:side],
        [resetButton.heightAnchor constraintEqualToConstant:side],

        [increaseButton.trailingAnchor constraintEqualToAnchor:resetButton.leadingAnchor constant:-16.0],
        [increaseButton.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [increaseButton.widthAnchor constraintEqualToConstant:side],
        [increaseButton.heightAnchor constraintEqualToConstant:side],

        [_valueLabel.trailingAnchor constraintEqualToAnchor:increaseButton.leadingAnchor constant:-8.0],
        [_valueLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [_valueLabel.widthAnchor constraintGreaterThanOrEqualToConstant:140.0],

        [decreaseButton.trailingAnchor constraintEqualToAnchor:_valueLabel.leadingAnchor constant:-8.0],
        [decreaseButton.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [decreaseButton.widthAnchor constraintEqualToConstant:side],
        [decreaseButton.heightAnchor constraintEqualToConstant:side],

        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:decreaseButton.leadingAnchor constant:-16.0],
    ]];
    return row;
}

- (UIButton *)makeStepperButtonWithImageName:(NSString *)imageName
                          accessibilityLabel:(NSString *)label
                                      action:(SEL)action
{
    VLCStepperButton *button = [VLCStepperButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:24.0];
    [button setImage:[UIImage systemImageNamed:imageName withConfiguration:configuration] forState:UIControlStateNormal];
    button.tintColor = UIColor.whiteColor;
    button.layer.cornerRadius = 28.0;
    button.clipsToBounds = YES;
    button.accessibilityLabel = label;
    [button addTarget:self action:action forControlEvents:UIControlEventPrimaryActionTriggered];
    return button;
}

- (void)increaseValue
{
    [self applyValue:_value + _stepperStep];
}

- (void)decreaseValue
{
    [self applyValue:_value - _stepperStep];
}

- (void)resetValue
{
    [self applyValue:_defaultValue];
}

- (void)applyValue:(float)value
{
    _value = MAX(_minimumValue, MIN(_maximumValue, value));
    [self updateValueLabel];
    if (_hasValuedItems) {
        [self selectItemMatchingValue];
    }
    id<VLCPlayerInlineMenuDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(inlineMenu:didSetValue:)]) {
        [delegate inlineMenu:self didSetValue:_value];
    }
}

- (void)selectItemMatchingValue
{
    NSInteger matchIndex = NSNotFound;
    for (NSInteger i = 0; i < _itemCount; i++) {
        NSNumber *itemValue = _items[i].value;
        _items[i].selected = (itemValue != nil && fabsf(itemValue.floatValue - _value) < 0.01f);
        if (_items[i].selected) {
            matchIndex = i;
        }
    }
    if (matchIndex == _selectedIndex) {
        return;
    }
    _selectedIndex = matchIndex;
    [_collectionView reloadData];
}

- (void)updateValueLabel
{
    switch (_stepperUnit) {
        case VLCPlayerStepperUnitMilliseconds:
            _valueLabel.text = [NSString stringWithFormat:@"%.0f ms", _value];
            break;
        case VLCPlayerStepperUnitRate:
            _valueLabel.text = [NSString stringWithFormat:@"%.2f×", _value];
            break;
    }
}

- (CGFloat)panelContentHeight
{
    CGFloat height = _itemCount * VLCInlineMenuItemHeight + MAX(0, _itemCount - 1) * VLCInlineMenuItemSpacing;
    if (_showsStepperControl) {
        height += VLCInlineMenuInset + VLCInlineMenuStepperRowHeight;
    }
    return height;
}

- (NSArray<id<UIFocusEnvironment>> *)panelPreferredFocusEnvironments
{
    return @[_collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlayerInlineMenuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCInlineMenuCellIdentifier
                                                                             forIndexPath:indexPath];
    [cell configureWithItem:_items[indexPath.row]];
    return cell;
}

- (NSIndexPath *)indexPathForPreferredFocusedItemInCollectionView:(UICollectionView *)collectionView
{
    if (_selectedIndex == NSNotFound) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    id<VLCPlayerInlineMenuDelegate> delegate = self.delegate;
    [self dismissViewControllerAnimated:YES completion:^{
        [delegate inlineMenu:self didSelectItemAtIndex:index];
    }];
}

@end

#pragma mark - info

@interface VLCPlayerInfoPanelViewController ()
{
    NSString *_infoText;
    VLCFocusableCardView *_infoCard;
    UILabel *_infoLabel;
}
@end

@implementation VLCPlayerInfoPanelViewController

- (instancetype)initWithTitle:(NSString *)title
                     infoText:(NSString *)infoText
{
    self = [super initWithTitle:title];
    if (self) {
        _infoText = infoText;
    }
    return self;
}

- (void)populatePanelContent
{
    UIView *container = self.panelContentView;

    _infoCard = [[VLCFocusableCardView alloc] init];
    _infoCard.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:_infoCard];

    _infoLabel = [[UILabel alloc] init];
    _infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _infoLabel.numberOfLines = 0;
    _infoLabel.textColor = PresentationTheme.darkTheme.colors.lightTextColor;
    _infoLabel.attributedText = [self attributedInfoText];
    [_infoCard addSubview:_infoLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_infoCard.topAnchor constraintEqualToAnchor:container.topAnchor],
        [_infoCard.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [_infoCard.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [_infoCard.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],

        [_infoLabel.topAnchor constraintEqualToAnchor:_infoCard.topAnchor],
        [_infoLabel.leadingAnchor constraintEqualToAnchor:_infoCard.leadingAnchor],
        [_infoLabel.trailingAnchor constraintEqualToAnchor:_infoCard.trailingAnchor],
    ]];
}

- (NSAttributedString *)attributedInfoText
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacing = 18.0;
    paragraphStyle.lineSpacing = 4.0;
    return [[NSAttributedString alloc] initWithString:_infoText
                                           attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:29.0],
        NSParagraphStyleAttributeName: paragraphStyle,
    }];
}

- (CGFloat)panelContentHeight
{
    return [_infoLabel sizeThatFits:CGSizeMake(VLCInlineMenuContentWidth(), CGFLOAT_MAX)].height;
}

- (NSArray<id<UIFocusEnvironment>> *)panelPreferredFocusEnvironments
{
    return @[_infoCard];
}

@end

#pragma mark - queue

static NSString *const VLCQueueCellIdentifier = @"VLCPlayerQueueCell";

@interface VLCPlayerQueuePanelViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    UICollectionView *_collectionView;
    VLCQueueToggleButton *_shuffleButton;
    VLCQueueToggleButton *_repeatButton;
}
@end

@implementation VLCPlayerQueuePanelViewController

- (VLCMediaList *)activeList
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    return vpc.isShuffleMode ? vpc.shuffledList : vpc.mediaList;
}

- (NSInteger)currentIndex
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    return [[self activeList] indexOfMedia:vpc.currentlyPlayingMedia];
}

- (void)populatePanelContent
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = VLCInlineMenuItemSpacing;
    layout.minimumInteritemSpacing = 0.0;
    layout.itemSize = CGSizeMake(VLCInlineMenuContentWidth(), VLCInlineMenuQueueRowHeight);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.remembersLastFocusedIndexPath = YES;
    [_collectionView registerClass:[VLCPlayerQueueCell class] forCellWithReuseIdentifier:VLCQueueCellIdentifier];

    UIView *container = self.panelContentView;
    [container addSubview:_collectionView];

    UIView *footer = [self makeFooterRow];
    [container addSubview:footer];

    [NSLayoutConstraint activateConstraints:@[
        [_collectionView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [_collectionView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [_collectionView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],

        [footer.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [footer.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [footer.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [footer.heightAnchor constraintEqualToConstant:VLCInlineMenuStepperRowHeight],
        [_collectionView.bottomAnchor constraintEqualToAnchor:footer.topAnchor constant:-VLCInlineMenuInset],
    ]];
}

- (UIView *)makeFooterRow
{
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    _shuffleButton = [self makeToggleButtonWithImageName:@"shuffle"
                                      accessibilityLabel:NSLocalizedString(@"SHUFFLE", nil)
                                                  action:@selector(toggleShuffle)];
    _repeatButton = [self makeToggleButtonWithImageName:@"repeat"
                                     accessibilityLabel:NSLocalizedString(@"REPEAT_MODE", nil)
                                                 action:@selector(toggleRepeat)];
    [row addSubview:_shuffleButton];
    [row addSubview:_repeatButton];
    [self updateShuffleButton];
    [self updateRepeatButton];

    const CGFloat side = 56.0;
    [NSLayoutConstraint activateConstraints:@[
        [_shuffleButton.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [_shuffleButton.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [_shuffleButton.widthAnchor constraintEqualToConstant:side],
        [_shuffleButton.heightAnchor constraintEqualToConstant:side],

        [_repeatButton.leadingAnchor constraintEqualToAnchor:_shuffleButton.trailingAnchor constant:16.0],
        [_repeatButton.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [_repeatButton.widthAnchor constraintEqualToConstant:side],
        [_repeatButton.heightAnchor constraintEqualToConstant:side],
    ]];
    return row;
}

- (VLCQueueToggleButton *)makeToggleButtonWithImageName:(NSString *)imageName
                                     accessibilityLabel:(NSString *)label
                                                 action:(SEL)action
{
    VLCQueueToggleButton *button = [VLCQueueToggleButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:24.0];
    [button setImage:[UIImage systemImageNamed:imageName withConfiguration:configuration] forState:UIControlStateNormal];
    button.layer.cornerRadius = 28.0;
    button.clipsToBounds = YES;
    button.accessibilityLabel = label;
    [button addTarget:self action:action forControlEvents:UIControlEventPrimaryActionTriggered];
    return button;
}

- (void)toggleShuffle
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    vpc.shuffleMode = !vpc.isShuffleMode;
    [self updateShuffleButton];
    [_collectionView reloadData];
    [self setNeedsFocusUpdate];
}

- (void)toggleRepeat
{
    [[VLCPlaybackService sharedInstance] toggleRepeatMode];
    [self updateRepeatButton];
}

- (void)updateShuffleButton
{
    _shuffleButton.active = [VLCPlaybackService sharedInstance].isShuffleMode;
}

- (void)updateRepeatButton
{
    VLCRepeatMode mode = [VLCPlaybackService sharedInstance].repeatMode;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:24.0];
    NSString *imageName = (mode == VLCRepeatCurrentItem) ? @"repeat.1" : @"repeat";
    [_repeatButton setImage:[UIImage systemImageNamed:imageName withConfiguration:configuration] forState:UIControlStateNormal];
    _repeatButton.active = (mode != VLCDoNotRepeat);
}

- (CGFloat)panelContentHeight
{
    CGFloat rows = [self activeList].count;
    CGFloat height = rows * VLCInlineMenuQueueRowHeight + MAX(0, rows - 1) * VLCInlineMenuItemSpacing;
    return height + VLCInlineMenuInset + VLCInlineMenuStepperRowHeight;
}

- (NSArray<id<UIFocusEnvironment>> *)panelPreferredFocusEnvironments
{
    return @[_collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self activeList].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlayerQueueCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCQueueCellIdentifier
                                                                        forIndexPath:indexPath];
    VLCMedia *media = [[self activeList] mediaAtIndex:indexPath.row];
    VLCMLMedia *mlMedia = [[VLCAppCoordinator sharedInstance].mediaLibraryService fetchOrCreateMediaWith:media.url];

    NSString *title = mlMedia.title.length ? mlMedia.title : media.url.lastPathComponent;
    NSString *subtitle = [self subtitleForMedia:mlMedia];
    BOOL current = indexPath.row == [self currentIndex];
    [cell configureWithTitle:title subtitle:subtitle current:current];
    return cell;
}

- (NSString *)subtitleForMedia:(VLCMLMedia *)mlMedia
{
    if (mlMedia == nil) {
        return @"";
    }
    NSString *artist = mlMedia.artist.name;
    NSString *duration = [VLCTime timeWithInt:(int)mlMedia.duration].stringValue;
    if (artist.length && duration.length) {
        return [NSString stringWithFormat:@"%@ — %@", artist, duration];
    }
    return artist.length ? artist : duration;
}

- (NSIndexPath *)indexPathForPreferredFocusedItemInCollectionView:(UICollectionView *)collectionView
{
    NSInteger current = [self currentIndex];
    if (current == NSNotFound || current < 0) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:current inSection:0];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    [self dismissViewControllerAnimated:YES completion:^{
        [[VLCPlaybackService sharedInstance] playItemAtIndex:index];
    }];
}

@end
