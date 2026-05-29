/*****************************************************************************
 * VLCWatchConnectivityService.swift
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


class VLCWatchConnectivityService {

    // Update the app context if the session is activated, and update UI with the command status.
    func updateAppContext(_ context: [String: Any]) {
        var message = VLCWatchMessage(command: .updateAppContext, phrase: .updated)
        message.timedColor = TimedColor(context)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: message)
        }

        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            message.phrase = .failed
            message.errorMessage = error.localizedDescription
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Send a message if the session is activated, and update the UI with the command status.
    func sendMessage(_ message: [String: Any]) {
        var vlcMessage = VLCWatchMessage(command: .sendMessage, phrase: .sent)
        vlcMessage.timedColor = TimedColor(message)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: vlcMessage)
        }

        // A reply handler block runs asynchronously on a background thread and should return quickly.
        WCSession.default.sendMessage(message, replyHandler: { replyMessage in
            vlcMessage.phrase = .replied
            vlcMessage.timedColor = TimedColor(replyMessage)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: vlcMessage)
        }, errorHandler: { error in
            vlcMessage.phrase = .failed
            vlcMessage.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: vlcMessage)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: vlcMessage)
    }

    // Send a piece of message data if the session is activated, and update the UI with the command status.
    func sendMessageData(_ messageData: Data) {
        var message = VLCWatchMessage(command: .sendMessageData, phrase: .sent)
        message.timedColor = TimedColor(messageData)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: message)
        }

        // A reply handler block runs asynchronously on a background thread and should return quickly.
        WCSession.default.sendMessageData(messageData, replyHandler: { replyData in
            message.phrase = .replied
            message.timedColor = TimedColor(replyData)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
        }, errorHandler: { error in
            message.phrase = .failed
            message.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Transfer a piece of user info if the session is activated, and update the UI with the command status.
    // Returns a WCSessionUserInfoTransfer object to monitor the progress or cancel the operation.
    func transferUserInfo(_ userInfo: [String: Any]) {
        var message = VLCWatchMessage(command: .transferUserInfo, phrase: .transferring)
        message.timedColor = TimedColor(userInfo)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: message)
        }

        message.userInfoTranser = WCSession.default.transferUserInfo(userInfo)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Transfer a file if the session is activated, and update the UI with the command status.
    // Return a WCSessionFileTransfer object to monitor the progress or cancel the operation.
    func transferFile(_ file: URL, metadata: [String: Any]) {
        var message = VLCWatchMessage(command: .transferFile, phrase: .transferring)
        message.timedColor = TimedColor(metadata)
        message.payload = metadata

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: message)
        }

        message.fileTransfer = WCSession.default.transferFile(file, metadata: metadata)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Transfer a piece of user info for current complications if the session is activated,
    // and update the UI with the command status.
    // Return a WCSessionUserInfoTransfer object to monitor the progress or cancel the operation.
    func transferCurrentComplicationUserInfo(_ userInfo: [String: Any]) {
        var message = VLCWatchMessage(command: .transferCurrentComplicationUserInfo, phrase: .failed)
        message.timedColor = TimedColor(userInfo)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: message)
        }

        message.errorMessage = "Not supported on watchOS!"

        #if os(iOS)
        if WCSession.default.isComplicationEnabled {
            let userInfoTranser = WCSession.default.transferCurrentComplicationUserInfo(userInfo)
            message.phrase = .transferring
            message.errorMessage = nil
            message.userInfoTranser = userInfoTranser

        } else {
            message.errorMessage = "\nComplication is not enabled!"
        }
        #endif

        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }

    // Post a notification on the main thread asynchronously.
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: VLCWatchMessage? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }

    // Handle unactivated session error. WCSession commands require an activated session.
    private func handleSessionUnactivated(with message: VLCWatchMessage) {
        var mutableMessage = message
        mutableMessage.phrase = .failed
        mutableMessage.errorMessage = "WCSession is not activated yet!"
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: mutableMessage)
    }
}
