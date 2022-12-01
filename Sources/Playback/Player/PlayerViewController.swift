/*****************************************************************************
 * PlayerViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class PlayerViewController: UIViewController {
    // MARK: - Properties

    var services: Services
    var playerController: PlayerController
    var playbackService: PlaybackService = PlaybackService.sharedInstance()
    var queueViewController: QueueViewController?
    var alertController: UIAlertController?
    var seekBy: Int = 0

    lazy var mediaNavigationBar: MediaNavigationBar = {
        var mediaNavigationBar = MediaNavigationBar(frame: .zero,
                                                    rendererDiscovererService: services.rendererDiscovererManager)
        mediaNavigationBar.delegate = self
        mediaNavigationBar.presentingViewController = self
        mediaNavigationBar.chromeCastButton.isHidden =
            self.playbackService.renderer == nil
        return mediaNavigationBar
    }()

    lazy var mediaScrubProgressBar: MediaScrubProgressBar = {
        var mediaScrubProgressBar: MediaScrubProgressBar = MediaScrubProgressBar()
        return mediaScrubProgressBar
    }()

    lazy var moreOptionsActionSheet: MediaMoreOptionsActionSheet = {
        var moreOptionsActionSheet = MediaMoreOptionsActionSheet()
        moreOptionsActionSheet.moreOptionsDelegate = self
        return moreOptionsActionSheet
    }()

    lazy var optionsNavigationBar: OptionsNavigationBar = {
        var optionsNavigationBar = OptionsNavigationBar()
        optionsNavigationBar.delegate = self
        return optionsNavigationBar
    }()

    lazy var equalizerPopupView: PopupView = {
        let equalizerPopupView = PopupView()
        equalizerPopupView.delegate = self
        return equalizerPopupView
    }()

    var addBookmarksView: AddBookmarksView? = nil

    // MARK: - Init

    @objc init(services: Services, playerController: PlayerController) {
        self.services = services
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func showPopup(_ popupView: PopupView, with contentView: UIView, accessoryViewsDelegate: PopupViewAccessoryViewsDelegate? = nil) {
        popupView.isShown = true

        popupView.addContentView(contentView, constraintWidth: true)
        if let accessoryViewsDelegate = accessoryViewsDelegate {
            popupView.accessoryViewsDelegate = accessoryViewsDelegate
        }

        view.addSubview(popupView)
    }

    // MARK: - Private methods

    private func jumpBackwards(_ interval: Int = 10) {
        playbackService.jumpBackward(Int32(interval))
    }

    private func jumpForwards(_ interval: Int = 10) {
        playbackService.jumpForward(Int32(interval))
    }

    private func showIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = false
        }, completion: nil)
    }

    private func openOptionView(view: MediaPlayerActionSheetCellIdentifier) {
        present(moreOptionsActionSheet, animated: true, completion: {
            self.moreOptionsActionSheet.addView(view)
        })
    }

    private func hideIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = true
        }, completion: nil)
    }

    private func resetVideoFilters() {
        hideIcon(button: optionsNavigationBar.videoFiltersButton)
        moreOptionsActionSheet.resetVideoFilters()
    }

    private func resetPlaybackSpeed() {
        hideIcon(button: optionsNavigationBar.playbackSpeedButton)
        moreOptionsActionSheet.resetPlaybackSpeed()
    }

    private func resetEqualizer() {
        moreOptionsActionSheet.resetEqualizer()
        hideIcon(button: optionsNavigationBar.equalizerButton)
    }

    private func resetSleepTimer() {
        hideIcon(button: optionsNavigationBar.sleepTimerButton)
        moreOptionsActionSheet.resetSleepTimer()
    }

    private func handleReset(button: UIButton) {
        switch button {
        case optionsNavigationBar.videoFiltersButton:
            resetVideoFilters()
            return
        case optionsNavigationBar.playbackSpeedButton:
            resetPlaybackSpeed()
            return
        case optionsNavigationBar.equalizerButton:
            resetEqualizer()
            return
        case optionsNavigationBar.sleepTimerButton:
            resetSleepTimer()
            return
        default:
            assertionFailure("VideoPlayerViewController: Unvalid button.")
        }
    }

    // MARK: - Gesture handlers

    @objc func handlePlayPauseGesture() {
        guard playerController.isPlayPauseGestureEnabled else {
            return
        }

        if playbackService.isPlaying {
            playbackService.pause()
        } else {
            playbackService.play()
        }
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension PlayerViewController: VLCPlaybackServiceDelegate {
    func savePlaybackState(_ playbackService: PlaybackService) {
        services.medialibraryService.savePlaybackState(from: playbackService)
    }

    func media(forPlaying media: VLCMedia?) -> VLCMLMedia? {
        services.medialibraryService.fetchMedia(with: media?.url)
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        mediaScrubProgressBar.updateInterfacePosition()
    }
}

// MARK: - MediaNavigationBarDelegate

extension PlayerViewController: MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar) {
        playbackService.stopPlayback()
    }

    func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar) {
        playbackService.stopPlayback()
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension PlayerViewController: MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        // DISABLE GESTURES
    }

    func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .playbackSpeed:
            showIcon(button: optionsNavigationBar.playbackSpeedButton)
            break
        case .sleepTimer:
            showIcon(button: optionsNavigationBar.sleepTimerButton)
            break
        case .equalizer:
            showIcon(button: optionsNavigationBar.equalizerButton)
            break
        default:
            assertionFailure("AudioPlayerViewController: Invalid option.")
        }
    }

    func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .playbackSpeed:
            hideIcon(button: optionsNavigationBar.playbackSpeedButton)
            break
        case .sleepTimer:
            hideIcon(button: optionsNavigationBar.sleepTimerButton)
            break
        case .equalizer:
            hideIcon(button: optionsNavigationBar.equalizerButton)
            break
        default:
            assertionFailure("AudioPlayerViewController: Invalid option.")
        }
    }

    func mediaMoreOptionsActionSheetHideAlertIfNecessary() {
        guard let alertController = alertController else {
            return
        }

        alertController.dismiss(animated: true)
        self.alertController = nil
    }

    func mediaMoreOptionsActionSheetPresentPopupView(withChild child: UIView) {
        if let equalizerView = child as? EqualizerView {
            guard !equalizerPopupView.isShown else {
                return
            }

            showPopup(equalizerPopupView, with: equalizerView, accessoryViewsDelegate: equalizerView)
        }
    }

    func mediaMoreOptionsActionSheetUpdateProgressBar() {
        if !playbackService.isPlaying {
            playbackService.playPause()
        }
    }

    func mediaMoreOptionsActionSheetGetCurrentMedia() -> VLCMLMedia? {
        guard let media = playbackService.currentlyPlayingMedia else {
            return nil
        }

        return services.medialibraryService.fetchMedia(with: media.url)
    }

    func mediaMoreOptionsActionSheetDidSelectBookmark(value: Float) {
        mediaScrubProgressBar.updateSliderWithValue(value: value)

        if !playbackService.isPlaying {
            playbackService.playPause()
        }
    }

    func mediaMoreOptionsActionSheetDisplayAlert(title: String, message: String, action: BookmarkActionIdentifier, index: Int, isEditing: Bool) {
        moreOptionsActionSheet.dismiss(animated: true, completion: {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            var actionTitle = NSLocalizedString("BUTTON_CANCEL", comment: "")
            let cancelAction = UIAlertAction(title: actionTitle, style: .cancel) { _ in
                if !isEditing {
                    self.openOptionView(view: .bookmarks)
                }
            }

            alertController.addAction(cancelAction)

            if action == .delete {
                actionTitle = NSLocalizedString("BUTTON_DELETE", comment: "")
                let mainAction = UIAlertAction(title: actionTitle, style: .destructive, handler: { _ in
                    self.moreOptionsActionSheet.deleteBookmarkAt(row: index)
                    if !isEditing {
                        self.openOptionView(view: .bookmarks)
                    }
                })

                alertController.addAction(mainAction)
            } else if action == .rename {
                alertController.addTextField(configurationHandler: { field in
                    field.text = message
                    field.returnKeyType = .done
                })

                actionTitle = NSLocalizedString("BUTTON_RENAME", comment: "")
                let mainAction = UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                    guard let field = alertController.textFields else {
                        return
                    }

                    guard let newName = field[0].text else {
                        return
                    }

                    self.moreOptionsActionSheet.renameBookmarkAt(name: newName, row: index)

                    if !isEditing {
                        self.openOptionView(view: .bookmarks)
                    }
                })

                alertController.addAction(mainAction)
            }

            self.present(alertController, animated: true, completion: nil)
            self.alertController = alertController
        })
    }

    func mediaMoreOptionsActionSheetDisplayAddBookmarksView(_ bookmarksView: AddBookmarksView) {
        mediaNavigationBar.isHidden = true

        bookmarksView.translatesAutoresizingMaskIntoConstraints = false

        addBookmarksView = bookmarksView
    }

    func mediaMoreOptionsActionSheetRemoveAddBookmarksView() {
        mediaNavigationBar.isHidden = false

        if let bookmarksView = addBookmarksView {
            bookmarksView.removeFromSuperview()
        }

        addBookmarksView = nil
    }

    func mediaMoreOptionsActionSheetDidToggleShuffle(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        playbackService.isShuffleMode = !playbackService.isShuffleMode

        if playerController.isRememberStateEnabled {
            UserDefaults.standard.setValue(playbackService.isShuffleMode, forKey: kVLCPlayerIsShuffleEnabled)
        }

        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    func mediaMoreOptionsActionSheetDidTapRepeat(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        playbackService.toggleRepeatMode()
        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }
}

// MARK: - OptionsNavigationBarDelegate

extension PlayerViewController: OptionsNavigationBarDelegate {
    func optionsNavigationBarDisplayAlert(title: String, message: String, button: UIButton) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)

        let resetButton = UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.handleReset(button: button)
        }

        alertController.addAction(cancelButton)
        alertController.addAction(resetButton)

        self.present(alertController, animated: true)
        self.alertController = alertController
    }

    func optionsNavigationBarGetRemainingTime() -> String {
        return moreOptionsActionSheet.getRemainingTime()
    }
}

// MARK: - PopupViewDelegate

extension PlayerViewController: PopupViewDelegate {
    @objc func popupViewDidClose(_ popupView: PopupView) {
        popupView.isShown = false
    }
}

// MARK: - Keyboard Controls

extension PlayerViewController {
    @objc func keyLeftArrow() {
        jumpBackwards(seekBy)
    }

    @objc func keyRightArrow() {
        jumpForwards(seekBy)
    }

    @objc func keyRightBracket() {
        playbackService.playbackRate *= 1.5
    }

    @objc func keyLeftBracket() {
        playbackService.playbackRate *= 0.75
    }

    @objc func keyEqual() {
        playbackService.playbackRate = 1.0
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = [
            UIKeyCommand(input: " ",
                         modifierFlags: [],
                         action: #selector(handlePlayPauseGesture),
                         discoverabilityTitle: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")),
            UIKeyCommand(input: "\r",
                         modifierFlags: [],
                         action: #selector(handlePlayPauseGesture),
                         discoverabilityTitle: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow,
                         modifierFlags: [],
                         action: #selector(keyLeftArrow),
                         discoverabilityTitle: NSLocalizedString("KEY_JUMP_BACKWARDS", comment: "")),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow,
                         modifierFlags: [],
                         action: #selector(keyRightArrow),
                         discoverabilityTitle: NSLocalizedString("KEY_JUMP_FORWARDS", comment: "")),
            UIKeyCommand(input: "[",
                         modifierFlags: [],
                         action: #selector(keyRightBracket),
                         discoverabilityTitle: NSLocalizedString("KEY_INCREASE_PLAYBACK_SPEED", comment: "")),
            UIKeyCommand(input: "]",
                         modifierFlags: [],
                         action: #selector(keyLeftBracket),
                         discoverabilityTitle: NSLocalizedString("KEY_DECREASE_PLAYBACK_SPEED", comment: ""))
        ]

        if abs(playbackService.playbackRate - 1.0) > .ulpOfOne {
            commands.append(UIKeyCommand(input: "=",
                                         modifierFlags: [],
                                         action: #selector(keyEqual),
                                         discoverabilityTitle: NSLocalizedString("KEY_RESET_PLAYBACK_SPEED",
                                                                                 comment: "")))
        }

        if #available(iOS 15, *) {
            commands.forEach {
                if $0.input == UIKeyCommand.inputRightArrow
                    || $0.input == UIKeyCommand.inputLeftArrow {
                    ///UIKeyCommand.wantsPriorityOverSystemBehavior is introduced in iOS 15 SDK
                    ///but we actually still use Xcode 12.4 on CI. This old version only provides
                    ///SDK for iOS 14.4 max. Hence we use ObjC apis to call the method and still
                    ///have the ability to build with older Xcode versions.
                    let selector = NSSelectorFromString("setWantsPriorityOverSystemBehavior:")
                    if $0.responds(to: selector) {
                        $0.perform(selector, with: true)
                    }
                }
            }
        }

        return commands
    }
}
