/*****************************************************************************
 * MediaMoreOptionsActionSheet.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCMediaMoreOptionsActionSheetDelegate)
protocol MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool)
}

@objc (VLCMediaMoreOptionsActionSheet)
@objcMembers class MediaMoreOptionsActionSheet: MediaPlayerActionSheet {

    // MARK: Instance variables
    weak var moreOptionsDelegate: MediaMoreOptionsActionSheetDelegate?

    // To be removed when Designs are done for the Filters, Equalizer etc views are added to Figma
    lazy private var mockViewController: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .green
        vc.view.frame = externalFrame
        return vc
    }()

    @objc var interfaceDisabled: Bool = false {
        didSet {
            collectionView.visibleCells.forEach {
                if let cell = $0 as? ActionSheetCell, let id = cell.identifier {
                    if id == .interfaceLock {
                        cell.setToggleSwitch(state: interfaceDisabled)
                    } else {
                        cell.alpha = interfaceDisabled ? 0.5 : 1
                    }
                }
            }
            collectionView.allowsSelection = !interfaceDisabled
        }
    }

    override init() {
        super.init()
        mediaPlayerActionSheetDelegate = self
        mediaPlayerActionSheetDataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MediaMoreOptionsActionSheet: MediaPlayerActionSheetDelegate {
    func mediaPlayerActionSheetHeaderTitle() -> String? {
        return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
    }

    func mediaPlayerDidToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        guard let moreOptionsDelegate = moreOptionsDelegate else {
            preconditionFailure("MediaMoreOptionsActionSheet: MoreOptionsActionSheetDelegate not set")
        }

        if let id = cell.identifier, id == .interfaceLock {
            moreOptionsDelegate.mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: state)
        }
    }
}

extension MediaMoreOptionsActionSheet: MediaPlayerActionSheetDataSource {
    
    var configurableCellModels: [ActionSheetCellModel] {
        let models: [ActionSheetCellModel] = [
            ActionSheetCellModel(
                title:NSLocalizedString("VIDEO_FILTER", comment: ""),
                imageIdentifier:"filter",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .filter
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("PLAYBACK_SPEED", comment: ""),
                imageIdentifier:"playback",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .playback
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("EQUALIZER_CELL_TITLE", comment: ""),
                imageIdentifier:"equalizer",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .equalizer
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("BUTTON_SLEEP_TIMER", comment: ""),
                imageIdentifier:"speedIcon",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .sleepTimer
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: ""),
                imageIdentifier:"iconLock",
                accessoryType: .toggleSwitch,
                cellIdentifier: .interfaceLock
            )
        ]
        return models
    }
}
