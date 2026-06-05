/*
     File: TestDataProvider.swift
 Abstract: Defines the interface for providing payload for Watch Connectivity APIs.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

Copyright (C) 2024 Apple Inc.
(https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity)

 */

import UIKit

// Constants to access the payload dictionary.
// isCurrentComplicationInfo tells if the userInfo is from transferCurrentComplicationUserInfo
// in session:didReceiveUserInfo: (see SessionDelegator).
struct PayloadKey {
    static let timeStamp = "timeStamp"
    static let colorData = "colorData"
    static let isCurrentComplicationInfo = "isCurrentComplicationInfo"
}

// Generate the default payload for commands. The payload contains a random color and a time stamp.
class TestDataProvider {

    // Generate a dictionary containing a time stamp and a random color data.
    static func timedColor() -> [String: Any] {
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))

        let randomColor = UIColor(red: red, green: green, blue: blue, alpha: 1)

        let data = try? NSKeyedArchiver.archivedData(withRootObject: randomColor, requiringSecureCoding: false)
        guard let colorData = data else { fatalError("Failed to archive a UIColor!") }

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let timeString = dateFormatter.string(from: Date())

        return [PayloadKey.timeStamp: timeString, PayloadKey.colorData: colorData]
    }

    // Generate an app context for updateApplicationContext.
    static func appContext() -> [String: Any] {
        return timedColor()
    }

    // Generate a message for sendMessage.
    static func message() -> [String: Any] {
        return timedColor()
    }

    // Generate a piece of message data for sendMessageData.
    static func messageData() -> Data {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: timedColor(), requiringSecureCoding: false)
        guard let timedColor = data else { fatalError("Failed to archive a timedColor dictionary!") }
        return timedColor
    }

    // Generate a userInfo dictionary for transferUserInfo.
    static func userInfo() -> [String: Any] {
        return timedColor()
    }

    // Generate a file URL for transferFile.
    // Use the log file for transferFile from the watch side.
    static func file() -> URL? {
        #if os(watchOS)
        return WatchLogger.shared.getFileURL() // Use the log file for transferFile.
        #else
        // Use Info.plist for file transfer.
        // Change this to a bigger file to make the file transfer progress more obvious.
        //
        guard let url = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
            fatalError("Failed to find Info.plist in current bundle!")
        }
        return url
        #endif
    }

    // Generate a file metadata dictionary, used as the payload for transferFile.
    static func fileMetaData() -> [String: Any] {
        return timedColor()
    }

    // Generate a complication info dictionary for transferCurrentComplicationUserInfo.
    static func currentComplicationInfo() -> [String: Any] {
        var complicationInfo = timedColor()
        complicationInfo[PayloadKey.isCurrentComplicationInfo] = true
        return complicationInfo
    }
}
