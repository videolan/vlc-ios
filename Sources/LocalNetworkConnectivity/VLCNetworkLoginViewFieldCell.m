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
#import "VLC_iOS-Swift.h"

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
    
    id<VLCLayoutAnchorContainer> guide = self;
    if (@available(iOS 11.0, *)) {
        guide = self.safeAreaLayoutGuide;
    }
    [NSLayoutConstraint activateConstraints:@[
                                              [darkView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                              [darkView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [darkView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
                                              [darkView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-1],
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
