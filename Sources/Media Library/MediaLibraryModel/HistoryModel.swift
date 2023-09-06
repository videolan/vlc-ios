/*****************************************************************************
 * HistoryModel.swift
 *
 * Copyright © 2023 VLC authors and VideoLAN
 * Copyright © 2023 Videolabs
 *
 * Authors: Avi Wadhwa <aviwad@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class HistoryModel: MLBaseModel {
    // These two are initialized with the class
    var medialibrary: MediaLibraryService
    var mediaType: VLCMLMediaType
    
    // Other variables
    typealias MLType = VLCMLMedia
    var sortModel = SortModel([])
    var observable = Observable<MediaLibraryBaseModelObserver>()
    var fileArrayLock = NSRecursiveLock()
    var files = [VLCMLMedia]()
    var cellType: BaseCollectionViewCell.Type = MediaCollectionViewCell.self
    var name: String = "HISTORY"
    var indicatorName: String = NSLocalizedString("HISTORY", comment: "")

    required init(medialibrary: MediaLibraryService, mediaType: VLCMLMediaType) {
        self.medialibrary = medialibrary
        self.mediaType = mediaType
        medialibrary.observable.addObserver(self)
    }
    
    required init(medialibrary: MediaLibraryService) {
        fatalError("Need to pass media type")
    }
    
    func delete(_ items: [VLCMLMedia]) {
        for case let media in items {
            media.removeFromHistory()
        }
    }
    
    func append(_ item: VLCMLMedia) {
        // dummy function
    }
}

// MARK: - MediaLibraryObserver
extension HistoryModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, historyChangedOfType type: VLCMLHistoryType) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = medialibrary.medialib.history(of: mediaType) ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibraryDidStartRescan() {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = medialibrary.medialib.history(of: mediaType) ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }
    
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        // Since we cannot sort the history, we simply force a media library rescan
        medialibraryDidStartRescan()
    }
}
