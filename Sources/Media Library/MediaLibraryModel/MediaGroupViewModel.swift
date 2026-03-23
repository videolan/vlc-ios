/*****************************************************************************
 * MediaGroupViewModel.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class MediaGroupViewModel: MLBaseModel {
    typealias MLType = VLCMLMediaGroup

    var sortModel = SortModel([.alpha, .duration, .insertionDate, .lastModificationDate, .nbVideo, .releaseDate, .fileSize, .lastPlaybackDate, .playCount])

    var observable = VLCObservable<MediaLibraryBaseModelObserver>()

    var fileArrayLock = NSRecursiveLock()

    var files = [VLCMLMediaGroup]()

    var cellType: BaseCollectionViewCell.Type {
        return UserDefaults.standard.bool(forKey: "\(kVLCVideoLibraryGridLayout)\(name)") ? MovieCollectionViewCell.self : MediaCollectionViewCell.self
    }

    var medialibrary: MediaLibraryService

    var name: String = "VIDEO_GROUPS"

    var indicatorName: String = NSLocalizedString("VIDEO_GROUPS", comment: "")

    var currentPage = 0
    var hasMorePages = true
    var isLoading = false

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.observable.addObserver(self)
    }

    func append(_ item: VLCMLMediaGroup) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files.append(item)
    }

    func append(_ media: [VLCMLMedia], to mediaGroup: VLCMLMediaGroup) {
        let originIds = originMediaGroupsIds(from: media)

        for medium in media {
            mediaGroup.add(medium)
        }

        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = swapModels(with: [mediaGroup])
        filterFilesFromDeletion(of: originIds)
    }

    func delete(_ items: [VLCMLMediaGroup]) {
        for item in items {
            guard let media = item.media(of: .video) else {
                continue
            }

            for medium in media {
                medium.deleteMainFile()
            }
            item.destroy()
        }
        medialibrary.reload()
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        filterFilesFromDeletion(of: items)
    }

    func rename(_ mediaGroup: VLCMLMediaGroup, to name: String) {
        if mediaGroup.nbTotalMedia() == 1 && !mediaGroup.userInteracted() {
            guard let media = mediaGroup.media(of: .video)?.first else {
                assertionFailure("MediaGroupViewController: rename: Failed to retrieve media.")
                return
            }
            media.updateTitle(name)
        } else {
            mediaGroup.rename(withName: name)
        }
    }

    func create(with name: String,
                from mediaGroupIds: [VLCMLIdentifier]? = nil, content: [VLCMLMedia]) -> Bool {
        guard let mediaGroup = medialibrary.medialib.createMediaGroup(withName: name) else {
            assertionFailure("MediaGroupViewModel: Unable to create a mediagroup with name: \(name)")
            return false
        }
        append(mediaGroup)
        content.forEach() { mediaGroup.add($0) }
        if let mediaGroupIds = mediaGroupIds {
            fileArrayLock.lock()
            defer { fileArrayLock.unlock() }
            filterFilesFromDeletion(of: mediaGroupIds)
        }
        return true
    }

    func create(with name: String, from mediaContent: [VLCMLMedia]) -> Bool {
        let originIds = originMediaGroupsIds(from: mediaContent)
        return create(with: name, from: originIds, content: mediaContent)
    }

    func unGroupMedia(_ media: [VLCMLMedia], from originMediaGroup: VLCMLMediaGroup) -> Bool {
        for medium in media {
            medium.removeFromGroup()
            guard let newGroup = medialibrary.medialib.createMediaGroup(withName: medium.title) else {
                return false
            }
            newGroup.add(medium)
        }
        if originMediaGroup.nbTotalMedia() == 0 {
            fileArrayLock.lock()
            defer { fileArrayLock.unlock() }
            filterFilesFromDeletion(of: [originMediaGroup])
            medialibrary.medialib.deleteMediaGroup(withIdentifier: originMediaGroup.identifier())
        }
        return true
    }

    func fetchPage(offset: Int, limit: Int) -> [VLCMLMediaGroup] {
        return medialibrary.medialib.mediaGroups(with: sortModel.currentSort,
                                                 desc: sortModel.desc,
                                                 UInt32(limit),
                                                 UInt32(offset)) ?? []
    }
}

extension VLCMLMediaGroup {
    @objc func mediaDuration() -> String {
        return VLCTime(number: NSNumber(value: duration())).stringValue
    }
}

// MARK: - Private helpers

private extension MediaGroupViewModel {
    func originMediaGroupsIds(from media: [VLCMLMedia]) -> [VLCMLIdentifier] {
        var originIds = [VLCMLIdentifier]()
        media.forEach() {
            let groupId = $0.groupIdentifier()
            if !originIds.contains(groupId) {
                originIds.append(groupId)
            }
        }
        return originIds
    }
}

// MARK: - MediaLibraryObserver

extension MediaGroupViewModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService,
                      didAddMediaGroups mediaGroups: [VLCMLMediaGroup]) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        for mediaGroup in mediaGroups {
            if !files.contains(where: { $0.identifier() == mediaGroup.identifier() }) {
                files.append(mediaGroup)
            }
        }
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyMediaGroupsWithIds mediaGroupsIds: [NSNumber]) {
        var mediaGroups = [VLCMLMediaGroup]()

        mediaGroupsIds.forEach() {
            guard let safeMediaGroup = medialibrary.medialib.mediaGroup(withIdentifier: $0.int64Value)
                else {
                    return
            }
            mediaGroups.append(safeMediaGroup)
        }

        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = swapModels(with: mediaGroups)
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didDeleteMediaGroupsWithIds mediaGroupsIds: [NSNumber]) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files.removeAll {
            mediaGroupsIds.contains(NSNumber(value: $0.identifier()))
        }
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    // MARK: - VLCMLMedia

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyVideos videos: [VLCMLMedia]) {
        guard !videos.isEmpty else { return }

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
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}

// MARK: - VLCMLMediaGroup - Search

extension VLCMLMediaGroup: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return search(searchString, in: name())
    }
}

// MARK: - VLCMLMediaGroup - MediaCollectionModel

extension VLCMLMediaGroup: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return nil
    }

    func files(with criteria: VLCMLSortingCriteria,
               desc: Bool) -> [VLCMLMedia]? {
        // FIXME: For now force type of media to .video
        return media(of: .video, sort: criteria, desc: desc)
    }

    func title() -> String {
        if nbTotalMedia() == 1 && !userInteracted() {
            guard let media = media(of: .video)?.first else {
                assertionFailure("MediaGroupViewController: Failed to retrieve media.")
                return name()
            }
            return media.title
        } else {
            return name()
        }
    }
}

// MARK: - VLCMLMediaGroup - Helpers

extension VLCMLMediaGroup {
    func numberOfTracksString() -> String {
        let mediaCount = nbVideo()
        let tracksString = mediaCount > 1 ? NSLocalizedString("TRACKS", comment: "") : NSLocalizedString("TRACK", comment: "")
        return String(format: tracksString, mediaCount)
    }

    func accessibilityText() -> String? {
        return name() + " " + numberOfTracksString()
    }
}
