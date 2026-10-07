/*****************************************************************************
* FileManager+DeleteMediaFolder.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2019-2026 VideoLAN. All rights reserved.
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*          Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation

extension FileManager {
    func deleteMediaFolder(name: String, at path: URL, externalFolders: [URL]) throws {
        let libraryFolders = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) + externalFolders)
            .map { $0.resolvingSymlinksInPath() }
        let path = path.resolvingSymlinksInPath()
        if isInside(path, anyOf: libraryFolders) {
            if let dirContent = try? FileManager.default.contentsOfDirectory(at: path,
                                                                             includingPropertiesForKeys: []) {
                if dirContent.isEmpty || canDeleteFolder(content: dirContent, name: name) {
                    do {
                        let parentPath = path.deletingLastPathComponent()
                        try FileManager.default.removeItem(at: path)
                        if isInside(parentPath, anyOf: libraryFolders) && canDeleteParent(at: path, name: name) {
                            try FileManager.default.removeItem(at: parentPath)
                        }
                    }
                    catch let error as NSError {
                        throw error
                    }
                }
            }
        }
    }
}

// MARK: - Private helpers

private extension FileManager {
    func isInside(_ url: URL, anyOf folders: [URL]) -> Bool {
        let components = url.standardizedFileURL.pathComponents
        return folders.contains { folder in
            let folderComponents = folder.standardizedFileURL.pathComponents
            return components.count > folderComponents.count
                && Array(components.prefix(folderComponents.count)) == folderComponents
        }
    }

    func canDeleteFolder(content: [URL], name: String) -> Bool {
        var coverNames: Set = [
            "album",
            "albumart",
            "albumartsmall",
            "back",
            "cover",
            ".folder",
            "folder",
            "front",
            "thumb"
        ]
        let coverExtensions: Set = [
            "jpg",
            "jpeg",
            "png",
            "gif",
            "bmp"
        ]
        if !name.isEmpty {
            coverNames.insert(name.lowercased())
        }
        for file in content {
            if !coverNames.contains(file.deletingPathExtension().lastPathComponent.lowercased())
                || !coverExtensions.contains(file.pathExtension.lowercased()) {
                    return false
            }
        }
        return true
    }

    func canDeleteParent(at path: URL, name: String) -> Bool {
        let parentPath = path.deletingLastPathComponent()
        if parentPath.lastPathComponent == name {
            if let parentDirContent = try? FileManager.default.contentsOfDirectory(at: parentPath, includingPropertiesForKeys: []) {
                if parentDirContent.isEmpty {
                    return true
                }
            }
        }
        return false
    }
}
