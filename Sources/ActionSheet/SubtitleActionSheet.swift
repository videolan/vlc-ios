/*****************************************************************************
 * SubtitleActionSheet.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum SubtitleActionSheetCellIdentifier: String, CustomStringConvertible, CaseIterable {
    case audioTrack
    case subtitleTrack
    case chapter

    var description: String {
        switch self {
        case .audioTrack:
            return NSLocalizedString("CHOOSE_AUDIO_TRACK", comment: "")
        case .subtitleTrack:
            return NSLocalizedString("CHOOSE_SUBTITLE_TRACK", comment: "")
        case .chapter:
            return NSLocalizedString("CHOOSE_CHAPTER", comment: "")
        }
    }
}

@objc (VLCSubtitleActionSheet)
@objcMembers class SubtitleActionSheet: MediaPlayerActionSheet {

    override init() {
        super.init()
        mediaPlayerActionSheetDelegate = self
        mediaPlayerActionSheetDataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SubtitleActionSheet: MediaPlayerActionSheetDelegate {
    func mediaPlayerActionSheetHeaderTitle() -> String? {
        return NSLocalizedString("SUBTITLES_AND_AUDIO_HEADER", comment: "")
    }
}

extension SubtitleActionSheet: MediaPlayerActionSheetDataSource {
    var configurableCellModels: [ActionSheetCellModel] {
        var models = [ActionSheetCellModel]()

        SubtitleActionSheetCellIdentifier.allCases.forEach {
            let v = UIView(frame: offScreenFrame)
            v.backgroundColor = .blue
            let cellModel = ActionSheetCellModel(
                title: $0.description,
                imageIdentifier: $0.rawValue,
                viewToPresent: v
            )
            models.append(cellModel)
        }
        return models
    }
}
