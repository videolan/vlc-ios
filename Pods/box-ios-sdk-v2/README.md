BoxSDK: Box API V2 iOS SDK
==========================

[![Build Status](https://travis-ci.org/box/box-ios-sdk-v2.png?branch=master)](https://travis-ci.org/box/box-ios-sdk-v2)
[![Version](https://cocoapod-badges.herokuapp.com/v/box-ios-sdk-v2/badge.png)](http://cocoadocs.org/docsets/box-ios-sdk-v2)
[![Platform](https://cocoapod-badges.herokuapp.com/p/box-ios-sdk-v2/badge.png)](http://cocoadocs.org/docsets/box-ios-sdk-v2)
[![Project Status](http://opensource.box.com/badges/maintenance.svg)](http://opensource.box.com/badges)

This SDK provides access to the [Box V2 API](https://developers.box.com/docs/).
It currently supports file, folder, user, comment, and search operations.

We have built [several sample applications with the V2 SDK](https://github.com/box/box-ios-sdk-sample-app).

## Add to your project

### CocoaPods

The easiest way to add this Box SDK to your project is with [CocoaPods](http://cocoapods.org).

Add the following to your Podfile:

```
pod 'box-ios-sdk-v2', '~> 1.2'
```

### Dependent XCode Project

An alternative (and more difficult) way to add the Box SDK to your project is as a
dependent XCode project.

1. Clone this repository into your project's directory. You can use git submodules
   if you want.
2. Open your project in XCode.
3. Drag BoxSDK.xcodeproj into the root of your project explorer.<br />![Dependent project](http://box.github.io/box-ios-sdk-v2/readme-images/dependent-project.png)

4. Add the BoxSDK project as a target dependency.<br />![Target dependency](http://box.github.io/box-ios-sdk-v2/readme-images/target-dependency.png)

5. Link with libBoxSDK.a<br />![Link with binary](http://box.github.io/box-ios-sdk-v2/readme-images/link-with-binary.png)

6. Link with QuartzCore.framework and Security.framework.

7. Add the `-ObjC` linker flag. This is needed to load categories defined in the SDK.<br />![Add linker flag](http://box.github.io/box-ios-sdk-v2/readme-images/linker-flag.png)

8. `#import <BoxSDK/BoxSDK.h>`

See our [sample applications](https://github.com/box/box-ios-sdk-sample-app) for examples of integrating
the V2 SDK. Check out the [documentation hosted on Github](http://box.github.io/box-ios-sdk-v2/) which is
also included in the source.

## Quickstart

### Configure

Set your client ID and client secret on the SDK client:

```objc
[BoxSDK sharedSDK].OAuth2Session.clientID = @"YOUR_CLIENT_ID";
[BoxSDK sharedSDK].OAuth2Session.clientSecret = @"YOUR_CLIENT_SECRET";
```

**Note**: When setting up your service on Box, make sure that your redirect URI
is set to `boxsdk-YOUR_CLIENT_ID://boxsdkoauth2redirect` and that you also set
the 'Redirect url:' value on the Box developer portal. The API will then use
this URI when issuing OAuth2 calls.

### Authenticate
To authenticate your app with Box, you need to use OAuth2. The authorization flow
happens in a `UIWebView`. To get started, you can present the sample web view the
SDK provides:

```objc
BoxAuthorizationViewController *authorizationController = [[BoxAuthorizationViewController alloc] initWithAuthorizationURL:[[BoxSDK sharedSDK].OAuth2Session authorizeURL] redirectURI:[[BoxSDK sharedSDK].OAuth2Session redirectURIString]];
authorizationController.delegate = myAuthorizationControllerDelegate;
[self presentViewController:authorizationController animated:YES completion:nil];
```

On successful authentication, the object you set as the delegate of your
BoxAuthorizationViewController will receive the '- (BOOL)authorizationViewController:(BoxAuthorizationViewController *)authorizationViewController shouldLoadReceivedOAuth2RedirectRequest:(NSURLRequest *)request'
callback:

```objc
- (BOOL)authorizationViewController:(BoxAuthorizationViewController *)authorizationViewController shouldLoadReceivedOAuth2RedirectRequest:(NSURLRequest *)request
{
    [[BoxSDK sharedSDK].OAuth2Session performAuthorizationCodeGrantWithReceivedURL:request.URL];
    return NO;
}
```

You can listen to notifications on `[BoxSDK sharedSDK].OAuth2Session` to be notified
when a user becomes successfully authenticated.

**Note**: The SDK does not store tokens. We recommend storing the refresh token in
the keychain and listening to notifications sent by the OAuth2Session. For more
information, see
[the documetation for BoxOAuth2Session](http://box.github.io/box-ios-sdk-v2/Classes/BoxOAuth2Session.html).

### Making API calls

All SDK API calls are asynchronous. They are scheduled by the SDK on an `NSOperationQueue`.
To be notified of API responses and errors, pass blocks to the SDK API call methods. These
blocks are triggered once the API response has been received by the SDK.

**Note**: callbacks are not triggered on the main thread. Wrap updates to your app's
UI in a `dispatch_sync` block on the main thread.

#### Get a folder's children

```objc
BoxCollectionBlock success = ^(BoxCollection *collection)
{
  // grab items from the collection, use the collection as a data source
  // for a table view, etc.
};

BoxAPIJSONFailureBlock failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
{
  // handle errors
};

[[BoxSDK sharedSDK].foldersManager folderItemsWithID:folderID requestBuilder:nil success:success failure:failure];
```

#### Get a file's information

```objc
BoxFileBlock success = ^(BoxFile *file)
{
  // manipulate the BoxFile.
};

BoxAPIJSONFailureBlock failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
{
  // handle errors
};

[[BoxSDK sharedSDK].filesManager fileInfoWithID:folderID requestBuilder:nil success:success failure:failure];
```

#### Edit an item's information

To send data via the API, use a request builder. If we wish to move a file and change its
name:

```objc
BoxFileBlock success = ^(BoxFile *file)
{
  // manipulate the BoxFile.
};

BoxAPIJSONFailureBlock failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
{
  // handle errors
};

BoxFilesRequestBuilder *builder = [BoxFilesRequestBuilder alloc] init];
builder.name = @"My awesome file.txt"
builder.parentID = BoxAPIFolderIDRoot;

[[BoxSDK sharedSDK].filesManager editFileWithID:folderID requestBuilder:builder success:success failure:failure];
```

#### Upload a new file

```objc
BoxFileBlock fileBlock = ^(BoxFile *file)
{
  // manipulate resulting BoxFile
};

BoxAPIJSONFailureBlock failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
{
  // handle failed upload
};

BoxAPIMultipartProgressBlock progressBlock = ^(unsigned long long totalBytes, unsigned long long bytesSent)
{
  // indicate progress of upload
};

BoxFilesRequestBuilder *builder = [[BoxFilesRequestBuilder alloc] init];
builder.name = @"Logo_Box_Blue_Whitebg_480x480.jpg";
builder.parentID = folderID;

NSString *path = [[NSBundle mainBundle] pathForResource:@"Logo_Box_Blue_Whitebg_480x480.jpg" ofType:nil];
NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];
NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
long long contentLength = [[fileAttributes objectForKey:NSFileSize] longLongValue];

[[BoxSDK sharedSDK].filesManager uploadFileWithInputStream:inputStream contentLength:contentLength MIMEType:nil requestBuilder:builder success:fileBlock failure:failureBlock progress:progressBlock];
```

#### Download a file

```objc
NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];

BoxDownloadSuccessBlock successBlock = ^(NSString *downloadedFileID, long long expectedContentLength)
{
  // handle download, preview download, etc.
};

BoxDownloadFailureBlock failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
{
  // handle download failure
};

BoxAPIDataProgressBlock progressBlock = ^(long long expectedTotalBytes, unsigned long long bytesReceived)
{
  // display progress
};

[[BoxSDK sharedSDK].filesManager downloadFileWithID:fileID outputStream:outputStream requestBuilder:nil success:successBlock failure:failureBlock progress:progressBlock];
```

### Folder Picker
An easy way to integrate Box into your app is to use the folder picker
widget included in the SDK. The folder picker provides a folder browser
that users can use to select a file or folder from their account. You can
use this folder to then make API calls.  You can find folder picker brand assets
such as buttons [here](https://cloud.box.com/picker-assets/).

The folder picker looks like this:

![Folder picker](http://box.github.io/box-ios-sdk-v2/readme-images/folder-picker.png)

See our [sample app that utilizes the folder picker](https://github.com/box/box-ios-sdk-sample-app/tree/master/BOXContracts).

#### Setup steps
In addition to the installation steps above, you must do two more things in XCode to
include the folder picker assets and icons in your app.

1. Add BoxSDKResources as a dependent target.<br />![Resource bundle dependency](http://box.github.io/box-ios-sdk-v2/readme-images/resource-bundle-dependency.png)
2. Copy the resource bundle during your app's copy files build phase.<br />![Resource bundle copy](http://box.github.io/box-ios-sdk-v2/readme-images/copy-bundle.png)

## Tests

This SDK contains unit tests that are runnable with `./bin/test.sh` or alternatively `rake spec`.

Pull requests will not be accepted unless they include test coverage.

## Documentation

Documentation for this SDK is generated using [appledoc](http://gentlebytes.com/appledoc/).
Documentation can be generated by running `./bin/generate-documentation.sh`. This script
depends on the `appledoc` binary which can be downloaded using homebrew (`brew install appledoc`).

[Documentation is hosted on this repo's github page](http://box.github.io/box-ios-sdk-v2/).

Pull requests will not be accepted unless they include documentation.

## Known issues

* There is no support for manipulating files in the trash.
* Missing support for the following endpoints:
  * Collaborations
  * Events
  * Groups
  * Tasks



## Copyright and License

Copyright 2014 Box, Inc. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
