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

class ShowEpisodeModel: MediaModel {
    typealias MLType = VLCMLMedia

    var sortModel = SortModel([.alpha, .duration, .insertionDate, .releaseDate, .fileSize])

    var observable = Observable<MediaLibraryBaseModelObserver>()

    var files = [VLCMLMedia]()
    var fileArrayLock = NSRecursiveLock()

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var name: String = "EPISODES"

    var indicatorName: String = NSLocalizedString("EPISODES", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
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
        showEpisodes.forEach({ append($0) })
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
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
