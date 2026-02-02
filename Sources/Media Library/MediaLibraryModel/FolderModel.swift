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

    var name: String = "Folder"
    var indicatorName: String = NSLocalizedString("BUTTON_FOLDER", comment: "")
    var cellType: BaseCollectionViewCell.Type {
        if isAudio {
            return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryGridLayout)\("FOLDER_AUDIO")") ? MediaGridCollectionCell.self : MediaCollectionViewCell.self
        } else {
            return UserDefaults.standard.bool(forKey: "\(kVLCVideoLibraryGridLayout)\("FOLDER_VIDEO")") ? MovieCollectionViewCell.self : MediaCollectionViewCell.self
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
        files = currentFolder.subfolders(with: sortModel.currentSort, desc: sortModel.desc)!
        if self.isAudio {
            folderMediaFiles = currentFolder.media(of: .audio, sortingCriteria: sortModel.currentSort, desc: sortModel.desc)!
        } else {
            folderMediaFiles = currentFolder.media(of: .video, sortingCriteria: sortModel.currentSort, desc: sortModel.desc)!
        }
    }

    func delete(_ items: [VLCMLFolder]) {
        // dummy function
    }

    func append(_ item: VLCMLFolder) {
        // dummy function
    }

    func delete(media: [VLCMLMedia]) {
        media.forEach { mediaItem in
            mediaItem.deleteMainFile()
            if let index = folderMediaFiles.firstIndex(of: mediaItem) {
                folderMediaFiles.remove(at: index)
            }
        }
        observable.notifyObservers() {
            $0.mediaLibraryBaseModelReloadView()
        }
    }


    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
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

        matches = matches || search(searchString, in: mrl.lastPathComponent)

        return matches
    }

}
