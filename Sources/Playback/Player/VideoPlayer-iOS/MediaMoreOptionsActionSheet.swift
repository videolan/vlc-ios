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

@objc (VLCMediaMoreOptionsActionSheetDelegate)
protocol MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool)
    @objc optional func mediaMoreOptionsActionSheetDidAppeared()
    func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier)
    func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier)
    func mediaMoreOptionsActionSheetHideAlertIfNecessary()
    func mediaMoreOptionsActionSheetPresentPopupView(withChild child: UIView)
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
    @objc optional func mediaMoreOptionsActionSheetShowPlaybackSpeedShortcut(_ displayView: Bool)
}

@objc (VLCMediaMoreOptionsActionSheet)
@objcMembers class MediaMoreOptionsActionSheet: MediaPlayerActionSheet {

    // MARK: - Instance variables
    weak var moreOptionsDelegate: MediaMoreOptionsActionSheetDelegate?
    var currentMediaHasChapters: Bool = false

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

    private lazy var videoFiltersView: VideoFiltersView = {
        let videoFiltersView = Bundle.main.loadNibNamed("VideoFiltersView",
                                                        owner: nil,
                                                        options: nil)?.first as! VideoFiltersView
        videoFiltersView.frame = offScreenFrame
        if #available(iOS 13.0, *) {
            videoFiltersView.overrideUserInterfaceStyle = .dark
        }
        videoFiltersView.delegate = self
        return videoFiltersView
    }()

    private lazy var playbackSpeedView: PlaybackSpeedView = {
        let playbackSpeedView = Bundle.main.loadNibNamed("PlaybackSpeedView",
                                                         owner: nil,
                                                         options: nil)?.first as! PlaybackSpeedView

        playbackSpeedView.frame = offScreenFrame
        if #available(iOS 13.0, *) {
            playbackSpeedView.overrideUserInterfaceStyle = .dark
        }
        playbackSpeedView.delegate = self
        playbackSpeedView.setupShortcutView()
        return playbackSpeedView
    }()

    private lazy var sleepTimerView: SleepTimerView = {
        let nib = UINib(nibName: "SleepTimerView", bundle: nil)
        let sleepTimerView = nib.instantiate(withOwner: nil, options: nil).first as! SleepTimerView
        sleepTimerView.frame = offScreenFrame
        if #available(iOS 13.0, *) {
            sleepTimerView.overrideUserInterfaceStyle = .dark
        }
        sleepTimerView.delegate = self
        return sleepTimerView
    }()

    private lazy var equalizerView: EqualizerView = {
        let equalizerView = EqualizerView()
        if #available(iOS 13.0, *) {
            equalizerView.overrideUserInterfaceStyle = .dark
        }

        guard let playbackService = PlaybackService.sharedInstance() as? EqualizerViewDelegate else {
            preconditionFailure("PlaybackService should be EqualizerViewDelegate.")
        }
        equalizerView.delegate = playbackService
        equalizerView.UIDelegate = self
        return equalizerView
    }()

    private lazy var chapterView: ChapterView = {
        let chapterView = ChapterView.init(frame: offScreenFrame)
        if #available(iOS 13.0, *) {
            chapterView.overrideUserInterfaceStyle = .dark
        }
        chapterView.delegate = self
        return chapterView
    }()

    private lazy var bookmarksView: BookmarksView = {
        let bookmarksView = BookmarksView(frame: offScreenFrame)
        if #available(iOS 13.0, *) {
            bookmarksView.overrideUserInterfaceStyle = .dark
        }
        bookmarksView.delegate = self
        return bookmarksView
    }()

    private lazy var addBookmarksView: AddBookmarksView = {
        let addBookmarksView = bookmarksView.getAddBookmarksView()
        return addBookmarksView
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
    func resetVideoFilters() {
        videoFiltersView.resetIfNeeded()
    }

    func resetPlaybackSpeed() {
        playbackSpeedView.reset()
    }

    func resetEqualizer() {
        equalizerView.resetEqualizer()
    }

    func resetSleepTimer() {
        sleepTimerView.reset()
    }

    func getRemainingTime() -> String {
        return sleepTimerView.remainingTime()
    }

    func updateThemes() {
        videoFiltersView.setupTheme()
        playbackSpeedView.setupTheme()
        sleepTimerView.setupTheme()
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

    func resetOptionsIfNecessary() {
        playbackSpeedView.resetSlidersIfNeeded()
        updateThemes()
    }

    func addView(_ view: ActionSheetCellIdentifier) {
        switch view {
        case .filter:
            openOptionView(videoFiltersView)
        case .playback:
            openOptionView(playbackSpeedView)
        case .sleepTimer:
            openOptionView(sleepTimerView)
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

// MARK: - VideoFiltersViewDelegate
extension MediaMoreOptionsActionSheet: VideoFiltersViewDelegate {
    func videoFiltersViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .videoFilters)
    }

    func videoFiltersViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .videoFilters)
    }
}

// MARK: - PlaybackSpeedViewDelegate
extension MediaMoreOptionsActionSheet: PlaybackSpeedViewDelegate {
    func playbackSpeedViewHandleOptionChange(title: String) {
        self.headerView.title.text = title
    }

    func playbackSpeedViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .playbackSpeed)
    }

    func playbackSpeedViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .playbackSpeed)
    }

    func playbackSpeedViewCanDisplayShortcutView() -> Bool {
        return moreOptionsDelegate is AudioPlayerViewController
    }

    func playbackSpeedViewHandleShortcutSwitchChange(displayView: Bool) {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowPlaybackSpeedShortcut?(displayView)
    }
}

// MARK: - SleepTimerViewDelegate
extension MediaMoreOptionsActionSheet: SleepTimerViewDelegate {
    func sleepTimerViewCloseActionSheet() {
        removeActionSheet()
    }

    func sleepTimerViewShowAlert(message: String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        if #available(iOS 13.0, *) {
            alert.view.overrideUserInterfaceStyle = .dark
        }
        alert.view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        alert.view.layer.cornerRadius = 15

        self.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true, completion: {
                self.sleepTimerViewCloseActionSheet()
            })
        }
    }

    func sleepTimerViewHideAlertIfNecessary() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideAlertIfNecessary()
    }

    func sleepTimerViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .sleepTimer)
    }

    func sleepTimerViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .sleepTimer)
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

    func bookmarksViewOpenBookmarksView() {
        openOptionView(bookmarksView)
    }

    func bookmarksViewOpenAddBookmarksView() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDisplayAddBookmarksView(addBookmarksView)
        removeActionSheet()
    }

    func bookmarksViewCloseAddBookmarksView() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetRemoveAddBookmarksView()
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
            return videoFiltersView
        case .playback:
            return playbackSpeedView
        case .sleepTimer:
            return sleepTimerView
        case .equalizer:
            return equalizerView
        case .chapters:
            return chapterView
        case .bookmarks:
            return bookmarksView
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

            if $0 == .addBookmarks || $0 == .blackBackground {
                return
            }

            if $0 == .filter && isAudioPlayer {
                // Do not show the video filters category when the audio player is shown.
                return
            }

            let cellModel = ActionSheetCellModel(
                title: String(describing: $0),
                imageIdentifier: $0.rawValue == "bookmarks" ? "chapters" : $0.rawValue,
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
