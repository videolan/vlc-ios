/*****************************************************************************
* ExtensionDelegate.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Tobias Conradi <videolan # tobias-conradi.de>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import WatchKit
import WatchConnectivity
import CoreData

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        WCSession.defaultSession().delegate = self;
        WCSession.defaultSession().activateSession()

    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        let msg = VLCWatchMessage(dictionary: message)
        if msg.name == VLCWatchMessageNameNotification, let payloadDict = msg.payload as? [String : AnyObject] {
            if let name = payloadDict["name"] as? String {
                handleRemoteNotification(name, userInfo: payloadDict["userInfo"] as? [String : AnyObject])
            }
        }
    }

    func handleRemoteNotification(name:String, userInfo: [String: AnyObject]?) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: self, userInfo: userInfo)
    }


    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // TODO: copy db and send update notification
    }
}
