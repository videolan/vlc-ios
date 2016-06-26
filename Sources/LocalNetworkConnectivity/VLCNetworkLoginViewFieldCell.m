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

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contentView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    self.textField.delegate = self;
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
