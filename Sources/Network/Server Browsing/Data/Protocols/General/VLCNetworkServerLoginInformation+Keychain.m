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

#import "VLCNetworkServerLoginInformation+Keychain.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>

@implementation VLCNetworkServerLoginInformation (Keychain)


+ (instancetype)loginInformationWithKeychainIdentifier:(NSString *)keychainIdentifier
{
    NSURLComponents *components = [NSURLComponents componentsWithString:keychainIdentifier];

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:components.scheme];
    login.address = components.host;
    login.port = components.port;
    return login;
}

- (NSString *)keychainServiceIdentifier
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.protocolIdentifier;
    components.host = self.address;
    /* the login dialog may feed us with a port 0 instead of nil which will lead
     * to different URL strings compared to what VLCKit delivers, so the saved and
     * the requested password will never match */
    if (self.port && self.port.intValue > 0) {
        components.port = self.port;
    } else {
        components.port = nil;
    }
    NSString *serviceIdentifier = components.URL.absoluteString;
    return serviceIdentifier;
}

- (BOOL)loadLoginInformationFromKeychainWithError:(NSError *__autoreleasing _Nullable *)error
{
    NSError *localError = nil;
    NSString *keychainServiceIdentifier = self.keychainServiceIdentifier;
    if (!keychainServiceIdentifier) {
        *error = [NSError errorWithDomain:NSURLErrorDomain
                                     code:NSURLErrorBadURL
                                 userInfo:nil];
        return NO;
    }
    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemsForService:keychainServiceIdentifier error:&localError].firstObject;
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    if (!keychainItem) {
        return YES;
    }

    self.username = keychainItem.account;
    self.password = keychainItem.secret.stringValue;

    NSDictionary *genericAttributes = keychainItem.generic.dictionaryValue;
    for (VLCNetworkServerLoginInformationField *field in self.additionalFields) {
        id value = genericAttributes[field.identifier];
        if ([value isKindOfClass:[NSString class]]) {
            field.textValue = value;
        }
    }

    return YES;
}

- (BOOL)saveLoginInformationToKeychainWithError:(NSError *__autoreleasing  _Nullable *)error
{
    NSString *keychainServiceIdentifier = self.keychainServiceIdentifier;
    if (keychainServiceIdentifier == nil) {
        *error = [NSError errorWithDomain:NSURLErrorDomain
                                     code:NSURLErrorBadURL
                                 userInfo:nil];
        return NO;
    }

    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemForService:keychainServiceIdentifier account:self.username error:nil];
    if (!keychainItem) {
        keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
        keychainItem.service = self.keychainServiceIdentifier;
        keychainItem.account = self.username;
    }

    keychainItem.secret.stringValue = self.password;

    NSArray<VLCNetworkServerLoginInformationField *> *fields = self.additionalFields;
    NSUInteger fieldsCount = fields.count;
    if (fieldsCount) {
        NSMutableDictionary *genericAttributes = [NSMutableDictionary dictionaryWithCapacity:fieldsCount];
        for (VLCNetworkServerLoginInformationField *field in fields) {
            NSString *textValue = field.textValue;
            if (textValue) {
                genericAttributes[field.identifier] = textValue;
            }
        }
        keychainItem.generic.dictionaryValue = genericAttributes;
    }
    return [keychainItem saveWithError:error];
}

- (BOOL)deleteFromKeychainWithError:(NSError *__autoreleasing  _Nullable *)error
{
    NSString *keychainServiceIdentifier = self.keychainServiceIdentifier;
    if (!keychainServiceIdentifier) {
        *error = [NSError errorWithDomain:NSURLErrorDomain
                                     code:NSURLErrorBadURL
                                 userInfo:nil];
        return NO;
    }

    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = self.keychainServiceIdentifier;
    keychainItem.account = self.username;

    return [keychainItem deleteWithError:error];
}

@end
