/*****************************************************************************
 * HistoryModel.swift
 *
 * Copyright © 2023-2026 VLC authors and VideoLAN
 * Copyright © 2023 Videolabs
 *
 * Authors: Avi Wadhwa <aviwad@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class HistoryModel: MLBaseModel {
    enum Filter: Int {
        case any
        case audio
        case video
    }

    var currentPage: Int = 0
    var hasMorePages: Bool = false
    var isLoading: Bool = false

    func fetchPage(offset: Int, limit: Int) -> [VLCMLMedia] {
        return []
    }

    func getMedia() {
        // dummy
    }

    var medialibrary: MediaLibraryService

    typealias MLType = VLCMLMedia
    var sortModel = SortModel([])
    var observable = VLCObservable<MediaLibraryBaseModelObserver>()
    var fileArrayLock = NSRecursiveLock()
    var files = [VLCMLMedia]()
    var cellType: BaseCollectionViewCell.Type = MediaCollectionViewCell.self
    var name: String = "HISTORY"
    var indicatorName: String = NSLocalizedString("HISTORY", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.observable.addObserver(self)
    }

    func delete(_ items: [VLCMLMedia]) {
        for case let media in items {
            media.removeFromHistory()
        }
    }
    
    func append(_ item: VLCMLMedia) {
        // dummy function
    }

    var filter: Filter {
        get {
            return Filter(rawValue: UserDefaults.standard.integer(forKey: kVLCHistoryFilter)) ?? .any
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kVLCHistoryFilter)
            loadHistory()
        }
    }

    func clear() {
        switch filter {
        case .any:
            medialibrary.medialib.clearHistory(of: .local)
        case .audio:
            medialibrary.medialib.clearHistory(by: .audio)
        case .video:
            medialibrary.medialib.clearHistory(by: .video)
        }
    }

    private func loadHistory() {
        let history: [VLCMLMedia]?
        switch filter {
        case .any:
            history = medialibrary.medialib.history(of: .local)
        case .audio:
            history = medialibrary.medialib.audioHistory()
        case .video:
            history = medialibrary.medialib.videoHistory()
        }

        fileArrayLock.lock()
        files = history ?? []
        fileArrayLock.unlock()

        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}

// MARK: - MediaLibraryObserver
extension HistoryModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, historyChangedOfType type: VLCMLHistoryType) {
        loadHistory()
    }

    func medialibraryDidStartRescan() {
        loadHistory()
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        loadHistory()
    }
}
