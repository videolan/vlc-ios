/*****************************************************************************
 * VLCRadioAlarmEditorViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioAlarmEditorViewController.h"

#import "VLC-Swift.h"

@implementation VLCRadioAlarmEditorViewController
{
    NSString *_stationName;
    VLCRadioAlarmInfo *_existingAlarm;
    VLCRadioAlarmEditorCompletion _completion;

    UIDatePicker *_datePicker;
    NSArray<UIButton *> *_weekdayButtons;
}

+ (void)presentForStationNamed:(NSString *)stationName
                 existingAlarm:(VLCRadioAlarmInfo *)existingAlarm
            fromViewController:(UIViewController *)viewController
                    completion:(VLCRadioAlarmEditorCompletion)completion
{
    VLCRadioAlarmEditorViewController *editor = [[VLCRadioAlarmEditorViewController alloc] initWithStationName:stationName
                                                                                                existingAlarm:existingAlarm
                                                                                                   completion:completion];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editor];
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = navigationController.sheetPresentationController;
        sheet.detents = @[[UISheetPresentationControllerDetent mediumDetent]];
        sheet.prefersGrabberVisible = YES;
    }
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (instancetype)initWithStationName:(NSString *)stationName
                      existingAlarm:(VLCRadioAlarmInfo *)existingAlarm
                         completion:(VLCRadioAlarmEditorCompletion)completion
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _stationName = stationName;
        _existingAlarm = existingAlarm;
        _completion = [completion copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = _stationName;
    self.view.backgroundColor = PresentationTheme.current.colors.background;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_SAVE", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(save)];

    [self setupViews];
}

- (void)setupViews
{
    NSCalendar *calendar = [NSCalendar currentCalendar];

    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.translatesAutoresizingMaskIntoConstraints = NO;
    _datePicker.datePickerMode = UIDatePickerModeTime;
    if (@available(iOS 13.4, *)) {
        _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    if (_existingAlarm) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.hour = _existingAlarm.hour;
        components.minute = _existingAlarm.minute;
        NSDate *date = [calendar dateFromComponents:components];
        if (date) {
            _datePicker.date = date;
        }
    }

    UILabel *repeatLabel = [[UILabel alloc] init];
    repeatLabel.translatesAutoresizingMaskIntoConstraints = NO;
    repeatLabel.text = NSLocalizedString(@"REPEAT_MODE", nil);
    repeatLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    repeatLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;

    UIStackView *weekdayStack = [[UIStackView alloc] init];
    weekdayStack.translatesAutoresizingMaskIntoConstraints = NO;
    weekdayStack.axis = UILayoutConstraintAxisHorizontal;
    weekdayStack.distribution = UIStackViewDistributionFillEqually;
    weekdayStack.spacing = 8.0;

    NSArray<NSString *> *symbols = calendar.veryShortWeekdaySymbols;
    NSInteger dayCount = symbols.count;
    NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:dayCount];
    for (NSInteger offset = 0; offset < dayCount; offset++) {
        // start the week where the user's locale starts it
        NSInteger weekday = (calendar.firstWeekday - 1 + offset) % dayCount + 1;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:symbols[weekday - 1] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        button.tag = weekday;
        button.layer.cornerRadius = 18.0;
        button.clipsToBounds = YES;
        button.selected = [_existingAlarm.weekdays containsObject:@(weekday)];
        [button addTarget:self action:@selector(toggleWeekday:) forControlEvents:UIControlEventTouchUpInside];
        [button.heightAnchor constraintEqualToConstant:36.0].active = YES;
        [self applyStyleToButton:button];
        [weekdayStack addArrangedSubview:button];
        [buttons addObject:button];
    }
    _weekdayButtons = [buttons copy];

    [self.view addSubview:_datePicker];
    [self.view addSubview:repeatLabel];
    [self.view addSubview:weekdayStack];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_datePicker.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [_datePicker.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [_datePicker.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],

        [repeatLabel.topAnchor constraintEqualToAnchor:_datePicker.bottomAnchor constant:16.0],
        [repeatLabel.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20.0],

        [weekdayStack.topAnchor constraintEqualToAnchor:repeatLabel.bottomAnchor constant:8.0],
        [weekdayStack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20.0],
        [weekdayStack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20.0]
    ]];
}

- (void)applyStyleToButton:(UIButton *)button
{
    ColorPalette *themeColors = PresentationTheme.current.colors;
    button.backgroundColor = button.selected ? themeColors.orangeUI : themeColors.cellBackgroundB;
    [button setTitleColor:button.selected ? [UIColor whiteColor] : themeColors.cellTextColor
                 forState:UIControlStateNormal];
}

- (void)toggleWeekday:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self applyStyleToButton:sender];
}

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                  fromDate:_datePicker.date];
    NSMutableArray<NSNumber *> *weekdays = [NSMutableArray array];
    for (UIButton *button in _weekdayButtons) {
        if (button.selected) {
            [weekdays addObject:@(button.tag)];
        }
    }

    VLCRadioAlarmEditorCompletion completion = _completion;
    [self dismissViewControllerAnimated:YES completion:^{
        completion(components.hour, components.minute, [weekdays copy]);
    }];
}

@end
