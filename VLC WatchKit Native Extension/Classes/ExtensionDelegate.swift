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
import MediaLibraryKit

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
        let fileType = file.metadata?["filetype"] as? String ?? ""
        if fileType == "coredata" {
            copyUpdatedCoreDataDBFromURL(file.fileURL)
        }
    }

    func copyUpdatedCoreDataDBFromURL(url:NSURL) {
        let library = MLMediaLibrary.sharedMediaLibrary()
        do {
            //  we can be sure that it's only the sqlite file and no -wal -shm etc. therefore we can just plain copy it.
            if NSFileManager.defaultManager().fileExistsAtPath(library.persistentStoreURL!.absoluteString) {
                try NSFileManager.defaultManager().replaceItemAtURL(library.persistentStoreURL, withItemAtURL: url, backupItemName: nil, options: NSFileManagerItemReplacementOptions.UsingNewMetadataOnly, resultingItemURL: nil)
            } else {
                try NSFileManager.defaultManager().copyItemAtURL(url, toURL: library.persistentStoreURL)
            }
        } catch {
            print("failed to copy Core Data DB to new DB location on watch")
        }
        NSNotificationCenter.defaultCenter().postNotificationName(VLCDBUpdateNotification, object: self)
    }

}
