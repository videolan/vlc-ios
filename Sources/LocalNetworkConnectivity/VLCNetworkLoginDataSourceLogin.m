/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkLoginDataSourceLogin.h"
#import "VLCNetworkLoginViewFieldCell.h"
#import "VLCNetworkLoginViewButtonCell.h"

typedef NS_ENUM(NSUInteger, VLCNetworkServerLoginIndex) {
    VLCNetworkServerLoginIndexServer,
    VLCNetworkServerLoginIndexPort,
    VLCNetworkServerLoginIndexUsername,
    VLCNetworkServerLoginIndexPassword,
    VLCNetworkServerLoginIndexSave,

    VLCNetworkServerLoginIndexCount,
    VLCNetworkServerLoginIndexFieldCount = VLCNetworkServerLoginIndexSave
};

@interface VLCNetworkLoginDataSourceLogin () <VLCNetworkLoginViewFieldCellDelegate>
@property (nonatomic, weak) UITableView *tableView;
@end

@implementation VLCNetworkLoginDataSourceLogin
@synthesize sectionIndex = _sectionIndex;

#pragma mark - API

- (void)registerCellsInTableView:(UITableView *)tableView
{
    [tableView registerClass:[VLCNetworkLoginViewButtonCell class] forCellReuseIdentifier:kVLCNetworkLoginViewButtonCellIdentifier];
    [tableView registerClass:[VLCNetworkLoginViewFieldCell class] forCellReuseIdentifier:kVLCNetworkLoginViewFieldCellIdentifier];
}

- (void)setLoginInformation:(VLCNetworkServerLoginInformation *)loginInformation
{
    _loginInformation = loginInformation;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - helper

- (void)configureButtonCell:(VLCNetworkLoginViewButtonCell *)buttonCell forRow:(NSUInteger)row
{
    NSString *labelString = nil;
    NSUInteger additionalFieldsCount = self.loginInformation.additionalFields.count;
    NSUInteger buttonRowIndex = row-additionalFieldsCount;
    if (buttonRowIndex == VLCNetworkServerLoginIndexSave) {
        labelString = NSLocalizedString(@"BUTTON_SAVE", nil);
    }
    buttonCell.titleString = labelString;
}

- (void)configureFieldCell:(VLCNetworkLoginViewFieldCell *)fieldCell forRow:(NSUInteger)row
{
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    BOOL secureTextEntry = NO;
    NSString *labelString = nil;
    NSString *valueString = nil;
    UIReturnKeyType returnKeyType = UIReturnKeyNext;
    NSString *textContentType = nil;

    switch (row) {
        case VLCNetworkServerLoginIndexServer:
            keyboardType = UIKeyboardTypeURL;
            labelString = NSLocalizedString(@"SERVER", nil);
            valueString = self.loginInformation.address;
            [self.delegate canConnect:valueString && valueString.length > 0];
            if (@available(iOS 10.0, *)) {
                textContentType = UITextContentTypeURL;
            }
            break;
        case VLCNetworkServerLoginIndexPort:
            keyboardType = UIKeyboardTypeNumberPad;
            labelString = NSLocalizedString(@"SERVER_PORT", nil);
            valueString = self.loginInformation.port.stringValue;
            break;
        case VLCNetworkServerLoginIndexUsername:
            labelString = NSLocalizedString(@"USER_LABEL", nil);
            valueString = self.loginInformation.username;
            if (@available(iOS 11.0, *)) {
                textContentType = UITextContentTypeUsername;
            }
            break;
        case VLCNetworkServerLoginIndexPassword:
            labelString = NSLocalizedString(@"PASSWORD_LABEL", nil);
            valueString = self.loginInformation.password;
            secureTextEntry = YES;
            if (self.loginInformation.additionalFields.count == 0) {
                returnKeyType = UIReturnKeyDone;
            }
            if (@available(iOS 11.0, *)) {
                textContentType = UITextContentTypePassword;
            }
            break;
        default: {
            NSUInteger additionalFieldRow = row-VLCNetworkServerLoginIndexFieldCount;
            NSArray <VLCNetworkServerLoginInformationField *> *additionalFields = self.loginInformation.additionalFields;
            VLCNetworkServerLoginInformationField *field = additionalFields[additionalFieldRow];
            if (field.type == VLCNetworkServerLoginInformationFieldTypeNumber) {
                keyboardType = UIKeyboardTypeNumberPad;
            }
            valueString     = field.textValue;
            labelString     = field.localizedLabel;
            returnKeyType   = additionalFieldRow == additionalFields.count-1 ? UIReturnKeyDone : UIReturnKeyNext;
        }
            break;
    }

    fieldCell.placeholderString = labelString;
    UITextField *textField = fieldCell.textField;
    textField.autocorrectionType     = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.text                   = valueString;
    textField.keyboardType           = keyboardType;
    textField.secureTextEntry        = secureTextEntry;
    textField.returnKeyType          = returnKeyType;
    textField.tag                    = row;
    if (@available(iOS 10.0, *)) {
        textField.textContentType = textContentType;
    }
    fieldCell.delegate = self;
}

- (void)updatedStringValue:(NSString *)string forRow:(NSUInteger)row
{
    switch (row) {
        case VLCNetworkServerLoginIndexServer:
            self.loginInformation.address = string;
            [self.delegate canConnect:string && string.length > 0];
            break;
        case VLCNetworkServerLoginIndexPort:
            self.loginInformation.port = string.length > 0 ? @(string.integerValue) : nil;
            break;
        case VLCNetworkServerLoginIndexUsername:
            self.loginInformation.username = string;
            break;
        case VLCNetworkServerLoginIndexPassword:
            self.loginInformation.password = string;
            break;
        default: {
            NSUInteger additionalFieldRow = row-VLCNetworkServerLoginIndexFieldCount;
            NSArray <VLCNetworkServerLoginInformationField *> *additionalFields = self.loginInformation.additionalFields;
            VLCNetworkServerLoginInformationField *field = additionalFields[additionalFieldRow];
            field.textValue = string;
        }
            break;
    }
}

- (void)makeCellFirstResponder:(UITableViewCell *)cell
{
    if ([cell isKindOfClass:[VLCNetworkLoginViewFieldCell class]]) {
        [[(VLCNetworkLoginViewFieldCell *)cell textField] becomeFirstResponder];
    }
}


#pragma mark - VLCNetworkLoginDataSourceSection
- (void)configureWithTableView:(UITableView *)tableView
{
    [self registerCellsInTableView:tableView];
    self.tableView = tableView;
}

- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView
{
    return VLCNetworkServerLoginIndexCount + self.loginInformation.additionalFields.count;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    switch (row) {
        case VLCNetworkServerLoginIndexServer:
        case VLCNetworkServerLoginIndexPort:
        case VLCNetworkServerLoginIndexUsername:
        case VLCNetworkServerLoginIndexPassword:
            return kVLCNetworkLoginViewFieldCellIdentifier;
        default:
            break;
    }
    NSUInteger additionalFieldsCount = self.loginInformation.additionalFields.count;
    NSUInteger buttonRowIndex = row-additionalFieldsCount;
    if (buttonRowIndex == VLCNetworkServerLoginIndexSave) {
        return kVLCNetworkLoginViewButtonCellIdentifier;
    } else {
        return kVLCNetworkLoginViewFieldCellIdentifier;
    }
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    if ([cell isKindOfClass:[VLCNetworkLoginViewFieldCell class]]) {
        [self configureFieldCell:(id)cell forRow:row];
    } else if ([cell isKindOfClass:[VLCNetworkLoginViewButtonCell class]]) {
        [self configureButtonCell:(id)cell forRow:row];
    } else {
        NSLog(@"%s can't configure cell: %@", __PRETTY_FUNCTION__, cell);
    }
}

- (NSUInteger)willSelectRow:(NSUInteger)row
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:self.sectionIndex]];
    if ([cell isKindOfClass:[VLCNetworkLoginViewFieldCell class]]) {
        [self makeCellFirstResponder:cell];
        return NSNotFound;
    } else {
        return row;
    }
}
- (void)didSelectRow:(NSUInteger)row
{
    NSUInteger additionalFieldsCount = self.loginInformation.additionalFields.count;
    NSUInteger buttonRowIndex = row-additionalFieldsCount;
    if (buttonRowIndex == VLCNetworkServerLoginIndexSave) {
        [self.delegate saveLoginDataSource:self];
    }
}

#pragma mark - VLCNetworkLoginViewFieldCellDelegate

- (BOOL)loginViewFieldCellShouldReturn:(VLCNetworkLoginViewFieldCell *)cell
{
    if (cell.textField.returnKeyType == UIReturnKeyNext) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        [self makeCellFirstResponder:cell];
        [self.tableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        return NO;
    } else {
        return YES;
    }
}

- (void)loginViewFieldCellDidEndEditing:(VLCNetworkLoginViewFieldCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self updatedStringValue:cell.textField.text forRow:indexPath.row];
}

@end
