/*****************************************************************************
 * SortModel.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class SortModel {
    var currentSort: VLCMLSortingCriteria
    var desc: Bool
    var sortingCriteria: [VLCMLSortingCriteria]

    init(_ criteria: [VLCMLSortingCriteria]) {
        sortingCriteria = criteria
        currentSort = .default
        desc = false
    }
}

// MARK: - VLCMLSortingCriteria extension

extension VLCMLSortingCriteria: CustomStringConvertible {
    init(value: UInt) {
        guard let sortingCriteria = VLCMLSortingCriteria(rawValue: value) else {
            assertionFailure("VLCMLSortingCriteria: Unable to init with the given value: \(value)")
            self = .default
            return
        }
        self = sortingCriteria
    }

    public var description: String {
        switch self {
        case .alpha:
            return NSLocalizedString("ALPHA", comment: "")
        case .duration:
            return NSLocalizedString("DURATION", comment: "")
        case .insertionDate:
            return NSLocalizedString("INSERTION_DATE", comment: "")
        case .lastModificationDate:
            return NSLocalizedString("LAST_MODIFICATION_DATE", comment: "")
        case .releaseDate:
            return NSLocalizedString("RELEASE_DATE", comment: "")
        case .fileSize:
            return NSLocalizedString("FILE_SIZE", comment: "")
        case .artist:
            return NSLocalizedString("ARTIST", comment: "")
        case .playCount:
            return NSLocalizedString("PLAY_COUNT", comment: "")
        case  .album:
            return NSLocalizedString("ALBUM", comment: "")
        case .filename:
            return NSLocalizedString("FILENAME", comment: "")
        case .trackNumber:
            return NSLocalizedString("TRACK_NUMBER", comment: "")
        case .nbVideo:
            return NSLocalizedString("NB_VIDEO", comment: "")
        case .nbAudio:
            return NSLocalizedString("NB_AUDIO", comment: "")
        case .nbMedia:
            return NSLocalizedString("NB_MEDIA", comment: "")
        case .nbAlbum:
            return NSLocalizedString("NB_ALBUM", comment: "")
        case .lastPlaybackDate:
            return NSLocalizedString("LAST_PLAYBACK_DATE", comment: "")
        case .trackID:
            return NSLocalizedString("TRACK_ID", comment: "")
        case .default:
            return NSLocalizedString("DEFAULT", comment: "")
        }
    }
}
