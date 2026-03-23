/*****************************************************************************
 * TrackModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class TrackModel: NSObject, MediaModel {
    typealias MLType = VLCMLMedia

    @objc var sortModel = SortModel([.alpha, .album, .duration, .fileSize, .insertionDate, .lastPlaybackDate, .playCount])

    var observable = VLCObservable<MediaLibraryBaseModelObserver>()

    @objc var files = [VLCMLMedia]()
    var fileArrayLock = NSRecursiveLock()

    var currentPage = 0
    var hasMorePages = true
    var isLoading = false

    #if !os(tvOS)
    var cellType: BaseCollectionViewCell.Type {
        return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(name)") ? MediaGridCollectionCell.self : MediaCollectionViewCell.self
    }
    #endif

    var medialibrary: MediaLibraryService

    var name: String = "SONGS"

    var indicatorName: String = NSLocalizedString("SONGS", comment: "")

    @objc required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        super.init()
        medialibrary.observable.addObserver(self)
    }

    func fetchPage(offset: Int, limit: Int) -> [VLCMLMedia] {
        return medialibrary.media(ofType: .audio,
                                  sortingCriteria: sortModel.currentSort,
                                  desc: sortModel.desc,
                                  items: UInt32(limit),
                                  offset: UInt32(offset))
    }

    @objc func getMedia(at index: Int) -> VLCMLMedia? {
        guard index >= 0, index < files.count else { return nil }
        return files[index]
    }
}

// MARK: - MediaLibraryObserver

extension TrackModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        tracks.forEach({ append($0) })
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyTracks tracks: [VLCMLMedia]) {
        if !tracks.isEmpty {
            defer {
                fileArrayLock.unlock()
            }
            fileArrayLock.lock()
            files = swapModels(with: tracks)
            observable.notifyObservers {
                $0.mediaLibraryBaseModelReloadView()
            }
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = files.filter() {
            for id in ids where $0.identifier() == id.int64Value {
                return false
            }
            return true
        }
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}
