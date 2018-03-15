# Dropbox for Objective-C

The ~~Official~~ Dropbox Objective-C SDK for integrating with Dropbox [API v2](https://www.dropbox.com/developers/documentation/http/documentation) on iOS or macOS.

Full documentation [here](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/).

---

## Table of Contents

* [System requirements](#system-requirements)
  * [Xcode 8 and iOS 10 bug](#xcode-8-and-ios-10-bug)
* [Get started](#get-started)
  * [Register your application](#register-your-application)
  * [Obtain an OAuth 2.0 token](#obtain-an-oauth-20-token)
* [SDK distribution](#sdk-distribution)
  * [CocoaPods](#cocoapods)
  * [Carthage](#carthage)
  * [Manually add subproject](#manually-add-subproject)
* [Configure your project](#configure-your-project)
  * [Application `.plist` file](#application-plist-file)
  * [Handling the authorization flow](#handling-the-authorization-flow)
    * [Initialize a `DBUserClient` instance](#initialize-a-dbuserclient-instance)
    * [Begin the authorization flow](#begin-the-authorization-flow)
    * [Handle redirect back into SDK](#handle-redirect-back-into-sdk)
* [Try some API requests](#try-some-api-requests)
  * [Dropbox client instance](#dropbox-client-instance)
  * [Handle the API response](#handle-the-api-response)
  * [Request types](#request-types)
    * [RPC-style request](#rpc-style-request)
    * [Upload-style request](#upload-style-request)
    * [Download-style request](#download-style-request)
    * [Note about background sessions](#note-about-background-sessions)
  * [Handling responses and errors](#handling-responses-and-errors)
    * [Route-specific errors](#route-specific-errors)
    * [Generic network request errors](#generic-network-request-errors)
    * [Response handling edge cases](#response-handling-edge-cases)
    * [Consistent global error handling](#consistent-global-error-handling)
  * [Customizing network calls](#customizing-network-calls)
    * [Configure network client](#configure-network-client)
    * [Specify API call response queue](#specify-api-call-response-queue)
  * [`DBClientsManager` class](#dbclientsmanager-class)
    * [Single Dropbox user case](#single-dropbox-user-case)
    * [Multiple Dropbox user case](#multiple-dropbox-user-case)
* [Examples](#examples)
* [Migrating from API v1](#migrating-from-api-v1)
    * [Migrating OAuth tokens from earlier SDKs](#migrating-oauth-tokens-from-earlier-sdks)
* [Documentation](#documentation)
* [Stone](#stone)
* [Modifications](#modifications)
* [Bugs](#bugs)

---

## System requirements

- iOS 7.0+
- macOS 10.10+
- Xcode 7.3+

---

### Xcode 8 and iOS 10 bugs

#### Keychain bug
The Dropbox Objective-C SDK currently supports Xcode 8 and iOS 10. However, there appears to be a bug with the Keychain in the iOS simulator environment where data is not persistently saved to the Keychain.

As a temporary workaround, in the Project Navigator, select **your project** > **Capabilities** > **Keychain Sharing** > **ON**.

You can read more about the bug [here](https://forums.developer.apple.com/message/170381#170381).

#### Longpoll session timeout bug
Currently, there is a bug with iOS 10 where our longpoll requests timeout after ~6 minutes (instead of our max supported timeframe of 8 minutes (480 seconds)).

For this reason, we recommend that all longpoll calls be made using [`-listFolderLongpoll:timeout:`](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESRoutes.html#/c:objc(cs)DBFILESRoutes(im)listFolderLongpoll:timeout:), with a specified `timeout` values of <= 300 seconds (5 minutes), until this issue is resolved by Apple.

Read more about the issue [here](https://forums.developer.apple.com/thread/67606).

## Get started

### Register your application

Before using this SDK, you should register your application in the [Dropbox App Console](https://dropbox.com/developers/apps). This creates a record of your app with Dropbox that will be associated with the API calls you make.

### Obtain an OAuth 2.0 token

All requests need to be made with an OAuth 2.0 access token. An OAuth token represents an authenticated link between a Dropbox app and
a Dropbox user account or team.

Once you've created an app, you can go to the App Console and manually generate an access token to authorize your app to access your own Dropbox account.
Otherwise, you can obtain an OAuth token programmatically using the SDK's pre-defined auth flow. For more information, [see below](https://github.com/dropbox/dropbox-sdk-obj-c#handling-authorization-flow).

---

## SDK distribution

You can integrate the Dropbox Objective-C SDK into your project using one of several methods.

### CocoaPods

To use [CocoaPods](http://cocoapods.org), a dependency manager for Cocoa projects, you should first install it using the following command:

```bash
$ gem install cocoapods
```

Then navigate to the directory that contains your project and create a new file called `Podfile`. You can do this either with `pod init`, or open an existing Podfile, and then add `pod 'ObjectiveDropboxOfficial'` to the main loop. Your Podfile should look something like this:

##### iOS

```ruby
platform :ios, '9.0'
use_frameworks!

target '<YOUR_PROJECT_NAME>' do
    pod 'ObjectiveDropboxOfficial'
end
```

##### macOS

```ruby
platform :osx, '10.10'
use_frameworks!

target '<YOUR_PROJECT_NAME>' do
    pod 'ObjectiveDropboxOfficial'
end
```

Then, after ensuring that your project window in Xcode is **closed**, run the following command to install the dependency:

```bash
$ pod install
```

Once this command completes, open the newly create `.xcworkspace` file. Your project should now be successfully integrated with the the SDK.

From here, you can pull SDK updates using the following command:

```bash
$ pod update
```

##### Common issues

###### Undefined architecture

If Xcode errors with a message about `Undefined symbols for architecture...`, try the following:

- Project Navigator > build target > **Build Settings** > **Other Linker Flags** add `$(inherited)` and `-ObjC`.

---

### Carthage

You can also integrate the Dropbox Objective-C SDK into your project using [Carthage](https://github.com/Carthage/Carthage), a decentralized dependency manager for Cocoa. Carthage offers more flexibility than CocoaPods, but requires some additional work. You can install Carthage (with Xcode 7+) via [Homebrew](http://brew.sh/):

```bash
brew update
brew install carthage
```

 To install the Dropbox Objective-C SDK via Carthage, you need to create a `Cartfile` in your project with the following contents:

```
# ObjectiveDropboxOfficial
github "https://github.com/dropbox/dropbox-sdk-obj-c" ~> 3.2.0
```

Then, run the following command to checkout and build the Dropbox Objective-C SDK repository:

##### iOS

```bash
carthage update --platform iOS
```

In the Project Navigator in Xcode, select your project, and then navigate to **General** > **Linked Frameworks and Libraries**, then drag and drop `ObjectiveDropboxOfficial.framework` (from `Carthage/Build/iOS`).

Then, navigate to **Build Phases** > **+** > **New Run Script Phase**. In the newly-created **Run Script** section, add the following code to the script body area (beneath the "Shell" box):

```
/usr/local/bin/carthage copy-frameworks
```

Then, navigate to the **Input Files** section and add the following path:

```
$(SRCROOT)/Carthage/Build/iOS/ObjectiveDropboxOfficial.framework
```

##### macOS
```bash
carthage update --platform Mac
```

In the Project Navigator in Xcode, select your project, and then navigate to **General** > **Embedded Binaries**, then drag and drop `ObjectiveDropboxOfficial.framework` (from `Carthage/Build/Mac`).

Then navigate to **Build Phases** > **+** > **New Copy Files Phase**. In the newly-created **Copy Files** section, click the **Destination** drop-down menu and select **Products Directory**, then drag and drop `ObjectiveDropboxOfficial.framework.dSYM` (from `Carthage/Build/Mac`).

##### Common issues

###### Linking errors

Please make sure the SDK is inside of your Xcode project folder, otherwise your app may run into linking errors.

If you wish to keep the SDK outside of your Xcode project folder (perhaps to share between different apps), you will need to configure your a few environmental variables.

- Project Navigator > build target > **Build Settings** > **Header Search Path** add `$(PROJECT_DIR)/../<PATH_TO_SDK>/dropbox-sdk-obj-c/Source/ObjectiveDropboxOfficial (recursive)`

- Project Navigator > build target > **Build Settings** > **Framework Search Paths** add `$(PROJECT_DIR)/../<PATH_TO_SDK>/dropbox-sdk-obj-c/Source/ObjectiveDropboxOfficial/build/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME) (non-recursive)`

###### dyld: Library not loaded error

If you receive a run-time error message like `dyld: Library not loaded:`, please try the following:

- Add ObjectiveDropboxOfficial framework to **Embedded Binaries** as well as **Linked Frameworks and Libraries**.
- Project Navigator > build target > **Build Settings** > **Linking** > **Runpath Search Paths** add `$(inherited) @executable_path/Frameworks`.

---

### Manually add subproject

Finally, you can also integrate the Dropbox Objective-C SDK into your project manually with the help of Carthage. Please take the following steps:

Create a `Cartfile` in your project with the same contents as the Cartfile listed in the [Carthage](#carthage) section of the README.

Then, run the following command to checkout and build the Dropbox Objective-C SDK repository:

##### iOS

```bash
carthage update --platform iOS
```
Once you have checked-out out all the necessary code via Carthage, drag the `Carthage/Checkouts/ObjectiveDropboxOfficial/Source/ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.xcodeproj` file into your project as a subproject.

Then, in the Project Navigator in Xcode, select your project, and then navigate to your project's build target > **General** > **Linked Frameworks and Libraries** > **+** and then add the `ObjectiveDropboxOfficial.framework` file for the iOS platform.

##### macOS
```bash
carthage update --platform Mac
```

Once you have checked-out out all the necessary code via Carthage, drag the `Carthage/Checkouts/ObjectiveDropboxOfficial/Source/ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.xcodeproj` file into your project as a subproject.

Then, in the Project Navigator in Xcode, select your project, and then navigate to your project's build target > **General** > **Embedded Binaries** > **+** and then add the `ObjectiveDropboxOfficial.framework` file for the macOS platform.

---

## Configure your project

Once you have integrated the Dropbox Objective-C SDK into your project, there are a few additional steps to take before you can begin making API calls.

### Application `.plist` file

You will need to modify your application's `.plist` to handle Apple's [new security changes](https://developer.apple.com/videos/wwdc/2015/?id=703) to the `canOpenURL` function. You should
add the following code to your application's `.plist` file:

```
<key>LSApplicationQueriesSchemes</key>
    <array>
        <string>dbapi-8-emm</string>
        <string>dbapi-2</string>
    </array>
```
This allows the Objective-C SDK to determine if the official Dropbox iOS app is installed on the current device. If it is installed, then the official Dropbox iOS app can be used to programmatically obtain an OAuth 2.0 access token.

Additionally, your application needs to register to handle a unique Dropbox URL scheme for redirect following completion of the OAuth 2.0 authorization flow. This URL scheme should have the format `db-<APP_KEY>`, where `<APP_KEY>` is your
Dropbox app's app key, which can be found in the [App Console](https://dropbox.com/developers/apps).

You should add the following code to your `.plist` file (but be sure to replace `<APP_KEY>` with your app's app key):

```
<key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>db-<APP_KEY></string>
            </array>
            <key>CFBundleURLName</key>
            <string></string>
        </dict>
    </array>
```

After you've made the above changes, your application's `.plist` file should look something like this:

<p align="center">
  <img src="https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/Images/InfoPlistExample.png?raw=true" alt="Info .plist Example"/>
</p>

---

### Handling the authorization flow

There are three methods to programmatically retrieve an OAuth 2.0 access token:

* **Direct auth** (iOS only): This launches the official Dropbox iOS app (if installed), authenticates via the official app, then redirects back into the SDK
* **Safari view controller auth** (iOS only): This launches a `SFSafariViewController` to facillitate the auth flow. This is desirable because it is safer for the end-user, and pre-existing session data can be used to avoid requiring the user to re-enter their Dropbox credentials.
* **Redirect to external browser** (macOS only): This launches the user's default browser to facillitate the auth flow. This is also desirable because it is safer for the end-user, and pre-existing session data can be used to avoid requiring the user to re-enter their Dropbox credentials.

To facilitate the above authorization flows, you should take the following steps:

---

#### Initialize a `DBUserClient` instance

##### iOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [DBClientsManager setupWithAppKey:@"<APP_KEY>"];
  return YES;
}

```

##### macOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [DBClientsManager setupWithAppKeyDesktop:@"<APP_KEY>"];
}
```

---

#### Begin the authorization flow

You can commence the auth flow by calling `authorizeFromController:controller:openURL` method in your application's
view controller.

##### iOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (void)myButtonInControllerPressed {
  [DBClientsManager authorizeFromController:[UIApplication sharedApplication]
                                 controller:self
                                    openURL:^(NSURL *url) {
                                      [[UIApplication sharedApplication] openURL:url];
                                    }];
}

```

##### macOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (void)myButtonInControllerPressed {
  [DBClientsManager authorizeFromControllerDesktop:[NSWorkspace sharedWorkspace]
                                        controller:self
                                           openURL:^(NSURL *url){ [[NSWorkspace sharedWorkspace] openURL:url]; }];
}
```

Beginning the authentication flow on mobile will launch a window like this:


<p align="center">
  <img src="https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/Images/OAuthFlowInit.png?raw=true" alt="Auth Flow Init Example"/>
</p>

---

#### Handle redirect back into SDK

To handle the redirection back into the Objective-C SDK once the authentication flow is complete, you should add the following code in your application's delegate:

##### iOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
  DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
  if (authResult != nil) {
    if ([authResult isSuccess]) {
      NSLog(@"Success! User is logged into Dropbox.");
    } else if ([authResult isCancel]) {
      NSLog(@"Authorization flow was manually canceled by user!");
    } else if ([authResult isError]) {
      NSLog(@"Error: %@", authResult);
    }
  }
  return NO;
}
```

##### macOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

// generic launch handler
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                     andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                   forEventClass:kInternetEventClass
                                                      andEventID:kAEGetURL];
}

// custom handler
- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
  NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
  DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
  if (authResult != nil) {
    if ([authResult isSuccess]) {
      NSLog(@"Success! User is logged into Dropbox.");
    } else if ([authResult isCancel]) {
      NSLog(@"Authorization flow was manually canceled by user!");
    } else if ([authResult isError]) {
      NSLog(@"Error: %@", authResult);
    }
    // this forces your app to the foreground, after it has handled the browser redirect
    [[NSRunningApplication currentApplication]
        activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
  }
}
```

After the end user signs in with their Dropbox login credentials on mobile, they will see a window like this:


<p align="center">
  <img src="https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/Images/OAuthFlowApproval.png?raw=true" alt="Auth Flow Approval Example"/>
</p>

If they press **Allow** or **Cancel**, the `db-<APP_KEY>` redirect URL will be launched from the view controller, and will be handled in your application
delegate's `application:handleOpenURL` method, from which the result of the authorization can be parsed.

Now you're ready to begin making API requests!

---

## Try some API requests

Once you have obtained an OAuth 2.0 token, you can try some API v2 calls using the Objective-C SDK.

### Dropbox client instance

Start by creating a reference to the `DBUserClient` or `DBTeamClient` instance that you will use to make your API calls.

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

// Reference after programmatic auth flow
DBUserClient *client = [DBClientsManager authorizedClient];
```

or

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

// Initialize with manually retrieved auth token
DBUserClient *client = [[DBUserClient alloc] initWithAccessToken:@"<MY_ACCESS_TOKEN>"];
```

---

### Handle the API response

The Dropbox [User API](https://www.dropbox.com/developers/documentation/http/documentation) and [Business API](https://www.dropbox.com/developers/documentation/http/teams) have three types of requests: RPC, Upload and Download.

The response handlers for each request type are similar to one another. The arguments for the handler blocks are as follows:
* **route result type** (`DBNilObject` if the route does not have a return type)
* **route-specific error** (usually a union type)
* **network request error** (generic to all requests -- contains information like request ID, HTTP status code, etc.)
* **output content** (`NSURL` / `NSData` reference to downloaded output for Download-style endpoints only)

Response handlers are required for all endpoints. Progress handlers, on the other hand, are optional for all endpoints.

> Note: The Objective-C SDK uses `NSNumber` objects in place of boolean values. This is done so that nullability can be represented in some of our API response values. For this reason, you should be careful when writing checks like `if (myAPIObject.isSomething)`, which is checking nullability rather than value. Instead, you should use `if ([myAPIObject.isSomething boolValue])`, which converts the `NSNumber` field to a boolean value before using it in the if check.

---

### Request types

#### RPC-style request

```objective-c
[[client.filesRoutes createFolder:@"/test/path/in/Dropbox/account"]
    setResponseBlock:^(DBFILESFolderMetadata *result, DBFILESCreateFolderError *routeError, DBRequestError *networkError) {
      if (result) {
        NSLog(@"%@\n", result);
      } else {
        NSLog(@"%@\n%@\n", routeError, networkError);
      }
    }];
```

[-createFolder:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)createFolder:)

Here's an example for listing a folder's contents. In the response handler, we repeatedly call `listFolderContinue:` (for large folders) until we've listed the entire folder:

```objective-c
[[client.filesRoutes listFolder:@"/test/path/in/Dropbox/account"]
    setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderError *routeError, DBRequestError *networkError) {
      if (response) {
        NSArray<DBFILESMetadata *> *entries = response.entries;
        NSString *cursor = response.cursor;
        BOOL hasMore = [response.hasMore boolValue];

        [self printEntries:entries];

        if (hasMore) {
          NSLog(@"Folder is large enough where we need to call `listFolderContinue:`");

          [self listFolderContinueWithClient:client cursor:cursor];
        } else {
          NSLog(@"List folder complete.");
        }
      } else {
        NSLog(@"%@\n%@\n", routeError, networkError);
      }
    }];

...
...
...

- (void)listFolderContinueWithClient:(DBUserClient *)client cursor:(NSString *)cursor {
  [[client.filesRoutes listFolderContinue:cursor]
      setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderContinueError *routeError,
                         DBRequestError *networkError) {
        if (response) {
          NSArray<DBFILESMetadata *> *entries = response.entries;
          NSString *cursor = response.cursor;
          BOOL hasMore = [response.hasMore boolValue];

          [self printEntries:entries];

          if (hasMore) {
            [self listFolderContinueWithClient:client cursor:cursor];
          } else {
            NSLog(@"List folder complete.");
          }
        } else {
          NSLog(@"%@\n%@\n", routeError, networkError);
        }
      }];
}

- (void)printEntries:(NSArray<DBFILESMetadata *> *)entries {
  for (DBFILESMetadata *entry in entries) {
    if ([entry isKindOfClass:[DBFILESFileMetadata class]]) {
      DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)entry;
      NSLog(@"File data: %@\n", fileMetadata);
    } else if ([entry isKindOfClass:[DBFILESFolderMetadata class]]) {
      DBFILESFolderMetadata *folderMetadata = (DBFILESFolderMetadata *)entry;
      NSLog(@"Folder data: %@\n", folderMetadata);
    } else if ([entry isKindOfClass:[DBFILESDeletedMetadata class]]) {
      DBFILESDeletedMetadata *deletedMetadata = (DBFILESDeletedMetadata *)entry;
      NSLog(@"Deleted data: %@\n", deletedMetadata);
    }
  }
}
```

[-listFolder:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)listFolder:) and [-listFolderContinue:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)listFolder:)

---

#### Upload-style request

```objective-c
NSData *fileData = [@"file data example" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];

// For overriding on upload
DBFILESWriteMode *mode = [[DBFILESWriteMode alloc] initWithOverwrite];

[[[client.filesRoutes uploadData:@"/test/path/in/Dropbox/account/my_output.txt"
                            mode:mode
                      autorename:@(YES)
                  clientModified:nil
                            mute:@(NO)
                       inputData:fileData]
    setResponseBlock:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *networkError) {
      if (result) {
        NSLog(@"%@\n", result);
      } else {
        NSLog(@"%@\n%@\n", routeError, networkError);
      }
    }] setProgressBlock:^(int64_t bytesUploaded, int64_t totalBytesUploaded, int64_t totalBytesExpectedToUploaded) {
  NSLog(@"\n%lld\n%lld\n%lld\n", bytesUploaded, totalBytesUploaded, totalBytesExpectedToUploaded);
}];
```

[-uploadData:mode:autorename:clientModified:mute:inputData:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)uploadData:mode:autorename:clientModified:mute:inputData:)

Here's an example of an advanced upload case for "batch" uploading a large number of files:

```objective-c
NSMutableDictionary<NSURL *, DBFILESCommitInfo *> *uploadFilesUrlsToCommitInfo = [NSMutableDictionary new];
DBFILESCommitInfo *commitInfo = [[DBFILESCommitInfo alloc] initWithPath:@"/output/path/in/Dropbox/file.txt"];
[uploadFilesUrlsToCommitInfo setObject:commitInfo forKey:[NSURL fileURLWithPath:@"/local/path/to/file.txt"]];

[client.filesRoutes batchUploadFiles:uploadFilesUrlsToCommitInfo
    queue:nil
    progressBlock:^(int64_t uploaded, int64_t uploadedTotal, int64_t expectedToUploadTotal) {
      NSLog(@"Uploaded: %lld  UploadedTotal: %lld  ExpectedToUploadTotal: %lld", uploaded, uploadedTotal,
            expectedToUploadTotal);
    }
    responseBlock:^(NSDictionary<NSURL *, DBFILESUploadSessionFinishBatchResultEntry *> *fileUrlsToBatchResultEntries,
                    DBASYNCPollError *finishBatchRouteError, DBRequestError *finishBatchRequestError,
                    NSDictionary<NSURL *, DBRequestError *> *fileUrlsToRequestErrors) {
      if (fileUrlsToBatchResultEntries) {
        NSLog(@"Call to `/upload_session/finish_batch/check` succeeded");
        for (NSURL *clientSideFileUrl in fileUrlsToBatchResultEntries) {
          DBFILESUploadSessionFinishBatchResultEntry *resultEntry = fileUrlsToBatchResultEntries[clientSideFileUrl];
          if ([resultEntry isSuccess]) {
            NSString *dropboxFilePath = resultEntry.success.pathDisplay;
            NSLog(@"File successfully uploaded from %@ on local machine to %@ in Dropbox.",
                  [clientSideFileUrl path], dropboxFilePath);
          } else if ([resultEntry isFailure]) {
            // This particular file was not uploaded successfully, although the other
            // files may have been uploaded successfully. Perhaps implement some retry
            // logic here based on `uploadNetworkError` or `uploadSessionFinishError`
            DBRequestError *uploadNetworkError = fileUrlsToRequestErrors[clientSideFileUrl];
            DBFILESUploadSessionFinishError *uploadSessionFinishError = resultEntry.failure;

            // implement appropriate retry logic
          }
        }
      }

      if (finishBatchRouteError) {
        NSLog(@"Either bug in SDK code, or transient error on Dropbox server");
        NSLog(@"%@", finishBatchRouteError);
      } else if (finishBatchRequestError) {
        NSLog(@"Request error from calling `/upload_session/finish_batch/check`");
        NSLog(@"%@", finishBatchRequestError);
      } else if ([fileUrlsToRequestErrors count] > 0) {
        NSLog(@"Other additional errors (e.g. file doesn't exist client-side, etc.).");
        NSLog(@"%@", fileUrlsToRequestErrors);
      }
    }];
```

> Note: the `batchUploadFiles:` route method that is used above automatically chunk-uploads large files, something other upload methods in the SDK do **not** do. Also, with this route, response and progress handlers are passed directly into the route as arguments, and not via the `setResponseBlock` or `setProgressBlock` methods.

[-batchUploadFiles:queue:progressBlock:responseBlock:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)batchUploadFiles:queue:progressBlock:responseBlock:)

---

#### Download-style request

Here's an example for downloading to a file (`NSURL`):

```objective-c
NSFileManager *fileManager = [NSFileManager defaultManager];
NSURL *outputDirectory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
NSURL *outputUrl = [outputDirectory URLByAppendingPathComponent:@"test_file_output.txt"];

[[[client.filesRoutes downloadUrl:@"/test/path/in/Dropbox/account/my_file.txt" overwrite:YES destination:outputUrl]
    setResponseBlock:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError, DBRequestError *networkError,
                       NSURL *destination) {
      if (result) {
        NSLog(@"%@\n", result);
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:[destination path]];
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@\n", dataStr);
      } else {
        NSLog(@"%@\n%@\n", routeError, networkError);
      }
    }] setProgressBlock:^(int64_t bytesDownloaded, int64_t totalBytesDownloaded, int64_t totalBytesExpectedToDownload) {
  NSLog(@"%lld\n%lld\n%lld\n", bytesDownloaded, totalBytesDownloaded, totalBytesExpectedToDownload);
}];
```

[-downloadUrl:rev:overwrite:destination:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)downloadUrl:rev:overwrite:destination:)

Here's an example for downloading straight to memory (`NSData`):

```objective-c
[[[client.filesRoutes downloadData:@"/test/path/in/Dropbox/account/my_file.txt"]
    setResponseBlock:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError, DBRequestError *networkError,
                       NSData *fileContents) {
      if (result) {
        NSLog(@"%@\n", result);
        NSString *dataStr = [[NSString alloc] initWithData:fileContents encoding:NSUTF8StringEncoding];
        NSLog(@"%@\n", dataStr);
      } else {
        NSLog(@"%@\n%@\n", routeError, networkError);
      }
    }] setProgressBlock:^(int64_t bytesDownloaded, int64_t totalBytesDownloaded, int64_t totalBytesExpectedToDownload) {
  NSLog(@"%lld\n%lld\n%lld\n", bytesDownloaded, totalBytesDownloaded, totalBytesExpectedToDownload);
}];
```

[-downloadData:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)downloadData:)

---

#### Note about background sessions

Currently, the SDK uses a background `NSURLSession` to perform all download tasks and some upload tasks (including upload from a file, but not from memory or from a stream). Background sessions use a separate process to handle all data transfers. This is conveneient because when your app enters the background, the download / upload will continue.

However, the timeout periods for a background `NSURLSession` are virtually unlimited, so if you lose your network connection, the error handler will never be executed. Instead, the process will wait for a restored connection, and then resume from there.

If you're looking for more responsive error feedback in the event of a lost connection, you will want to force all requests onto a foreground `NSURLSession`. See the example in the [network configuration](#configure-network-client) section of the README for how to do this.

To read more, please consult Apple's [documentation](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/UsingNSURLSession.html).

**NOTE:** You should test all background session behavior on **an actual test device** and **not** the Xcode simulator, which has a lot of buggy behavior when it comes to handling background session behavior.

### Handling responses and errors

Dropbox API v2 deals largely with two data types: **structs** and **unions**. Broadly speaking, most route **arguments** are struct types and most route **errors** are union types.

**NOTE:** In this context, "structs" and "unions" are terms specific to the Dropbox API, and not to any of the languages that are used to query the API, so you should avoid thinking of them in terms of their Objective-C definitions.

**Struct types** are "traditional" object types, that is, composite types made up of a collection of one or more instance fields. All public instance fields are accessible at runtime, regardless of runtime state.

**Union types**, on the other hand, represent a single value that can take on multiple value types, depending on state. We capture all of these different type scenarios under one "union object", but that object will exist only as one type at runtime. Each union state type, or **tag**, may have an associated value (if it doesn't, the union state type is said to be **void**). Associated value types can either be primitives, structs or unions. Although the Objective-C SDK represents union types as objects with multiple instance fields, at most one instance field is accessible at runtime, depending on the tag state of the union.

For example, the [/delete](https://www.dropbox.com/developers/documentation/http/documentation#files-delete) endpoint returns an error, `DeleteError`, which is a union type. The `DeleteError` union can take on two different tag states: `path_lookup`
(if there is a problem looking up the path) or `path_write` (if there is a problem writing -- or in this case deleting -- to the path). Here, both tag states have non-void associated values (of types `DBFILESLookupError` and `DBFILESWriteError`, respectively).

In this way, one union object is able to capture a multitude of scenarios, each of which has their own value type.

To properly handle union types, you should call each of the `is<TAG_STATE>` methods associated with the union. Once you have determined the current tag state of the union, you can then safely access the value associated with that tag state (provided there exists an associated value type, i.e., it's not **void**).
If at run time you attempt to access a union instance field that is not associated with the current tag state, **an exception will be thrown**. See below:

---

#### Route-specific errors
```objective-c
[[client.filesRoutes delete_:@"/test/path/in/Dropbox/account"]
    setResponseBlock:^(DBFILESMetadata *result, DBFILESDeleteError *routeError, DBRequestError *networkError) {
      if (result) {
        NSLog(@"%@\n", result);
      } else {
        // Error is with the route specifically (status code 409)
        if (routeError) {
          if ([routeError isPathLookup]) {
            // Can safely access this field
            DBFILESLookupError *pathLookup = routeError.pathLookup;
            NSLog(@"%@\n", pathLookup);
          } else if ([routeError isPathWrite]) {
            DBFILESWriteError *pathWrite = routeError.pathWrite;
            NSLog(@"%@\n", pathWrite);

            // This would cause a runtime error
            // DBFILESLookupError *pathLookup = routeError.pathLookup;
          }
        }
        NSLog(@"%@\n%@\n", routeError, networkError);
      }
    }];
```

[-delete_:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBFILESUserAuthRoutes.html#/c:objc(cs)DBFILESUserAuthRoutes(im)downloadData:)

---

#### Generic network request errors

In the case of a network error, regardless of whether the error is specific to the route, a generic `DBRequestError` type will always be returned, which includes information like Dropbox request ID and HTTP status code.

The `DBRequestError` type is a special union type which is similar to the standard API v2 union type, but also includes a collection of `as<TAG_STATE>` methods, each of which returns a new instance of a particular error subtype.
As with accessing associated values in regular unions, the `as<TAG_STATE>` should only be called after the corresponding `is<TAG_STATE>` method returns true. See below:

```objective-c
[[client.filesRoutes delete_:@"/test/path/in/Dropbox/account"]
    setResponseBlock:^(DBFILESMetadata *result, DBFILESDeleteError *routeError, DBRequestError *networkError) {
      if (result) {
        NSLog(@"%@\n", result);
      } else {
        if (routeError) {
          // see handling above
        }
        // Error not specific to the route (status codes 500, 400, 401, 403, 404, 429)
        else {
          if ([networkError isInternalServerError]) {
            DBRequestInternalServerError *internalServerError = [networkError asInternalServerError];
            NSLog(@"%@\n", internalServerError);
          } else if ([networkError isBadInputError]) {
            DBRequestBadInputError *badInputError = [networkError asBadInputError];
            NSLog(@"%@\n", badInputError);
          } else if ([networkError isAuthError]) {
            DBRequestAuthError *authError = [networkError asAuthError];
            NSLog(@"%@\n", authError);
          } else if ([networkError isAccessError]) {
            DBRequestAccessError *accessError = [networkError asAccessError];
            NSLog(@"%@\n", accessError);
          } else if ([networkError isRateLimitError]) {
            DBRequestRateLimitError *rateLimitError = [networkError asRateLimitError];
            NSLog(@"%@\n", rateLimitError);
          } else if ([networkError isHttpError]) {
            DBRequestHttpError *genericHttpError = [networkError asHttpError];
            NSLog(@"%@\n", genericHttpError);
          } else if ([networkError isClientError]) {
            DBRequestClientError *genericLocalError = [networkError asClientError];
            NSLog(@"%@\n", genericLocalError);
          }
        }
      }
    }];
```

---

#### Response handling edge cases

Some routes return union types as result types, so you should be prepared to handle these results in the same way that you handle union route errors. Please consult the [documentation](https://www.dropbox.com/developers/documentation/http/documentation)
for each endpoint that you use to ensure you are properly handling the route's response type.

A few routes return result types that are **datatypes with subtypes**, that is, structs that can take on multiple state types like unions.

For example, the [/delete](https://www.dropbox.com/developers/documentation/http/documentation#files-delete) endpoint returns a generic `Metadata` type, which can exist either as a `FileMetadata` struct, a `FolderMetadata` struct, or a `DeletedMetadata` struct.
To determine at runtime which subtype the `Metadata` type exists as, perform an `isKindOfClass` check for each possible class, and then cast the result accordingly. See below:

```objective-c
[[client.filesRoutes delete_:@"/test/path/in/Dropbox/account"]
    setResponseBlock:^(DBFILESMetadata *result, DBFILESDeleteError *routeError, DBRequestError *networkError) {
      if (result) {
        if ([result isKindOfClass:[DBFILESFileMetadata class]]) {
          DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)result;
          NSLog(@"File data: %@\n", fileMetadata);
        } else if ([result isKindOfClass:[DBFILESFolderMetadata class]]) {
          DBFILESFolderMetadata *folderMetadata = (DBFILESFolderMetadata *)result;
          NSLog(@"Folder data: %@\n", folderMetadata);
        } else if ([result isKindOfClass:[DBFILESDeletedMetadata class]]) {
          DBFILESDeletedMetadata *deletedMetadata = (DBFILESDeletedMetadata *)result;
          NSLog(@"Deleted data: %@\n", deletedMetadata);
        }
      } else {
        if (routeError) {
          // see handling above
        } else {
          // see handling above
        }
      }
    }];
```

This `Metadata` object is known as a **datatype with subtypes** in our API v2 documentation.

Datatypes with subtypes are a way combining structs and unions. Datatypes with subtypes are struct objects that contain a tag, which specifies which subtype the object exists as at runtime. The reason we have this construct, as with unions, is so we can capture a multitude of scenarios with one object.

In the above example, the `Metadata` type can exists as `FileMetadata`, `FolderMetadata` or `DeleteMetadata`. Each of these types have common instances fields like "name" (the name for the file, folder or deleted type), but also instance fields that are specific to the particular subtype. In order to leverage inheritance, we set a common supertype called `Metadata` which captures all of the common instance fields, but also has a tag instance field, which specifies which subtype the object currently exists as.

In this way, datatypes with subtypes are a hybrid of structs and unions. Only a few routes return result types like this.

---

#### Consistent global error handling

Normally, errors are handled on a request-by-request basis by calling `setResponseBlock` on the returned request task object. Sometimes, however, it makes more sense to handle errors consistently, based on error type, regardless of the source of the request. For instance, maybe you want to display the same dialog every time there is a `/files/list_folder` error. Or perhaps every time there is an HTTP auth error, you simply want to log the user out of your application.

To implement these examples, you should have code in your app's setup logic (probably in your app delegate) that looks something like the following:

```objective-c
void (^listFolderGlobalResponseBlock)(DBFILESListFolderError *, DBRequestError *, DBTask *) =
    ^(DBFILESListFolderError *folderError, DBRequestError *networkError, DBTask *restartTask) {
      if (folderError) {
        // Display some dialog relating to this error
      }
    };

void (^networkGlobalResponseBlock)(DBRequestError *, DBTask *) =
    ^(DBRequestError *networkError, DBTask *restartTask) {
      if ([networkError isAuthError]) {
        // log the user out of the app, for instance
        [DBClientsManager unlinkAndResetClients];
      } else if ([networkError isRateLimitError]) {
        // automatically retry after backoff period
        DBRequestRateLimitError *rateLimitError = [networkError asRateLimitError];
        int backOff = [rateLimitError.retryAfter intValue];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, backOff * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [restartTask restart];
        });
      }
    };

// one response block per error type to globally handle
[DBGlobalErrorResponseHandler registerRouteErrorResponseBlock:listFolderGlobalResponseBlock
                                               routeErrorType:[DBFILESListFolderError class]];

// only one response block total to handle all network errors
[DBGlobalErrorResponseHandler registerNetworkErrorResponseBlock:networkGlobalResponseBlock];
```

The SDK allows you to set one response block to handle all generic network errors that aren't route-specific (like an HTTP auth error, or a rate-limit error). The SDK also allows you to set a response block to be executed in the event that a certain error type is returned.

These global response blocks will automatically be executed **in addition** to the response block that you supply for the specific request.

---

### Customizing network calls

#### Configure network client

It is possible to configure the networking client used by the SDK to make API requests. You can supply custom fields like a custom user agent or custom delegate queue to manage response handler code.

For instance, you can force the SDK to make all network requests on a foreground session:

##### iOS
```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

DBTransportDefaultConfig *transportConfig =
    [[DBTransportDefaultConfig alloc] initWithAppKey:@"<APP_KEY>" forceForegroundSession:YES];
[DBClientsManager setupWithTransportConfig:transportConfig];
```

##### macOS
```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

DBTransportDefaultConfig *transportConfig =
    [[DBTransportDefaultConfig alloc] initWithAppKey:@"<APP_KEY>" forceForegroundSession:YES];
[DBClientsManager setupWithTransportConfigDesktop:transportConfig];
```

See the `DBTransportDefaultConfig` class for all of the different customizable networking parameters.

#### Specify API call response queue

By default, response/progress handler code runs on the main thread. You can set a custom response queue for each API call that you make via the `setResponseBlock` method, in the event want your response/progress handler code to run on a different thread:

```objective-c
[[client.filesRoutes listFolder:@""]
    setResponseBlock:^(DBFILESListFolderResult *result, DBFILESListFolderError *routeError, DBRequestError *networkError) {
      if (result) {
        NSLog(@"%@", [NSThread currentThread]); // Output: <NSThread: 0x600000261480>{number = 5, name = (null)}
        NSLog(@"%@", [NSThread mainThread]);    // Output: <NSThread: 0x618000062bc0>{number = 1, name = (null)}
        NSLog(@"%@\n", result);
      }
    } queue:[NSOperationQueue new]]
```

---

### `DBClientsManager` class

The Objective-C SDK includes a convenience class, `DBClientsManager`, for integrating the different functions of the SDK into one class.

#### Single Dropbox user case

For most apps, it is reasonable to assume that only one Dropbox account (and access token) needs to be managed at a time. In this case, the `DBClientsManager` flow looks like this: 

* call `setupWithAppKey`/`setupWithAppKeyDesktop` (or `setupWithTeamAppKey`/`setupWithTeamAppKeyDesktop`) in integrating app's app delegate
* `DBClientsManager` class determines whether any access tokens are stored -- if any exist, one token is arbitrarily chosen to use for the `authorizedClient` / `authorizedTeamClient` shared instance
* if no token is found, client of the SDK should call `authorizeFromController`/`authorizeFromControllerDesktop` to initiate the OAuth flow
* if auth flow is initiated, client of the SDK should call `handleRedirectURL` (or `handleRedirectURLTeam`) in integrating app's app delegate to handle auth redirect back into the app and store the retrieved access token
* `DBClientsManager` class sets up a `DBUserClient` (or `DBTeamClient`) with the particular network configuration as defined by the `DBTransportDefaultConfig` instance passed in (or a standard configuration, if no config instance was passed when the `setupWith...` method was called)

The `DBUserClient` (or `DBTeamClient`) is then used to make all of the desired API calls.

* call `unlinkAndResetClients` to logout Dropbox user and clear all access tokens

#### Multiple Dropbox user case

For some apps, it is necessary to manage more than one Dropbox account (and access token) at a time. In this case, the `DBClientsManager` flow looks like this: 

* access token uids are managed by the app that is integrating with the SDK for later lookup
* call `setupWithAppKey`/`setupWithAppKeyDesktop` (or `setupWithTeamAppKey`/`setupWithTeamAppKeyDesktop`) in integrating app's app delegate
* `DBClientsManager` class determines whether any access tokens are stored -- if any exist, one token is arbitrarily chosen to use for the `authorizedClient` / `authorizedTeamClient` shared instance
* `DBClientsManager` class also populates `authorizedClients` / `authorizedTeamClients` shared dictionary from all tokens stored in keychain, if any exist
* if no token is found, client of the SDK should call `authorizeFromController`/`authorizeFromControllerDesktop` to initiate the OAuth flow
* if auth flow is initiated, call `handleRedirectURL` (or `handleRedirectURLTeam`) in integrating app's app delegate to handle auth redirect back into the app and store the retrieved access token
* at this point, the app that is integrating with the SDK should persistently save the `tokenUid` from the `DBAccessToken` field of the `DBOAuthResult` object returned from the `handleRedirectURL` (or `handleRedirectURLTeam`) method
* `DBClientsManager` class sets up a `DBUserClient` (or `DBTeamClient`) with the particular network configuration as defined by the `DBTransportDefaultConfig` instance passed in (or a standard configuration, if no config instance was passed when the `setupWith...` method was called) and saves it to the list of authorized clients

The `DBUserClient`s (or `DBTeamClient`s) in `authorizedClients` / `authorizedTeamClients` is then used to make all of the desired API calls.

* call `unlinkAndResetClient` to logout a particular Dropbox user and clear their access token
* call `unlinkAndResetClients` to logout all Dropbox users and clear all access tokens

---

## Examples

Example projects that demonstrate how to integrate your app with the SDK can be found in the `Examples/` folder.

* [DBRoulette](https://github.com/dropbox/dropbox-sdk-obj-c/tree/master/Examples/DBRoulette/) - Play a fun game of photo roulette with the image files in your Dropbox!

---

## Migrating from API v1

This section contains relevant info for migrating your app from API v1 to API v2 (which should be finished by June 28, 2017, when API v1 will be retired).

For a general API v1 migration guide, please see [here](https://www.dropbox.com/developers/reference/migration-guide).

### Migrating OAuth tokens from earlier SDKs

If your app was originally using an earlier API v1 SDK, including the [iOS Core SDK](https://www.dropbox.com/developers-v1/core/sdks/ios), the [OS X Core SDK](https://www.dropbox.com/developers-v1/core/sdks/osx), the [iOS Sync SDK](https://www.dropbox.com/developers-v1/sync/sdks/ios), or the [OS X Sync SDK](https://www.dropbox.com/developers-v1/sync/sdks/osx), then you can use the v2 SDK to perform a one-time migration of OAuth 1 tokens to OAuth 2.0 tokens, which are used by API v2. That way, when you migrate your app from the earlier SDK to the new API v2 SDK, users will not need to reauthenticate with Dropbox after you perform this update.

To perform this auth token migration, in your app delegate, you should call the following method:

[+checkAndPerformV1TokenMigration:queue:appKey:appSecret:](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/Classes/DBClientsManager.html#/c:objc(cs)DBClientsManager(cm)checkAndPerformV1TokenMigration:queue:appKey:appSecret:)

```objective-c
BOOL willPerformMigration = [DBClientsManager checkAndPerformV1TokenMigration:^(BOOL shouldRetry, BOOL invalidAppKeyOrSecret,
                                                    NSArray<NSArray<NSString *> *> *unsuccessfullyMigratedTokenData) {
  if (invalidAppKeyOrSecret) {
    // Developers should ensure that the appropriate app key and secret are being supplied.
    // If your app has multiple app keys / secrets, then run this migration method for
    // each app key / secret combination, and ignore this boolean.
  }

  if (shouldRetry) {
    // Store this BOOL somewhere to retry when network connection has returned
  }

  if ([unsuccessfullyMigratedTokenData count] != 0) {
    NSLog(@"The following tokens were unsucessfully migrated:");
    for (NSArray<NSString *> *tokenData in unsuccessfullyMigratedTokenData) {
      NSLog(@"DropboxUserID: %@, AccessToken: %@, AccessTokenSecret: %@, StoredAppKey: %@", tokenData[0],
            tokenData[1], tokenData[2], tokenData[3]);
    }
  }

  if (!invalidAppKeyOrSecret && !shouldRetry && [unsuccessfullyMigratedTokenData count] == 0) {
    [DBClientsManager setupWithAppKey:@"<APP_KEY>"];
  }
} queue:nil appKey:@"<APP_KEY>" appSecret:@"<APP_SECRET>"];

if (!willPerformMigration) {
  [DBClientsManager setupWithAppKey:@"<APP_KEY>"];
}
```

This method should successfully migrate all access tokens stored by the official Dropbox API SDKs from approximately 2012 until present, for both iOS and OS X. It will make one call to our OAuth 1 conversion endpoint for each OAuth 1 token that has been stored in your application's keychain by the v1 SDK. The method will execute all network requests off the main thread.

Here, token migration is treated as an atomic operation. Either all tokens that are possible to migrate are migrated at once, or none of them are. If all token conversion requests complete successfully, then the `shouldRetry` argument in `responseBlock` will be `NO`. If some token conversion requests succeed and some fail, and if the failures are for any reason other than network connectivity issues (e.g. token has been invalidated), then the migration will continue normally, and those tokens that were unsuccessfully migrated will be skipped, and `shouldRetry` will be `NO`. If any of the failures were because of network connectivity issues, none of the tokens will be migrated, and `shouldRetry` will be `YES`.

---

## Documentation

* [Dropbox API v2 Objective-C SDK](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/)
* [Dropbox API v2](https://www.dropbox.com/developers/documentation/http/documentation)

---

## Stone

All of our routes and data types are auto-generated using a framework called [Stone](https://github.com/dropbox/stone).

The `stone` repo contains all of the Objective-C specific generation logic, and the `spec` repo contains the language-neutral API endpoint specifications which serve
as input to the language-specific generators.

---

## Modifications

If you're interested in modifying the SDK codebase, you should take the following steps:

* clone this GitHub repository to your local filesystem
* run `git submodule init` and then `git submodule update`
* navigate to `TestObjectiveDropbox` and run `pod install`
* open `TestObjectiveDropbox/TestObjectiveDropbox.xcworkspace` in Xcode
* implement your changes to the SDK source code.

To ensure your changes have not broken any existing functionality, you can run a series of integration tests by
following the instructions listed in the `ViewController.m` file.

---

## Code generation

If you're interested in manually generating the SDK serialization logic, perform the following:

* clone this GitHub repository to your local filesystem
* run `git submodule init` and then `git submodule update`
* navigate to the [Stone GitHub repo](https://github.com/dropbox/stone), and install all necessary dependencies
* run `./generate_base_client.py` to generate code

To ensure your changes have not broken any existing functionality, you can run a series of integration tests by
following the instructions listed in the `ViewController.m` file.

---

## Bugs

Please post any bugs to the [issue tracker](https://github.com/dropbox/dropbox-sdk-obj-c/issues) found on the project's GitHub page.
  
Please include the following with your issue:
 - a description of what is not working right
 - sample code to help replicate the issue

Thank you!

