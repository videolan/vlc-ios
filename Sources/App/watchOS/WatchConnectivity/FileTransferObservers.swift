/*
     File: FileTransferObservers.swift
 Abstract: Manages the observation of the file transfer progress.

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

// Manages the observation of the file transfer progress.
class FileTransferObservers: ObservableObject {

    // Hold the observations and file transfers.
    // The system removes KVO automatically after releasing the observations.
    @Published private var fileTransferObervations = [WCSessionFileTransfer: NSKeyValueObservation]()
    @Published private(set) var progresssDescriptions = [WCSessionFileTransfer: String]()

    private var observations: [NSKeyValueObservation] {
        return Array(fileTransferObervations.values)
    }

    var fileTransfers: [WCSessionFileTransfer] {
        return Array(fileTransferObervations.keys)
    }

    // Invalidate all the observations.
    deinit {
        observations.forEach { observation in
            observation.invalidate()
        }
    }

    // Observe a file transfer, and hold the observation.
    func observe(_ fileTransfer: WCSessionFileTransfer, handler: ((Progress) -> Void)? = nil) {
        progresssDescriptions[fileTransfer] = fileTransfer.progress.localizedDescription
        let observation = fileTransfer.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.progresssDescriptions[fileTransfer] = progress.localizedDescription
                handler?(progress)
            }
        }
        if let existingObservation = fileTransferObervations[fileTransfer] {
            existingObservation.invalidate()
        }
        fileTransferObervations[fileTransfer] = observation
    }

    // Un-observe a file transfer, and invalidate the observation.
    func unobserve(_ fileTransfer: WCSessionFileTransfer) {
        if let observation = fileTransferObervations[fileTransfer] {
            observation.invalidate()
            fileTransferObervations[fileTransfer] = nil
        }
        progresssDescriptions[fileTransfer] = nil
    }

    func observe(_ fileTransfers: [WCSessionFileTransfer]) {
        for fileTransfer in fileTransfers {
            observe(fileTransfer)
        }
    }

    func reset() {
        observations.forEach { observation in
            observation.invalidate()
        }
        fileTransferObervations = [:]
        progresssDescriptions = [:]
    }
}
