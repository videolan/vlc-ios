/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkLoginViewFieldCell.h"
#import "VLC-Swift.h"

NSString * const kVLCNetworkLoginViewFieldCellIdentifier = @"VLCNetworkLoginViewFieldCellIdentifier";

@interface VLCNetworkLoginViewFieldCell () <UITextFieldDelegate>
@end

@implementation VLCNetworkLoginViewFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
        [self themeDidChange];
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    _darkView = [[UIView alloc] init];
    _darkView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_darkView];
    self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.delegate = self;
    self.textField.textColor = PresentationTheme.current.colors.cellTextColor;
    self.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [self addSubview:_textField];
    
    id<VLCLayoutAnchorContainer> guide = self;
    if (@available(iOS 11.0, *)) {
        guide = self.safeAreaLayoutGuide;
    }
    [NSLayoutConstraint activateConstraints:@[
                                              [_darkView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                              [_darkView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [_darkView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
                                              [_darkView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-1],
                                              [self.textField.leftAnchor constraintEqualToAnchor:guide.leftAnchor constant:8.0],
                                              [self.textField.topAnchor constraintEqualToAnchor:guide.topAnchor],
                                              [self.textField.rightAnchor constraintEqualToAnchor:guide.rightAnchor constant:8.0],
                                              [self.textField.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
                                              ]];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    UITextField *textField = self.textField;
    textField.keyboardType = UIKeyboardTypeDefault;
    textField.text = nil;
    textField.secureTextEntry = NO;
    self.placeholderString = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [self.textField becomeFirstResponder];
    }
}

- (void)themeDidChange
{
    self.backgroundColor = PresentationTheme.current.colors.background;
    self.textField.textColor = PresentationTheme.current.colors.cellTextColor;
    _darkView.backgroundColor = PresentationTheme.current.colors.background;
}

#pragma mark - Properties

- (void)setPlaceholderString:(NSString *)placeholderString
{
    UIColor *color = PresentationTheme.current.colors.lightTextColor;

    self.textField.attributedPlaceholder = placeholderString ? [[NSAttributedString alloc] initWithString:placeholderString attributes:@{NSForegroundColorAttributeName: color}] : nil;
}

- (NSString *)placeholderString
{
    return self.textField.placeholder;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = [self.delegate loginViewFieldCellShouldReturn:self];
    if (shouldReturn) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.delegate loginViewFieldCellDidEndEditing:self];
}

@end
