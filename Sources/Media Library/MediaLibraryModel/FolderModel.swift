//
//  FolderModel.swift
//  VLC-iOS
//
//  Created by Eshan Singh on 10/07/24.
//  Copyright © 2024-2026 VideoLAN. All rights reserved.
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
    var currentFolder: VLCMLFolder?
    private var externalFolderIdentifiers = Set<VLCMLIdentifier>()
    private var externalFolderLocations = [VLCMLIdentifier: VLCMLFolder.Location]()

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

    required init(medialibrary: MediaLibraryService, isAudio: Bool, folder: VLCMLFolder?) {
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

        if currentFolder == nil {
            currentFolder = medialibrary.baseFolder()
        }

        guard let currentFolder = currentFolder else {
            files = []
            folderMediaFiles = []
            return
        }

        let externalFolders = self.externalFolders(sortingCriteria: sortModel.currentSort, desc: sortModel.desc)
        externalFolderIdentifiers = Set(externalFolders.map { $0.identifier() })
        updateLocations(of: externalFolders)
        files = externalFolders + (currentFolder.subfolders(with: sortModel.currentSort, desc: sortModel.desc) ?? [])
        if self.isAudio {
            folderMediaFiles = currentFolder.media(of: .audio, sortingCriteria: sortModel.currentSort, desc: sortModel.desc) ?? []
        } else {
            folderMediaFiles = currentFolder.media(of: .video, sortingCriteria: sortModel.currentSort, desc: sortModel.desc) ?? []
        }
    }

    var isRoot: Bool {
        guard let currentFolder = currentFolder, let baseFolder = medialibrary.baseFolder() else {
            return false
        }
        return currentFolder.identifier() == baseFolder.identifier()
    }

    private func externalFolders(sortingCriteria criteria: VLCMLSortingCriteria, desc: Bool) -> [VLCMLFolder] {
        guard isRoot else {
            return []
        }
        return medialibrary.medialib.externalFolders(with: criteria, desc: desc)
    }

    func isExternalFolder(_ folder: VLCMLFolder) -> Bool {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        return externalFolderIdentifiers.contains(folder.identifier())
    }

    func location(of folder: VLCMLFolder) -> VLCMLFolder.Location? {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        return externalFolderLocations[folder.identifier()]
    }

    private func updateLocations(of folders: [VLCMLFolder]) {
        let mrls = folders.compactMap { folder in folder.mrl.map { (folder.identifier(), $0) } }
        guard !mrls.isEmpty else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var locations = [VLCMLIdentifier: VLCMLFolder.Location]()
            for (identifier, mrl) in mrls {
                locations[identifier] = VLCMLFolder.Location(url: mrl)
            }

            DispatchQueue.main.async {
                self.fileArrayLock.lock()
                let previousLocations = self.externalFolderLocations
                self.externalFolderLocations.merge(locations) { _, location in location }
                let didChange = self.externalFolderLocations != previousLocations
                self.fileArrayLock.unlock()

                guard didChange else {
                    return
                }
                self.observable.notifyObservers {
                    $0.mediaLibraryBaseModelReloadView()
                }
            }
        }
    }

    func fetchPage(offset: Int, limit: Int) -> [VLCMLFolder] {
        return []
    }

    func delete(_ items: [VLCMLFolder]) {
        var parentDirectories = Set<URL>()

        for folder in items {
            if isExternalFolder(folder) {
                medialibrary.medialib.deleteExternalFolder(folder)
                continue
            }

            guard let mrl = folder.mrl else {
                continue
            }

            let url = URL(fileURLWithPath: mrl.path)
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

    func removeFromLibrary(_ folder: VLCMLFolder) {
        medialibrary.medialib.removeExternalFolder(folder)

        fileArrayLock.lock()
        files.removeAll { $0.identifier() == folder.identifier() }
        fileArrayLock.unlock()

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
            guard let file = mediaItem.mainFile(), !file.isExternal(), !file.isNetwork(),
                  let mrl = file.mrl else {
                continue
            }

            let url = URL(fileURLWithPath: mrl.path)
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
        let externalFolders = medialibrary.medialib.externalFolders(with: .default, desc: false).compactMap { $0.mrl }
        for directory in directories {
            do {
                try FileManager.default.deleteMediaFolder(name: directory.lastPathComponent, at: directory,
                                                          externalFolders: externalFolders)
            } catch let error as NSError {
                APLog("FolderModel: Failed to remove the emptied directory \(directory.path): \(error.localizedDescription)")
            }
        }
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        if let currentFolder = currentFolder {
            let externalFolders = self.externalFolders(sortingCriteria: criteria, desc: desc)
            externalFolderIdentifiers = Set(externalFolders.map { $0.identifier() })
            updateLocations(of: externalFolders)
            files = externalFolders + (currentFolder.subfolders(with: criteria, desc: desc) ?? [])
            if self.isAudio {
                folderMediaFiles = currentFolder.media(of: .audio, sortingCriteria: criteria, desc: desc) ?? []
            } else {
                folderMediaFiles = currentFolder.media(of: .video, sortingCriteria: criteria, desc: desc) ?? []
            }
        } else {
            files = []
            folderMediaFiles = []
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
        reloadContents()
    }
    func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        reloadContents()
    }
    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        reloadContents()
    }
    func medialibrary(_ medialibrary: MediaLibraryService, didAddEntryPoint entryPoint: String) {
        reloadContents()
    }
    func medialibrary(_ medialibrary: MediaLibraryService, didRemoveEntryPoint entryPoint: String) {
        reloadContents()
    }

    private func reloadContents() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.reloadContents()
            }
            return
        }

        setupData()
        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}

extension VLCMLFolder: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        var matches = false

        matches = matches || search(searchString, in: name ?? "")

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
