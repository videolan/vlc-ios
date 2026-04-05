/*****************************************************************************
 * ShowEpisodeModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ShowEpisodeModel: NSObject, MediaModel {
    var currentPage: Int = 0
    var hasMorePages: Bool = false
    var isLoading: Bool = false

    func fetchPage(offset: Int, limit: Int) -> [VLCMLMedia] {
        return []
    }

    func getMedia() {
        // dummy
    }

    typealias MLType = VLCMLMedia

    var sortModel = SortModel([.alpha, .duration, .insertionDate, .releaseDate, .fileSize])

    var observable = VLCObservable<MediaLibraryBaseModelObserver>()

    var files = [VLCMLMedia]()
    var fileArrayLock = NSRecursiveLock()

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var name: String = "EPISODES"

    var indicatorName: String = NSLocalizedString("EPISODES", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        super.init()
        medialibrary.observable.addObserver(self)
    }

    func append(_ item: VLCMLMedia) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.append(item)
    }

    func delete(_ items: [VLCMLMedia]) {
        preconditionFailure("ShowEpisodeModel: Cannot delete showEpisode")
    }
}

// MARK: - Sort

extension ShowEpisodeModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        // Currently no show specific getter on medialibrary.
    }
}

// MARK: - MediaLibraryObserver

extension ShowEpisodeModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddShowEpisodes showEpisodes: [VLCMLMedia]) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files.append(contentsOf: showEpisodes)
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibraryDidStartRescan() {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.removeAll()
    }
}
