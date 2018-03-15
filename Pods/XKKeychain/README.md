# XKKeychain

<!-- [![CI Status](http://img.shields.io/travis/karlvr/XKKeychain.svg?style=flat)](https://travis-ci.org/karlvr/XKKeychain) -->
[![Version](https://img.shields.io/cocoapods/v/XKKeychain.svg?style=flat)](http://cocoadocs.org/docsets/XKKeychain)
[![License](https://img.shields.io/cocoapods/l/XKKeychain.svg?style=flat)](http://cocoadocs.org/docsets/XKKeychain)
[![Platform](https://img.shields.io/cocoapods/p/XKKeychain.svg?style=flat)](http://cocoadocs.org/docsets/XKKeychain)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

XKKeychain is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "XKKeychain"

It actually isn't available through CocoaPods yet, so in the meantime use:

    pod 'XKKeychain', :git => 'https://github.com/karlvr/XKKeychain.git'


## Usage

```objc
#import <XKKeychain/XKKeychain.h>
```

### Retrieving items from the keychain

The most common keychain item type is the generic password item type. To access that we use the `XKKeychainGenericPasswordItem` class.
Each keychain item is uniquely identified by its type, the service name and the account. The service name and account are arbitrary strings.
The service name generally identifies the service, such as your app or a third party service. The account name generally identifies the account
on that service that the credentials are stored for.

The keychain item contains a `secret`. This is where you store the information that you want to protect. XKKeychain provides access to the secret
as `NSData`, `NSString`, `NSDictionary`, or `id<NSCoding>`. You may also simply use `objectForKey:` or keyed subscripting on the secret. Just be
sure to use the same method to retrieve the secret as you used to store it, as under the hood the secret is an `NSData`.

```objc
NSString * const serviceName = @"your app name, or the service you're accessing, e.g. com.twitter";
NSString * const accountName = @"the account name the credential is for, e.g. avon";
XKKeychainGenericPasswordItem *item = [XKKeychainGenericPasswordItem itemForService:serviceName account:accountName error:&error];
if (error) {
	NSLog(@"Failed to access the keychain: %@", [error localizedDescription]);
}

NSString *secretString = item.secret.stringValue;
```

You can access the secret as different types. You should access it as the same type you put in.

```objc
NSData *secretData = item.secret.dataValue;
NSDictionary *secretDictionary = item.secret.dictionaryValue;
id secretValue = item.secret[@"aKey"];
id secret = item.secret.transformableValue; /* Using NSCoding */
```

You can store additional information in the keychain item. This information isn't secret. It is found in the `generic` property, which
supports the same different value types as secrets.

```objc
NSString *myString = item.generic.stringValue;
NSData *myData = item.generic.dataValue;
NSDictionary *myDictionary = item.generic.dictionaryValue;
id myValue = item.generic[@"aKey"];
id myObject = item.generic.transformableValue; /* Using NSCoding */
```

#### Bulk

You can retrieve arrays of items from keychain.

```objc
NSError *error = nil;
NSArray *items = [XKKeychainGenericPasswordItem itemsForService:serviceName error:&error];
```

### Storing items in the keychain

```objc
XKKeychainGenericPasswordItem *item = [XKKeychainGenericPasswordItem new];
item.service = serviceName;
item.account = accountName;
item.accessible = kSecAttrAccessibleAfterFirstUnlock;
item.secret.stringValue = @"top secret";
item.generic[@"aKey"] = @"a non private value";

NSError *error = nil;
if (![item saveWithError:&error]) {
	NSLog(@"Failed to save to the keychain: %@", [error localizedDescription]);
}
```

## Author

Karl von Randow, karl@xk72.com

## License

XKKeychain is available under the MIT license. See the LICENSE file for more info.

