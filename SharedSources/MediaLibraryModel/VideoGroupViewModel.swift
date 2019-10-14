/*****************************************************************************
 * VideoGroupViewModel.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// Fake VLCMLVideoGroup as a medialibrary entity with an id

extension VLCMLVideoGroup: VLCMLObject {
    public func identifier() -> VLCMLIdentifier {
        return 42
    }
}

class VideoGroupViewModel: MLBaseModel {
    typealias MLType = VLCMLVideoGroup

    var sortModel = SortModel([.alpha, .nbVideo])

    var updateView: (() -> Void)?

    var files: [VLCMLVideoGroup]

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("VIDEO_GROUPS", comment: "")

    var prefixLength: UInt32 = 0

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        self.files = medialibrary.medialib.videoGroups() ?? []
        medialibrary.medialib.setVideoGroupsAllowSingleVideo(false)

        setPrefixLength()
    }

    func append(_ item: VLCMLVideoGroup) {
        assertionFailure("VideoGroupViewModel: Cannot append VideoGroups")
    }

    func delete(_ items: [VLCMLObject]) {
        assertionFailure("VideoGroupViewModel: Cannot delete VideoGroups")
    }

    func updateVideoGroups() {
        setPrefixLength()
        files = medialibrary.medialib.videoGroups() ?? []
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        files = medialibrary.medialib.videoGroups(with: criteria, desc: desc) ?? []
        sortModel.currentSort = criteria
        sortModel.desc = desc
        updateView?()
    }
}

// MARK: - Private helpers

private extension VideoGroupViewModel {
    private func setPrefixLength() {
        let settingPrefixLength = UserDefaults.standard.integer(forKey:
            kVLCSettingsMediaLibraryVideoGroupPrefixLength)

        if prefixLength != settingPrefixLength {
            prefixLength = UInt32(settingPrefixLength)
            assert(prefixLength != 0, "VideoGroupViewModel: Failed to retrieve setting value.")
            medialibrary.medialib.setVideoGroupPrefixLength(prefixLength)
        }
    }
}

// MARK: - VLCMLVideoGroup - Search

extension VLCMLVideoGroup: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return name().lowercased().contains(searchString)
    }
}

// MARK: - VLCMLVideoGroup - MediaCollectionModel

extension VLCMLVideoGroup: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return nil
    }

    func files(with criteria: VLCMLSortingCriteria,
               desc: Bool) -> [VLCMLMedia]? {
        return media(with: criteria, desc: desc)
    }

    func title() -> String {
        return name()
    }
}

// MARK: - VLCMLVideoGroup - Helpers

extension VLCMLVideoGroup {
    func numberOfTracksString() -> String {
        let mediaCount = count()
        let tracksString = mediaCount > 1 ? NSLocalizedString("TRACKS", comment: "") : NSLocalizedString("TRACK", comment: "")
        return String(format: tracksString, mediaCount)
    }

    func accessibilityText() -> String? {
        return name() + " " + numberOfTracksString()
    }
}
