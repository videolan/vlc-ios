/*****************************************************************************
 * VLCWatchMessage.swift
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

// The object being transfered back and forth between watch and iPhone for communication
public struct VLCWatchMessage {
    var command: Command
    var phrase: Phrase
    var timedColor: TimedColor? // For testing
    var payload: [String: Any] = [:] // TODO: Keep as basic dict for now for easier testing. Should be class in future.
    var fileTransfer: WCSessionFileTransfer? // Information about in-progress file transfers. (also contains file)
    var file: WCSessionFile?
    var userInfoTranser: WCSessionUserInfoTransfer?
    var errorMessage: String?

    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}

// Constants to identify the Watch Connectivity methods, also for user-visible strings in UI.
enum Command: String, Codable {
    case updateAppContext = "UpdateAppContext"
    case sendMessage = "SendMessage"
    case sendMessageData = "SendMessageData"
    case transferUserInfo = "TransferUserInfo"
    case transferFile = "TransferFile"
    case transferCurrentComplicationUserInfo = "TransferComplicationUserInfo"
}

// Constants to identify the phrases of Watch Connectivity communication.
enum Phrase: String, Codable {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
}
