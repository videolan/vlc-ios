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
NSString * const kVLCNetworkLoginViewFieldCellIdentifier = @"VLCNetworkLoginViewFieldCellIdentifier";

@interface VLCNetworkLoginViewFieldCell () <UITextFieldDelegate>
@end

@implementation VLCNetworkLoginViewFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    UIView *darkView = [[UIView alloc] init];
    darkView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:darkView];
    darkView.backgroundColor = [UIColor colorWithRed:57.0/256.0 green:57.0/256.0 blue:57.0/256.0 alpha:1.0];
    self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.delegate = self;
    self.textField.textColor = [UIColor whiteColor];
    [self addSubview:_textField];
    
    NSObject *guide = self;
    if (@available(iOS 11.0, *)) {
        guide = self.safeAreaLayoutGuide;
    }

    [self addConstraints:@[
                           [NSLayoutConstraint constraintWithItem:darkView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                           [NSLayoutConstraint constraintWithItem:darkView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                           [NSLayoutConstraint constraintWithItem:darkView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                           [NSLayoutConstraint constraintWithItem:darkView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-1],

                           [NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1 constant:8.0],
                           [NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                           [NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1 constant:8.0],
                           [NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]
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

#pragma mark - Properties

- (void)setPlaceholderString:(NSString *)placeholderString
{
    UIColor *color = [UIColor VLCLightTextColor];

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
