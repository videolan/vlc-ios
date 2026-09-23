/*****************************************************************************
 * MediaMoreOptionsActionSheet.swift
 *
 * Copyright © 2019-2022 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCMediaMoreOptionsActionSheetDelegate)
protocol MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool)
    @objc optional func mediaMoreOptionsActionSheetDidAppeared()
    func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier)
    func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier)
    func mediaMoreOptionsActionSheetHideAlertIfNecessary()
    func mediaMoreOptionsActionSheetPresentPopupView(withChild child: UIView)
    func mediaMoreOptionsActionSheetPresentPlaybackSpeed()
    func mediaMoreOptionsActionSheetPresentSleepTimer()
    func mediaMoreOptionsActionSheetPresentVideoFilters()
    func mediaMoreOptionsActionSheetDisplayEqualizerAlert(_ alert: UIAlertController)
    func mediaMoreOptionsActionSheetUpdateProgressBar()
    func mediaMoreOptionsActionSheetGetCurrentMedia() -> VLCMLMedia?
    func mediaMoreOptionsActionSheetDidSelectBookmark(value: Float)
    func mediaMoreOptionsActionSheetDisplayAlert(title: String, message: String,
                                                 action: BookmarkActionIdentifier,
                                                 index: Int,
                                                 isEditing: Bool)
    func mediaMoreOptionsActionSheetDisplayAddBookmarksView(_ bookmarksView: AddBookmarksView)
    func mediaMoreOptionsActionSheetRemoveAddBookmarksView()
    func mediaMoreOptionsActionSheetDidToggleShuffle(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet)
    func mediaMoreOptionsActionSheetDidTapRepeat(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet)
    func mediaMoreOptionsActionSheetPresentABRepeatView(with abView: ABRepeatView)
    func mediaMoreOptionsActionSheetDidSelectAMark()
    func mediaMoreOptionsActionSheetDidSelectBMark()
}

@objc(VLCMediaMoreOptionsActionSheet)
@objcMembers class MediaMoreOptionsActionSheet: MediaPlayerActionSheet {

    // MARK: - Instance variables
    weak var moreOptionsDelegate: MediaMoreOptionsActionSheetDelegate?
    var currentMediaHasChapters: Bool = false
    private var pendingCardIdentifier: ActionSheetCellIdentifier?

    // To be removed when Designs are done for the Filters, Equalizer etc views are added to Figma
    lazy private(set) var mockView: UIView = {
        let v = UIView()
        v.backgroundColor = .green
        v.frame = offScreenFrame
        return v
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

    private(set) lazy var videoFiltersPlaceholderView = UIView()

    private(set) lazy var playbackSpeedPlaceholderView = UIView()

    private(set) lazy var sleepTimerPlaceholderView = UIView()

    private lazy var equalizerView: EqualizerView = {
        let equalizerView = EqualizerView()
        equalizerView.overrideUserInterfaceStyle = .dark

        guard let playbackService = PlaybackService.sharedInstance() as? EqualizerViewDelegate else {
            preconditionFailure("PlaybackService should be EqualizerViewDelegate.")
        }
        equalizerView.delegate = playbackService
        equalizerView.UIDelegate = self
        return equalizerView
    }()

    private lazy var chapterView: ChapterView = {
        let chapterView = ChapterView.init(frame: offScreenFrame)
        chapterView.overrideUserInterfaceStyle = .dark
        chapterView.delegate = self
        return chapterView
    }()

    private lazy var bookmarksView: BookmarksView = {
        let bookmarksView = BookmarksView(frame: offScreenFrame)
        bookmarksView.overrideUserInterfaceStyle = .dark
        bookmarksView.delegate = self
        return bookmarksView
    }()

    private lazy var addBookmarksView: AddBookmarksView = {
        let addBookmarksView = bookmarksView.getAddBookmarksView()
        return addBookmarksView
    }()

    private lazy var abRepeatView: ABRepeatView = {
        let abRepeatView = ABRepeatView(frame: CGRect(x: 0, y: 0, width: 500, height: 100))
        abRepeatView.delegate = self
        return abRepeatView
    }()

    // MARK: - Initializers
    override init() {
        super.init()
        mediaPlayerActionSheetDelegate = self
        mediaPlayerActionSheetDataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        removeCurrentChild()
        removeActionSheet()
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidAppeared?()
        bookmarksView.update()
    }

    func hidePlayer() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidAppeared?()
    }

    // MARK: - Instance Methods
    func resetEqualizer() {
        equalizerView.resetEqualizer()
    }

    func updateThemes() {
        equalizerView.setupTheme()
        chapterView.setupTheme()
        bookmarksView.setupTheme()
    }

    func configureRepeatMode() -> (image: UIImage?, title: String, isEnabled: Bool) {
        var image: UIImage?
        var localization: String = ""
        var isEnabled: Bool = false
        let playbackService = PlaybackService.sharedInstance()
        switch playbackService.repeatMode {
        case .doNotRepeat:
            isEnabled = false
            image = UIImage(named: "iconRepeat")
            localization = NSLocalizedString("MENU_REPEAT_DISABLED", comment: "")
        case .repeatCurrentItem:
            isEnabled = true
            image = UIImage(named: "iconRepeatOne")
            localization = NSLocalizedString("MENU_REPEAT_SINGLE", comment: "")
        case .repeatAllItems:
            isEnabled = true
            image = UIImage(named: "iconRepeat")
            localization = NSLocalizedString("MENU_REPEAT_ALL", comment: "")
        @unknown default: break

        }
        return (image, localization, isEnabled)
    }

    func configureShuffleMode() -> (image: UIImage?, title: String, isEnabled: Bool) {
        let playbackService = PlaybackService.sharedInstance()
        let image: UIImage? = UIImage(named: "iconShuffle")
        let localization: String = playbackService.isShuffleMode ? NSLocalizedString("SHUFFLE", comment: "") : NSLocalizedString("SHUFFLE_DISABLED", comment: "")
        let isEnabled: Bool = playbackService.isShuffleMode

        return (image, localization, isEnabled)
    }

    func addView(_ view: ActionSheetCellIdentifier) {
        switch view {
        case .equalizer:
            openOptionView(equalizerView)
        case .chapters:
            openOptionView(chapterView)
        case .bookmarks:
            openOptionView(bookmarksView)
        case .addBookmarks:
            openOptionView(addBookmarksView)
        default:
            openOptionView(mockView)
        }
    }

    func deleteBookmarkAt(row: Int) {
        bookmarksView.deleteBookmarkAt(row: row)
    }

    func renameBookmarkAt(name: String, row: Int) {
        bookmarksView.renameBookmarkAt(name: name, row: row)
    }
}

// MARK: - EqualizeViewUIDelegate
extension MediaMoreOptionsActionSheet: EqualizerViewUIDelegate {
    func equalizerViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .equalizer)
    }

    func equalizerViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .equalizer)
    }

    func displayAlert(_ alert: UIAlertController) {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDisplayEqualizerAlert(alert)
    }
}

// MARK: - ChapterViewDelegate
extension MediaMoreOptionsActionSheet: ChapterViewDelegate {
    func chapterViewDelegateDidSelectChapter(_ chapterView: ChapterView) {
        removeActionSheet()
        moreOptionsDelegate?.mediaMoreOptionsActionSheetUpdateProgressBar()
    }
}

// MARK: - BookmarksViewDelegate
extension MediaMoreOptionsActionSheet: BookmarksViewDelegate {
    func bookmarksViewGetCurrentPlayingMedia() -> VLCMLMedia? {
        return moreOptionsDelegate?.mediaMoreOptionsActionSheetGetCurrentMedia()
    }

    func bookmarksViewDidSelectBookmark(value: Float) {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidSelectBookmark(value: value)
        removeActionSheet()
    }

    func bookmarksViewShouldDisableGestures(_ disable: Bool) {
        shouldDisablePanGesture(disable)
        shouldDisableDragDownGesture(disable)
    }

    func bookmarksViewDisplayAlert(action: BookmarkActionIdentifier, index: Int, isEditing: Bool) {
        var title = String()
        var message = String()

        if action == .delete {
            title = NSLocalizedString("BOOKMARK_DELETE_TITLE", comment: "")
            message = NSLocalizedString("BOOKMARK_DELETE_MESSAGE", comment: "")
        } else if action == .rename {
            message = bookmarksView.getBookmarkNameAt(row: index)
            title = NSLocalizedString("BOOKMARK_RENAME_TITLE", comment: "")
        }

        moreOptionsDelegate?.mediaMoreOptionsActionSheetDisplayAlert(title: title, message: message, action: action, index: index, isEditing: isEditing)
    }

    func bookmarksViewOpenAddBookmarksView() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDisplayAddBookmarksView(addBookmarksView)
        removeActionSheet()
    }

    func bookmarksViewCloseAddBookmarksView() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetRemoveAddBookmarksView()
    }
}

// MARK: - ABRepeatViewDelegate
extension MediaMoreOptionsActionSheet: ABRepeatViewDelegate {
    func abRepeatViewDidSelectAMark() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidSelectAMark()
    }

    func abRepeatViewDidSelectBMark() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidSelectBMark()
    }

    func abRepeatViewShowIcon(_ option: OptionsNavigationBarIdentifier) {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: option)
    }

    func abRepeatViewHideIcon(_ option: OptionsNavigationBarIdentifier) {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: option)
    }
}

// MARK: - Cards
extension MediaMoreOptionsActionSheet {
    func closeAndPresentCard(for identifier: ActionSheetCellIdentifier) {
        pendingCardIdentifier = identifier
        removeActionSheet()
    }

    func presentPendingCard() {
        guard let identifier = pendingCardIdentifier else {
            return
        }

        pendingCardIdentifier = nil
        switch identifier {
        case .playback:
            moreOptionsDelegate?.mediaMoreOptionsActionSheetPresentPlaybackSpeed()
        case .sleepTimer:
            moreOptionsDelegate?.mediaMoreOptionsActionSheetPresentSleepTimer()
        case .filter:
            moreOptionsDelegate?.mediaMoreOptionsActionSheetPresentVideoFilters()
        default:
            break
        }
    }
}

// MARK: - MediaPlayerActionSheetDelegate
extension MediaMoreOptionsActionSheet: MediaPlayerActionSheetDelegate {
    func mediaPlayerActionSheetHeaderTitle() -> String? {
        if moreOptionsDelegate is AudioPlayerViewController {
            return NSLocalizedString("MORE_OPTIONS_HEADER_AUDIO_TITLE", comment: "")
        }

        return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
    }

    func mediaPlayerDidToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        guard let moreOptionsDelegate = moreOptionsDelegate else {
            preconditionFailure("MediaMoreOptionsActionSheet: MoreOptionsActionSheetDelegate not set")
        }

        guard let identifier = cell.identifier else {
            return
        }

        if identifier == .interfaceLock {
            moreOptionsDelegate.mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: state)
            interfaceDisabled = state
        }
    }
}

// MARK: - MediaPlayerActionSheetDataSource
extension MediaMoreOptionsActionSheet: MediaPlayerActionSheetDataSource {

    private func selectViewToPresent(for cell: ActionSheetCellIdentifier) -> UIView {
        switch cell {
        case .filter:
            return videoFiltersPlaceholderView
        case .playback:
            return playbackSpeedPlaceholderView
        case .sleepTimer:
            return sleepTimerPlaceholderView
        case .equalizer:
            return equalizerView
        case .chapters:
            return chapterView
        case .bookmarks:
            return bookmarksView
        case .abRepeat:
            return abRepeatView
        default:
            return mockView
        }
    }

    var configurableCellModels: [ActionSheetCellModel] {
        var models: [ActionSheetCellModel] = []
        let isAudioPlayer: Bool = moreOptionsDelegate is AudioPlayerViewController

        ActionSheetCellIdentifier.allCases.forEach {
            if $0 == .chapters && currentMediaHasChapters == false {
                // Do not show the chapters category when there are no chapters.
                return
            }

            // Do not display these options in the action sheet.
            if [ .addBookmarks, .playNextItem, .playlistPlayNextItem ].contains($0) {
                return
            }

            if $0 == .filter && isAudioPlayer {
                // Do not show the video filters category when the audio player is shown.
                return
            }

            let cellModel = ActionSheetCellModel(
                title: String(describing: $0),
                imageIdentifier: $0.rawValue,
                viewToPresent: selectViewToPresent(for: $0),
                cellIdentifier: $0
            )

            if $0 == .interfaceLock {
                cellModel.accessoryType = .toggleSwitch
                cellModel.viewToPresent = nil
            } else if $0 == .equalizer {
                cellModel.accessoryType = .popup
            } else if $0 == .repeatShuffle {
                cellModel.accessoryType = .none
                cellModel.viewToPresent = mockView
                let repeatTuple = configureRepeatMode()
                cellModel.iconImage = repeatTuple.image
                cellModel.title = repeatTuple.title
            }
            models.append(cellModel)
        }
        return models
    }
}
