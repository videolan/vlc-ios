/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>

#import <CoreFoundation/CoreFoundation.h>

#import "DBSDKReachability.h"

#pragma mark IPv6 Support
// DBSDKReachability fully support IPv6.  For full details, see ReadMe.md.

NSString *kDBSDKReachabilityChangedNotification = @"kNetworkReachabilityChangedNotification";

#pragma mark - Supporting functions

#define kShouldPrintReachabilityFlags 1

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char *comment) {
#if kShouldPrintReachabilityFlags

  NSLog(@"DBSDKReachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
#if TARGET_OS_IOS
        (flags & kSCNetworkReachabilityFlagsIsWWAN) ? 'W' : '-',
#else
        0,
#endif
        (flags & kSCNetworkReachabilityFlagsReachable) ? 'R' : '-',

        (flags & kSCNetworkReachabilityFlagsTransientConnection) ? 't' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? 'c' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) ? 'C' : '-',
        (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ? 'D' : '-',
        (flags & kSCNetworkReachabilityFlagsIsLocalAddress) ? 'l' : '-',
        (flags & kSCNetworkReachabilityFlagsIsDirect) ? 'd' : '-', comment);
#endif
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
#pragma unused(target, flags)
  NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
  NSCAssert([(__bridge NSObject *)info isKindOfClass:[DBSDKReachability class]],
            @"info was wrong class in ReachabilityCallback");

  DBSDKReachability *noteObject = (__bridge DBSDKReachability *)info;
  // Post a notification to notify the client that the network reachability changed.
  [[NSNotificationCenter defaultCenter] postNotificationName:kDBSDKReachabilityChangedNotification object:noteObject];
}

#pragma mark - DBSDKReachability implementation

@implementation DBSDKReachability {
  SCNetworkReachabilityRef _reachabilityRef;
}

- (void)dealloc {
  CFRelease(_reachabilityRef);
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName {
  DBSDKReachability *returnValue = NULL;
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
  if (reachability != NULL) {
    returnValue = [[self alloc] init];
    if (returnValue != NULL) {
      returnValue->_reachabilityRef = reachability;
    } else {
      CFRelease(reachability);
    }
  }
  return returnValue;
}

+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress {
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, hostAddress);

  DBSDKReachability *returnValue = NULL;

  if (reachability != NULL) {
    returnValue = [[self alloc] init];
    if (returnValue != NULL) {
      returnValue->_reachabilityRef = reachability;
    } else {
      CFRelease(reachability);
    }
  }
  return returnValue;
}

+ (instancetype)reachabilityForInternetConnection {
  struct sockaddr_in zeroAddress;
  bzero(&zeroAddress, sizeof(zeroAddress));
  zeroAddress.sin_len = sizeof(zeroAddress);
  zeroAddress.sin_family = AF_INET;

  return [self reachabilityWithAddress:(const struct sockaddr *)&zeroAddress];
}

#pragma mark reachabilityForLocalWiFi
// reachabilityForLocalWiFi has been removed from the sample.  See ReadMe.md for more information.
//+ (instancetype)reachabilityForLocalWiFi

#pragma mark - Start and stop notifier

- (BOOL)startNotifier {
  BOOL returnValue = NO;
  SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

  if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
    if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
      returnValue = YES;
    }
  }

  return returnValue;
}

- (void)stopNotifier {
  if (_reachabilityRef != NULL) {
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  }
}

#pragma mark - Network Flag Handling

- (DBNetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
  PrintReachabilityFlags(flags, "networkStatusForFlags");
  if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
    // The target host is not reachable.
    return DBNotReachable;
  }

  DBNetworkStatus returnValue = DBNotReachable;

  if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
    /*
If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
*/
    returnValue = DBReachableViaWiFi;
  }

  if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
       (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
    /*
     ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or
     higher APIs...
     */

    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
      /*
       ... and no [user] intervention is needed...
       */
      returnValue = DBReachableViaWiFi;
    }
  }

#if TARGET_OS_IOS
  if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
    /*
... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
*/
    returnValue = DBReachableViaWWAN;
  }
#endif

  return returnValue;
}

- (BOOL)connectionRequired {
  NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
    return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
  }

  return NO;
}

- (DBNetworkStatus)currentReachabilityStatus {
  NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
  DBNetworkStatus returnValue = DBNotReachable;
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
    returnValue = [self networkStatusForFlags:flags];
  }

  return returnValue;
}

@end
