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

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("EPISODES", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
    }

    func append(_ item: VLCMLMedia) {
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
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
        updateView?()
    }

    func medialibraryDidStartRescan() {
        files.removeAll()
    }
}
