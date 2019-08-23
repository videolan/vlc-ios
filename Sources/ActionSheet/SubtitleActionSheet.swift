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

@objc (VLCSubtitleActionSheet)
class SubtitleActionSheet: MediaPlayerActionSheet {

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

        MediaPlayerActionSheetCellIdentifier.subtitleCellIdentifiers.forEach {
            let v = UIView(frame: offScreenFrame)
            v.backgroundColor = .blue
            let cellModel = ActionSheetCellModel(
                title: $0.description,
                imageIdentifier: $0.rawValue,
                viewToPresent: v,
                cellIdentifier: $0
            )
            models.append(cellModel)
        }
        return models
    }
}
