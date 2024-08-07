/*****************************************************************************
 * NSURLSessionConfiguration+default.m
 * VLC for iOS
 *****************************************************************************
 *
 * Author: Anthony Doeraene <anthony.doeraene@hotmail.com>
 *
 *****************************************************************************/

#import <Foundation/Foundation.h>
#include "NSURLSessionConfiguration+default.h"

@implementation NSURLSessionConfiguration (defaultMPTCPConfiguration)
+ (NSURLSessionConfiguration *) defaultMPTCPConfiguration {
    static NSURLSessionConfiguration *defaultMPTCPConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        #if TARGET_OS_IOS
            // multipath is only supported on iOS 11.0+
            if (@available(iOS 11.0, *)) {
                conf.multipathServiceType = NSURLSessionMultipathServiceTypeHandover;
            }
        #endif
        // on other platforms, the defaultMPTCPConfiguration is simply [NSURLSessionConfiguration defaultSessionConfiguration], which is a standard TCP configuration
            
        defaultMPTCPConfiguration = conf;
    });
    return defaultMPTCPConfiguration;
}
@end
