/*****************************************************************************
 * VideoModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VideoModel: NSObject, MediaModel {
    typealias MLType = VLCMLMedia

    @objc var sortModel = SortModel([.alpha, .duration, .insertionDate, .releaseDate, .fileSize, .lastPlaybackDate, .playCount])

    var observable = VLCObservable<MediaLibraryBaseModelObserver>()

    var fileArrayLock = NSRecursiveLock()
    @objc var files = [VLCMLMedia]()

#if !os(tvOS)
    var cellType: BaseCollectionViewCell.Type {
        return UserDefaults.standard.bool(forKey: "\(kVLCVideoLibraryGridLayout)\(name)") ? MovieCollectionViewCell.self : MediaCollectionViewCell.self
    }
#endif

    var medialibrary: MediaLibraryService

    var name: String = "ALL_VIDEOS"

    var secondName: String = ""

    var indicatorName: String = NSLocalizedString("ALL_VIDEOS", comment: "")

    var intialPageSize = 12
    var currentPage = 0
    var firstTime = true

    @objc required init(medialibrary: MediaLibraryService) {
        defer {
            fileArrayLock.unlock()
        }
        self.medialibrary = medialibrary
        super.init()
        medialibrary.observable.addObserver(self)
        fileArrayLock.lock()
    }

    func getMedia() {
        currentPage += 1
        var didAppend = false
        let offset = (currentPage - 1) * intialPageSize
        let mediaAtOffset = medialibrary.media(ofType: .video, sortingCriteria: sortModel.currentSort, desc: sortModel.desc, items: UInt32(intialPageSize), offset: UInt32(offset))
            for media in mediaAtOffset {
                    files.append(media)
            }
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    @objc func getMedia(at index: Int) -> VLCMLMedia? {
        guard index >= 0, index < files.count else { return nil }
        return files[index]
    }
}

// MARK: - Sort

extension VideoModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        defer {
            fileArrayLock.unlock()
        }
        sortModel.currentSort = criteria
        sortModel.desc = desc
        if firstTime {
            getMedia()
            firstTime = false
        } else {
            files.removeAll()
            intialPageSize = 12
            currentPage = 0
            getMedia()
        }
    }
}

// MARK: - MediaLibraryObserver

extension VideoModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddVideos videos: [VLCMLMedia]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        videos.forEach({ append($0) })
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyVideos videos: [VLCMLMedia]) {
        if !videos.isEmpty {
            defer {
                fileArrayLock.unlock()
            }
            fileArrayLock.lock()
            files = swapModels(with: videos)
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

    // MARK: - Thumbnail

    func medialibrary(_ medialibrary: MediaLibraryService,
                      thumbnailReady media: VLCMLMedia,
                      type: VLCMLThumbnailSizeType, success: Bool) {
        guard success else {
            return
        }
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = swapModels(with: [media])
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}
