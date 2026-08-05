//
//  FolderModel.swift
//  VLC-iOS
//
//  Created by Eshan Singh on 10/07/24.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation
class FolderModel: MLBaseModel {

    var medialibrary: MediaLibraryService

    var sortModel = SortModel([.alpha, .album, .duration, .fileSize, .insertionDate, .lastPlaybackDate, .playCount])
    var observable = VLCObservable<MediaLibraryBaseModelObserver>()
    var fileArrayLock = NSRecursiveLock()
    var isAudio: Bool

    var files = [VLCMLFolder]()
    var folderMediaFiles = [VLCMLMedia]()
    var currentFolder: VLCMLFolder

    var currentPage = 0
    var hasMorePages = false
    var isLoading = false

    var name: String = "Folder"
    var indicatorName: String = NSLocalizedString("FOLDERS", comment: "")
    var cellType: BaseCollectionViewCell.Type {
        if isAudio {
            return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryGridLayout)\("FOLDER_AUDIO")\(name)") ? MediaGridCollectionCell.self : MediaCollectionViewCell.self
        } else {
            return UserDefaults.standard.bool(forKey: "\(kVLCVideoLibraryGridLayout)\("FOLDER_VIDEO")\(name)") ? MovieCollectionViewCell.self : MediaCollectionViewCell.self
        }
    }

    required init(medialibrary: MediaLibraryService, isAudio: Bool, folder: VLCMLFolder) {
        self.medialibrary = medialibrary
        self.isAudio = isAudio
        self.currentFolder = folder
        medialibrary.observable.addObserver(self)
        setupData()
    }

    required init(medialibrary: MediaLibraryService) {
        fatalError("Need to pass media type")
    }

    func setupData() {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = currentFolder.subfolders(with: sortModel.currentSort, desc: sortModel.desc)!
        if self.isAudio {
            folderMediaFiles = currentFolder.media(of: .audio, sortingCriteria: sortModel.currentSort, desc: sortModel.desc)!
        } else {
            folderMediaFiles = currentFolder.media(of: .video, sortingCriteria: sortModel.currentSort, desc: sortModel.desc)!
        }
    }

    func fetchPage(offset: Int, limit: Int) -> [VLCMLFolder] {
        return []
    }

    func delete(_ items: [VLCMLFolder]) {
        var parentDirectories = Set<URL>()

        for folder in items {
            let url = URL(fileURLWithPath: folder.mrl.path)
            parentDirectories.insert(url.deletingLastPathComponent())
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                APLog("FolderModel: Failed to delete \(url.path): \(error.localizedDescription)")
            }
        }

        removeEmptiedDirectories(parentDirectories)

        let deletedIdentifiers = Set(items.map { $0.identifier() })
        fileArrayLock.lock()
        files.removeAll { deletedIdentifiers.contains($0.identifier()) }
        fileArrayLock.unlock()

        medialibrary.reload()

        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func getMedia() {
        // stub - FolderModel uses setupData() instead
    }

    func append(_ item: VLCMLFolder) {
        // dummy function
    }

    func delete(media: [VLCMLMedia]) {
        var parentDirectories = Set<URL>()

        for mediaItem in media {
            guard let file = mediaItem.mainFile(), !file.isExternal(), !file.isNetwork() else {
                continue
            }

            let url = URL(fileURLWithPath: file.mrl.path)
            parentDirectories.insert(url.deletingLastPathComponent())
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                APLog("FolderModel: Failed to delete \(url.path): \(error.localizedDescription)")
            }
        }

        removeEmptiedDirectories(parentDirectories)

        let deletedIdentifiers = Set(media.map { $0.identifier() })
        fileArrayLock.lock()
        folderMediaFiles.removeAll { deletedIdentifiers.contains($0.identifier()) }
        fileArrayLock.unlock()

        medialibrary.reload()

        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    private func removeEmptiedDirectories(_ directories: Set<URL>) {
        for directory in directories {
            do {
                try FileManager.default.deleteMediaFolder(name: directory.lastPathComponent, at: directory)
            } catch let error as NSError {
                APLog("FolderModel: Failed to remove the emptied directory \(directory.path): \(error.localizedDescription)")
            }
        }
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = currentFolder.subfolders(with: criteria, desc: desc)!
        if self.isAudio {
            folderMediaFiles = currentFolder.media(of: .audio, sortingCriteria: criteria, desc: desc)!
        } else {
            folderMediaFiles = currentFolder.media(of: .video, sortingCriteria: criteria, desc: desc)!
        }

        sortModel.currentSort = criteria
        sortModel.desc = desc

        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}
// No notification for folders, so latest folders are only updated instantly in UI, if the folder is not empty, and a media file is also added.
extension FolderModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddVideos videos: [VLCMLMedia]) {
        setupData()
        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        setupData()
        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}

extension VLCMLFolder: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        var matches = false

        matches = matches || search(searchString, in: name)

        return matches
    }

}

extension VLCMLFolder {
    func allMedia() -> [VLCMLMedia] {
        var media = self.media(of: .unknown, sortingCriteria: .default, desc: false) ?? []

        for subfolder in subfolders(with: .default, desc: false) ?? [] {
            media += subfolder.allMedia()
        }

        return media
    }

    func folderDescriptionString() -> String {
        var components = [String]()

        let subfolderCount = subfolders(with: .default, desc: false)?.count ?? 0
        if subfolderCount == 1 {
            components.append(NSLocalizedString("SUBFOLDER_DESCRIPTION", comment: ""))
        } else if subfolderCount > 1 {
            components.append(String(format: NSLocalizedString("SUBFOLDERS_DESCRIPTION", comment: ""), locale: Locale.current, subfolderCount))
        }

        let mediaCount = nbMedia()
        if mediaCount == 1 {
            components.append(NSLocalizedString("ONE_FILE", comment: ""))
        } else if mediaCount > 1 {
            components.append(String(format: NSLocalizedString("NUM_OF_FILES", comment: ""), locale: Locale.current, mediaCount))
        }

        return components.joined(separator: ", ")
    }
}
