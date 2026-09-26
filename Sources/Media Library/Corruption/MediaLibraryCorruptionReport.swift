/*****************************************************************************
 * MediaLibraryCorruptionReport.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

enum MediaLibraryCorruptionReason: String {
    case databaseCorrupted = "database-corrupted"
    case setupFailed = "setup-failed"
    case unhandledException = "unhandled-exception"
}

class MediaLibraryCorruptionReport {
    private static let directoryName = "MediaLibraryCorruptionReport"
    private static let metadataFileName = "report.json"
    private static let logFileName = "medialibrary.log"
    private static let databaseSuffixes = ["", "-shm", "-wal", "-journal"]

    private static var directory: URL? {
        let searchPaths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        guard let basePath = searchPaths.first else {
            return nil
        }

        return URL(fileURLWithPath: basePath).appendingPathComponent(directoryName)
    }

    static var isPending: Bool {
        guard let directory = directory else {
            return false
        }

        return FileManager.default.fileExists(atPath: directory.appendingPathComponent(metadataFileName).path)
    }

    static func preserve(databasePath: String,
                         reason: MediaLibraryCorruptionReason,
                         details: String?,
                         log: [String]) {
        guard let directory = directory else {
            return
        }

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: directory)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch let error as NSError {
            APLog("MediaLibraryCorruptionReport: Failed to create \(directory.path): \(error.localizedDescription)")
            return
        }

        var preservedFiles: [String: NSNumber] = [:]
        for suffix in databaseSuffixes {
            let sourcePath = databasePath + suffix
            guard fileManager.fileExists(atPath: sourcePath) else {
                continue
            }

            let fileName = (sourcePath as NSString).lastPathComponent
            do {
                try fileManager.copyItem(atPath: sourcePath,
                                         toPath: directory.appendingPathComponent(fileName).path)
                let attributes = try fileManager.attributesOfItem(atPath: sourcePath)
                preservedFiles[fileName] = attributes[.size] as? NSNumber ?? 0
            } catch let error as NSError {
                APLog("MediaLibraryCorruptionReport: Failed to preserve \(sourcePath): \(error.localizedDescription)")
            }
        }

        guard !preservedFiles.isEmpty else {
            try? fileManager.removeItem(at: directory)
            return
        }

        if !log.isEmpty {
            do {
                try log.joined(separator: "\n").write(to: directory.appendingPathComponent(logFileName),
                                                      atomically: true,
                                                      encoding: .utf8)
            } catch let error as NSError {
                APLog("MediaLibraryCorruptionReport: Failed to write log: \(error.localizedDescription)")
            }
        }

        excludeFromDeviceBackup(directory)
        writeMetadata(to: directory, reason: reason, details: details, preservedFiles: preservedFiles)
    }

    static func archivedData() -> Data? {
        guard isPending, let directory = directory else {
            return nil
        }

        var archive: Data?
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: directory,
                                       options: [.forUploading],
                                       error: &coordinationError) { zippedURL in
            archive = try? Data(contentsOf: zippedURL)
        }

        if let coordinationError = coordinationError {
            APLog("MediaLibraryCorruptionReport: Failed to archive: \(coordinationError.localizedDescription)")
        }

        return archive
    }

    static func discard() {
        guard let directory = directory else {
            return
        }

        try? FileManager.default.removeItem(at: directory)
    }

    private static func writeMetadata(to directory: URL,
                                      reason: MediaLibraryCorruptionReason,
                                      details: String?,
                                      preservedFiles: [String: NSNumber]) {
        let bundle = Bundle.main
        var metadata: [String: Any] = [
            "Reason": reason.rawValue,
            "Date": ISO8601DateFormatter().string(from: Date()),
            "Files": preservedFiles,
            "Device": deviceIdentifier(),
            "OS": ProcessInfo.processInfo.operatingSystemVersionString,
            "Locale": Locale.autoupdatingCurrent.identifier,
            "VLC app version": bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            "VLC app build number": bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        ]

        if let details = details {
            metadata["Details"] = details
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            try data.write(to: directory.appendingPathComponent(metadataFileName))
        } catch let error as NSError {
            APLog("MediaLibraryCorruptionReport: Failed to write metadata: \(error.localizedDescription)")
        }
    }

    private static func excludeFromDeviceBackup(_ url: URL) {
        var mutableURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? mutableURL.setResourceValues(resourceValues)
    }

    private static func deviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }
}
