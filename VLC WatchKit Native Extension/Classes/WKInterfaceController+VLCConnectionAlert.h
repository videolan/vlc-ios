/*****************************************************************************
 * WKInterfaceController+VLCConnectionAlert.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>

@interface WKInterfaceController (VLCConnectionAlert)
/*+*
 * Same as method below, with nil as default okActionBlock
 ***/
- (void)vlc_performBlockIfSessionReachable:(void(^__nullable)())reachableBlock
                      showUnreachableAlert:(BOOL)unreachableAlert;

/*+*
 * check if the default session is reachable ^== iPhone connected to Watch
 * If the session is reachable, perform the block.
 * If the session is unreachable, show a unreachable alert if unreachable alert
 * is true.
 * okActionBlock is executed if the session is unreachable, the alert was 
 * presented and the user pressed the ok button.
 ***/
- (void)vlc_performBlockIfSessionReachable:(void(^__nullable)())reachableBlock
                      showUnreachableAlert:(BOOL)unreachableAlert
                             alertOKAction:(void(^__nullable)())okActionBlock;

@end
