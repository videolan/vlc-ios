/*****************************************************************************
 * InboxManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class InboxManager {
    private static var documentsURL: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private static var inboxURL: URL? {
        return documentsURL?.appendingPathComponent("Inbox", isDirectory: true)
    }

    private static var sharedInboxURL: URL? {
        guard let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "MLKitGroupIdentifier") as? String,
              let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            return nil
        }

        return containerURL.appendingPathComponent("Inbox", isDirectory: true)
    }

    static func isInInbox(_ url: URL) -> Bool {
        guard url.isFileURL, let inboxPath = inboxURL?.resolvingSymlinksInPath().path else {
            return false
        }

        return url.resolvingSymlinksInPath().path.hasPrefix(inboxPath + "/")
    }

    @discardableResult
    static func moveToDocuments(_ url: URL) -> URL? {
        guard let documentsURL = documentsURL else {
            return nil
        }

        let destination = availableURL(forFileNamed: url.lastPathComponent, in: documentsURL)

        do {
            try FileManager.default.moveItem(at: url, to: destination)
        } catch let error {
            APLog("InboxManager: failed to move \(url.lastPathComponent) to the Documents folder: \(error.localizedDescription)")
            return nil
        }

        return destination
    }

    static func drainInbox() {
        guard let inboxURL = inboxURL else {
            return
        }

        drain(inboxURL)
    }

    static func drainSharedInbox() {
        guard let sharedInboxURL = sharedInboxURL else {
            return
        }

        drain(sharedInboxURL)
    }

    static func drain(_ folderURL: URL) {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(at: folderURL,
                                                                  includingPropertiesForKeys: nil) else {
            return
        }

        /* the share extension writes to a hidden name while a file is still incomplete */
        for item in contents where !item.lastPathComponent.hasPrefix(".") {
            moveToDocuments(item)
        }

        if let remainder = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil),
           remainder.isEmpty {
            try? fileManager.removeItem(at: folderURL)
        }
    }

    private static func availableURL(forFileNamed fileName: String, in folderURL: URL) -> URL {
        let fileManager = FileManager.default
        var destination = folderURL.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: destination.path) else {
            return destination
        }

        let baseName = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        var index = 1

        repeat {
            var candidate = "\(baseName)_\(index)"
            if !fileExtension.isEmpty {
                candidate = (candidate as NSString).appendingPathExtension(fileExtension) ?? candidate
            }
            destination = folderURL.appendingPathComponent(candidate)
            index += 1
        } while fileManager.fileExists(atPath: destination.path)

        return destination
    }
}
