/*
     File: WatchLogger.swift
 Abstract: A debug utility for writing logs into a log file.

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

// WKWatchConnectivityRefreshBackgroundTask mostly happens when the watch app is in the background,
// and background task budget is limited, so Xcode isn't suitable for debugging in this case.
//
class WatchLogger {

    static let shared = WatchLogger()
    private var fileHandle: FileHandle?

    private init() {
        guard let fileURL else { return }
        fileHandle = try? FileHandle(forUpdating: fileURL)
    }

    // Return the folder URL, and create the folder if it doesn't exist yet.
    // Return nil to trigger a crash if the folder creation fails.
    //
    private var _folderURL: URL?
    private var folderURL: URL? {
        guard _folderURL == nil else { return _folderURL }

        var folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        folderURL.appendPathComponent("Logs")
        // .../Documents/Logs

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create the log folder: \(folderURL)! \n\(error)")
                return nil // To trigger crash.
            }
        }
        _folderURL = folderURL
        return folderURL
    }

    // Return the file URL, and create the file if it doesn't exist yet.
    // Return nil to trigger a crash if the file creation fails.
    //
    private var _fileURL: URL?
    private var fileURL: URL? {
        guard _fileURL == nil else { return _fileURL }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())

        guard let folderURL = self.folderURL else { return nil }
        var fileURL: URL = folderURL
        fileURL.appendPathComponent("\(dateString).log")

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            if !FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) {
                print("Failed to create the log file: \(fileURL)!")
                return nil // To trigger crash.
            }
        }
        _fileURL = fileURL
        return fileURL
    }

    // Avoid creating DateFormatter frequently, as Logger counts into the execution budget.
    //
    private lazy var timeStampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()

    // Use this dispatch queue to make the log file access thread-safe.
    // Public methods use performBlockAndWait to access the resource; private methods don't.
    //
    private lazy var ioQueue: DispatchQueue = {
        return DispatchQueue(label: "ioQueue")
    }()

    private func performBlockAndWait<T>(_ block: () -> T) -> T {
        return ioQueue.sync {
            return block()
        }
    }

    // Get the current log file URL.
    //
    func getFileURL() -> URL? {
        return performBlockAndWait {
            return fileURL
        }
    }

    // Append a line of text to the end of the file.
    // Use FileHandle to seek to the end directly.
    //
    func append(line: String) {
        guard let fileHandle = self.fileHandle else { return }
        let timeStamp = timeStampFormatter.string(from: Date())
        let timedLine = timeStamp + ": " + line + "\n"

        if let data = timedLine.data(using: .utf8) {
            performBlockAndWait {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
        }
    }

    // Read the file content and return it as a string.
    //
    func content() -> String {
        guard let fileHandle = self.fileHandle else { return "" }
        return performBlockAndWait {
            fileHandle.seek(toFileOffset: 0) // Read from the very beginning.
            return String(data: fileHandle.availableData, encoding: .utf8) ?? ""
        }
    }

    // Clear all logs. Reset the folder and file URL for later use.
    //
    func clearLogs() {
        guard let fileHandle = self.fileHandle,
              let folderURL = self.folderURL,
              let fileURL = self.fileURL
        else { return }
        performBlockAndWait {
            fileHandle.closeFile()
            do {
                try FileManager.default.removeItem(at: folderURL)
            } catch {
                print("Failed to clear the log folder!\n\(error)")
            }

            // Create a new file handle.
            //
            self._folderURL = nil
            self._fileURL = nil
            self.fileHandle = try? FileHandle(forUpdating: fileURL)
            assert(self.fileHandle != nil, "Failed to create the file handle!")
        }
    }
}
