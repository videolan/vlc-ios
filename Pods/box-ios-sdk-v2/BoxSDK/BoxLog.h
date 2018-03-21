//
//  BoxLog.h
//  BoxSDK
//
//  Created on 2/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#ifndef BoxSDK_BoxLog_h
#define BoxSDK_BoxLog_h

#ifdef DEBUG
#ifndef BOX_DISABLE_DEBUG_LOGGING
#define BOXLogFunction()        NSLog(@"%s", __FUNCTION__)
#define BOXLog(...)             NSLog(@"%s: %@", __FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define BOXLogFunction(...)
#define BOXLog(...)
#endif
#else
#define BOXLogFunction(...)
#define BOXLog(...)
#endif

#ifdef DEBUG
#define BOXAssert(x, ...)       NSAssert(x, @"%s: %@", __FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#define BOXCAssert(...)         NSCAssert(__VA_ARGS__)
#define BOXAssert1(...)         NSAssert1(__VA_ARGS__)
#define BOXAssertFail(...)      BOXAssert(NO, __VA_ARGS__)
#define BOXAbstract()           BOXAssertFail(@"Must be overridden by subclass.")
#else
#define BOXAssert(...)
#define BOXCAssert(...)
#define BOXAssert1(...)
#define BOXAssertFail(...)
#define BOXAbstract()
#endif

#endif
