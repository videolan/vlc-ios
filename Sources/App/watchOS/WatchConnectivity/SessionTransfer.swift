/*
     File: SessionTransfer.swift
 Abstract: Defines the session transfer interface.

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

import Foundation
import WatchConnectivity

// Provide a unified interface for transfers. The UI uses this interface to manage transfers.
protocol SessionTransfer {
    var timedColor: TimedColor? { get }
//    var payload: [String: Any] { get }
    var isTransferring: Bool { get }
    func cancel()
    func cancel(notifying command: Command)
}

// Implement the cancel method to cancel the transfer and notify the UI.
extension SessionTransfer {
    func cancel(notifying command: Command) {
        var commandStatus = VLCWatchMessage(command: command, phrase: .canceled)
        commandStatus.timedColor = timedColor

        cancel()

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        commandStatus.timedColor?.timeStamp = dateFormatter.string(from: Date())

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dataDidFlow, object: commandStatus)
        }
    }
}

// Conform SessionTransfer, and provide a timed color.
extension WCSessionUserInfoTransfer: SessionTransfer {
    var timedColor: TimedColor? { return TimedColor(userInfo) }
//    var payload: [String: Any] { return userInfo }
}

// Conform SessionTransfer, and provide a timed color.
extension WCSessionFileTransfer: SessionTransfer {
    var timedColor: TimedColor? {
        guard let metadata = file.metadata else { return nil }
        return TimedColor(metadata)
    }

//    var payload: [String: Any] { return file.metadata ?? [:] }
}
