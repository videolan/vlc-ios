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

    var mlSyncManager: MLSyncManagerProtocol?

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
        var message = VLCWatchMessage(command: .transferUserInfo, phrase: .received)
        message.payload = userInfo
//        commandStatus.timedColor = TimedColor(userInfo)

        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)

//        guard let isComplicationInfo = userInfo[PayloadKey.isCurrentComplicationInfo] as? Bool,
//              isComplicationInfo == true else {
//            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
//            return
//        }

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
//        message.timedColor = TimedColor(userInfoTransfer.userInfo)

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
        print("VLCSessionDelegate: didReceive file: \(file.fileURL)")
        var message = VLCWatchMessage(command: .transferFile, phrase: .received)
        message.file = file
        if let metadata = file.metadata {
            message.payload = metadata
        }

        guard let iphoneLibrarySyncId = message.payload[kVLCMediaLibrarySyncID] as? String else {
            preconditionFailure("VLCSessionDelegate: Missing \(kVLCMediaLibrarySyncID) in payload")
        }

        if let watchLibrarySyncId = mlSyncManager?.state.librarySyncId,
           watchLibrarySyncId != "" {
            // If another iPhone attempts to transfer file to watch, reset library sync ids
            if watchLibrarySyncId != iphoneLibrarySyncId {
                print("\(kVLCMediaLibrarySyncID) are different")
                // TODO: Reset library sync mappings or ignore?
                return
            }
        } else {
            // watch has not linked to an iphone yet, link them now
            mlSyncManager?.saveMLSyncState(
                MLSyncState(
                    librarySyncId: iphoneLibrarySyncId,
                    mediaSyncIds: [],
                    albumsSyncIds: [],
                    artistSyncIds: [],
                    pendingMediaTransfers: [:]
                )
            )
        }

        guard let messageTypeString = message.payload[kVLCWatchMessageType] as? String else {
            preconditionFailure("VLCSessionDelegate: Missing \(kVLCWatchMessageType) in payload")
        }

        guard let messageType = WatchMessageType(rawValue: messageTypeString) else {
            preconditionFailure("VLCSessionDelegate: Invalid WatchMessageType \"\(messageTypeString)\"")
        }

        // At this point, the MLSyncState should exist
        switch messageType {
        case .transferAudioFile:
            handleTransferAudioFile(message: message)
        case .transferiPhoneMediaLibraryDBFile:
            handleTransferSnapshotMediaLibraryDBFile(message: message)
        }
    }

    private func handleTransferAudioFile(message: VLCWatchMessage) {
        // iPhone sent audio file to watch
        guard let file = message.file else {
            preconditionFailure("VLCSessionDelegate: Missing file in payload")
        }
        let mediaFileName = file.fileURL.lastPathComponent
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let destination = documentsDir.appendingPathComponent(mediaFileName)

        do {
            try FileManager.default.moveItem(at: file.fileURL, to: destination) // Documents/Inbox -> /Documents
            print("VLCSession delegate handleTransferAudioFile: \(message.payload)")
            if let iphoneMediaID = message.payload[kVLCiPhoneMediaID] as? VLCMLIdentifier,
               let filename = message.payload[kVLCiPhoneMediaFileName] as? String,
               let iphoneAlbumID = message.payload[kVLCiPhoneAlbumID] as? VLCMLIdentifier,
               let iphoneAlbumName = message.payload[kVLCiPhoneAlbumName] as? String,
               let iphoneArtistID = message.payload[kVLCiPhoneArtistID] as? VLCMLIdentifier,
               let iphoneArtistName = message.payload[kVLCiPhoneArtistName] as? String
            {
                print("mlSyncManager.didReceiveFile timmy")
                mlSyncManager?.didReceiveFile(
                    iphoneMediaId: iphoneMediaID,
                    filename: filename,
                    iphoneAlbumID: iphoneAlbumID,
                    albumName: iphoneAlbumName,
                    iphoneArtistID: iphoneArtistID,
                    artistName: iphoneArtistName
                )
            }

            print("handleTransferAudioFile: Sucessfully moved file \(mediaFileName) to \(documentsDir)")
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
        } catch {
            // TODO: Show some error message to user
            print("handleTransferAudioFile: Failed to move file \(mediaFileName) to \(documentsDir): \(error)")
        }
        return
    }

    private func handleTransferSnapshotMediaLibraryDBFile(message: VLCWatchMessage) {
        guard let file = message.file else {    // medialibrary.db
            preconditionFailure("VLCSessionDelegate: Missing file in payload")
        }

        // Move medialibrary-iphone-snapshot.db file to /Library/MediaLibrarySnapshot/
        guard let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }

        let mediaLibraryDir = libraryDir
            .appendingPathComponent("MediaLibrarySnapshot")

        do {
            try FileManager.default.createDirectory(at: mediaLibraryDir, withIntermediateDirectories: true)

            let destination = mediaLibraryDir
                .appendingPathComponent(kVLCSnapshotMediaLibraryDBFileName) // medialibrary-snapshot.db

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            try FileManager.default.moveItem(at: file.fileURL, to: destination)

            print("handleTransferiPhoneMediaLibraryDBFile: Sucessfully moved file \(file.fileURL) to \(destination)")
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
            VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService = MediaLibraryService(libraryType: .snapshotLibrary)
            mlSyncManager?.loadMLSyncState()
        } catch {
            print("handleTransferiPhoneMediaLibraryDBFile: Failed to move file \(file.fileURL) to \(libraryDir): \(error)")
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

extension Notification.Name {
    static let VLCDidUpdateMLSyncStateNotification = Notification.Name("VLCDidUpdateMLSyncStateNotification")
    static let VLCWatchDidAddTracksNotification = Notification.Name("VLCWatchDidAddTracksNotification")
    static let VLCWatchDidAddAlbumsNotification = Notification.Name("VLCWatchDidAddAlbumsNotification")
    static let VLCWatchDidAddArtistsNotification = Notification.Name("VLCWatchDidAddArtistsNotification")
}
