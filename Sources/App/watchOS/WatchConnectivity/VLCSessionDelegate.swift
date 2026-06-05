/*****************************************************************************
 * VLCSessionDelegate.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import WatchConnectivity

// Custom notifications happen when Watch Connectivity activation or reachability status changes,
// or when receiving or sending data. Clients observe these notifications to update the UI.
extension Notification.Name {
    static let dataDidFlow = Notification.Name("DataDidFlow")
    static let activationDidComplete = Notification.Name("ActivationDidComplete")
    static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
}

@objcMembers
class VLCSessionDelegate: NSObject, WCSessionDelegate {

    // Monitor WCSession activation state changes.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        postNotificationOnMainQueueAsync(name: .activationDidComplete)
    }

    // Monitor WCSession reachability state changes.
    func sessionReachabilityDidChange(_ session: WCSession) {
        postNotificationOnMainQueueAsync(name: .reachabilityDidChange)
    }

    // Did receive an app context.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        var message = VLCWatchMessage(command: .updateAppContext, phrase: .received)
        message.timedColor = TimedColor(applicationContext)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Did receive a message, and the peer doesn't need a response.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        var vlcMessage = VLCWatchMessage(command: .sendMessage, phrase: .received)
        vlcMessage.timedColor = TimedColor(message)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: vlcMessage)
    }

    // Did receive a message, and the peer needs a response.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(message) // Echo back the time stamp.
    }

    // Did receive a piece of message data, and the peer doesn't need a response.
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        var message = VLCWatchMessage(command: .sendMessageData, phrase: .received)
        message.timedColor = TimedColor(messageData)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Did receive a piece of message data, and the peer needs a response.
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(messageData) // Echo back the time stamp.
    }

    // Did receive a piece of userInfo.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        var commandStatus = VLCWatchMessage(command: .transferUserInfo, phrase: .received)
        commandStatus.timedColor = TimedColor(userInfo)

        guard let isComplicationInfo = userInfo[PayloadKey.isCurrentComplicationInfo] as? Bool,
              isComplicationInfo == true else {
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            return
        }

        // Code below shows example of updating widget
//        #if os(watchOS)
//        commandStatus.command = .transferCurrentComplicationUserInfo
//
//        guard let sharedUserDefaults = UserDefaults(suiteName: WidgetSupport.appGroupContainer) else {
//            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
//            return
//        }
//        // Persist the data to the app group container.
//        //
//        sharedUserDefaults.setValue(commandStatus.timedColor?.timeStamp, forKey: WidgetSupport.UserDefaultsKey.timestamp)
//        sharedUserDefaults.setValue(commandStatus.timedColor?.colorData, forKey: WidgetSupport.UserDefaultsKey.colorData)
//
//        // Reload the timeline of the widget, if necessary.
//        //
//        WidgetCenter.shared.getCurrentConfigurations { result in
//            switch result {
//            case .success(let widgetInfoList):
//                for widgetInfo in widgetInfoList where widgetInfo.kind == WidgetSupport.widgetKind {
//                    WidgetCenter.shared.reloadTimelines(ofKind: widgetInfo.kind)
//                }
//            case .failure(let error):
//                print(error.localizedDescription)
//            }
//        }
//        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
//        #endif
    }

    // Did finish sending a piece of userInfo.
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        var message = VLCWatchMessage(command: .transferUserInfo, phrase: .finished)
        message.timedColor = TimedColor(userInfoTransfer.userInfo)

        #if os(iOS)
        if userInfoTransfer.isCurrentComplicationInfo {
            message.command = .transferCurrentComplicationUserInfo
        }
        #endif

        if let error = error {
            message.errorMessage = error.localizedDescription
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Did receive a file.
    /**
     The OS places the files in a temporary directory (i.e. Documents/Inbox/..) for the receiving app when they are transferred.
     Make sure you move the file to a permament location (e.g. Documents/) or otherwise quickly process it before you return from this method.
     Each file will be deleted from the inbox when you return from the didReceiveFile callback in your session delegate.

     file.fileURL example: Documents/Inbox/com.apple.watchconnectivity/<UUID1>/Files/<UUID2>/<song.ext> -- file:///var/mobile/Containers/Data/Application/<UUID3>/
    **/
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Received file from iPhone: \(file.fileURL)")
        var message = VLCWatchMessage(command: .transferFile, phrase: .received)
        message.file = file

        // Can also access meta data from file
        // commandStatus.timedColor = TimedColor(file.metadata!)

        let filename = file.fileURL.lastPathComponent
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documentsDir.appendingPathComponent(filename)

        do {
            try FileManager.default.moveItem(at: file.fileURL, to: destination) // Documents/Inbox -> /Documents
            print("Sucessfully moved file \(filename) to \(documentsDir)")
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
        } catch {
            // TODO: Show some error message to user
            print("Failed to move file \(filename) to \(documentsDir): \(error)")
        }
    }

    // Did finish a file transfer.
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        var message = VLCWatchMessage(command: .transferFile, phrase: .finished)

        if let error = error {
            message.errorMessage = error.localizedDescription
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
            return
        }

        message.fileTransfer = fileTransfer
        if let metadata = fileTransfer.file.metadata {
            message.payload = metadata
        }

//        commandStatus.timedColor = TimedColor(fileTransfer.file.metadata!)

        #if os(watchOS)
//        Logger.shared.clearLogs()
        #endif
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // WCSessionDelegate methods for iOS only.
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif

    // Post a notification on the main thread asynchronously.
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: VLCWatchMessage? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}
