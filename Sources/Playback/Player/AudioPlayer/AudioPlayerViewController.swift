/*****************************************************************************
 * AudioPlayerViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022-2023 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc (VLCAudioPlayerViewControllerDelegate)
protocol AudioPlayerViewControllerDelegate: AnyObject {
    func audioPlayerViewControllerDidMinimize(_ audioPlayerViewController: AudioPlayerViewController)
    func audioPlayerViewControllerDidClose(_ audioPlayerViewController: AudioPlayerViewController)
    func audioPlayerViewControllerShouldBeDisplayed(_ audioPlayerViewController: AudioPlayerViewController) -> Bool
}

@objc (VLCAudioPlayerViewController)
class AudioPlayerViewController: PlayerViewController {
    // MARK: - Properties

    @objc weak var delegate: AudioPlayerViewControllerDelegate?

    private var isQueueHidden: Bool = true

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return UIInterfaceOrientationMask.allButUpsideDown }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    lazy var audioPlayerView: AudioPlayerView = {
        let audioPlayerView = AudioPlayerView(frame: .zero)
        audioPlayerView.delegate = self
        return audioPlayerView
    }()

    private lazy var moreOptionsButton: UIButton = {
        let moreOptionsButton = UIButton(type: .custom)
        moreOptionsButton.setImage(UIImage(named: "iconMoreOptions"), for: .normal)
        moreOptionsButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        moreOptionsButton.addTarget(self, action: #selector(handleMoreOptionsButton), for: .touchUpInside)
        return moreOptionsButton
    }()

    private lazy var equalizerPopupTopConstraint: NSLayoutConstraint = {
        equalizerPopupView.topAnchor.constraint(equalTo: audioPlayerView.navigationBarView.topAnchor, constant: 10)
    }()

    private lazy var equalizerPopupBottomConstraint: NSLayoutConstraint = {
        equalizerPopupView.bottomAnchor.constraint(equalTo: audioPlayerView.progressionView.topAnchor, constant: -10)
    }()

    // MARK: - Init

    @objc override init(mediaLibraryService: MediaLibraryService, rendererDiscovererManager: VLCRendererDiscovererManager, playerController: PlayerController) {
        super.init(mediaLibraryService: mediaLibraryService, rendererDiscovererManager: rendererDiscovererManager, playerController: playerController)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackSpeedHasChanged(_:)), name: Notification.Name("ChangePlaybackSpeed"), object: nil)

        self.playerController.delegate = self
        mediaNavigationBar.addMoreOptionsButton(moreOptionsButton)
        audioPlayerView.setupNavigationBar(with: mediaNavigationBar)
        audioPlayerView.updateThumbnailImageView()
        audioPlayerView.setupPlaybackSpeed()
        audioPlayerView.setupBackgroundColor()
        mediaScrubProgressBar.updateBackgroundAlpha(with: 0.0)
        audioPlayerView.setupProgressView(with: mediaScrubProgressBar)
        audioPlayerView.setupExternalOutputView(with: externalOutputView)
        audioPlayerView.setupSliders()
        setupAudioPlayerViewConstraints()
        setupOptionsNavigationBar()
        setupStatusLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        playbackService.delegate = self
        playbackService.recoverPlaybackState()
        audioPlayerView.updateThumbnailImageView()
        audioPlayerView.setupBackgroundColor()
        audioPlayerView.setupPlaybackSpeed()
        setupGestures()
        playModeUpdated()

        if playbackService.isPlayingOnExternalScreen() {
            changeOutputView(to: externalOutputView.displayView)
        }

        let orientation = getDeviceOrientation()
        audioPlayerView.updateConstraints(for: orientation)
        mediaScrubProgressBar.shouldHideScrubLabels = orientation.isLandscape ? true : false

        let displayShortcutView: Bool = UserDefaults.standard.bool(forKey: kVLCPlayerShowPlaybackSpeedShortcut)
        audioPlayerView.shouldDisplaySecondaryStackView(displayShortcutView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        playerController.isInterfaceLocked = false
        queueViewController?.hide()
        numberOfGestureSeek = 0
        totalSeekDuration = 0
        previousSeekState = .default
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let orientation = getDeviceOrientation()
        audioPlayerView.updateConstraints(for: orientation)
        mediaScrubProgressBar.shouldHideScrubLabels = orientation.isLandscape ? true : false
    }

    // MARK: Public methods

    override func minimizePlayer() {
        delegate?.audioPlayerViewControllerDidMinimize(self)
    }
    
    @objc func playbackSpeedHasChanged(_ notification: NSNotification) {
        audioPlayerView.setupPlaybackSpeed()
    }

    override func showPopup(_ popupView: PopupView, with contentView: UIView, accessoryViewsDelegate: PopupViewAccessoryViewsDelegate? = nil) {
        moreOptionsButton.isEnabled = false
        super.showPopup(popupView, with: contentView, accessoryViewsDelegate: accessoryViewsDelegate)

        let iPhone5width: CGFloat = 320
        let leadingConstraint = popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
        let trailingConstraint = popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        leadingConstraint.priority = .required
        trailingConstraint.priority = .required

        let newConstraints = [
            equalizerPopupTopConstraint,
            equalizerPopupBottomConstraint,
            leadingConstraint,
            trailingConstraint,
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.widthAnchor.constraint(greaterThanOrEqualToConstant: iPhone5width)
        ]

        NSLayoutConstraint.activate(newConstraints)
    }

    @objc func setupQueueViewController(with qvc: QueueViewController) {
        queueViewController = qvc
        queueViewController?.delegate = nil
    }

    @objc func handleMoreOptionsButton() {
        present(moreOptionsActionSheet, animated: false) {
            [unowned self] in
            self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
        }
    }

    override func setupGestures() {
        super.setupGestures()

        audioPlayerView.thumbnailView.addGestureRecognizer(panRecognizer)
        audioPlayerView.thumbnailView.addGestureRecognizer(leftSwipeRecognizer)
        audioPlayerView.thumbnailView.addGestureRecognizer(rightSwipeRecognizer)
        audioPlayerView.thumbnailView.addGestureRecognizer(doubleTapGestureRecognizer)
        audioPlayerView.addGestureRecognizer(playPauseRecognizer)
        audioPlayerView.addGestureRecognizer(pinchRecognizer)

        panRecognizer.require(toFail: leftSwipeRecognizer)
        panRecognizer.require(toFail: rightSwipeRecognizer)
    }

    @objc override func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        if recognizer.velocity < 0 && playerController.isCloseGestureEnabled {
            delegate?.audioPlayerViewControllerDidMinimize(self)
        }
    }

    override func changeOutputView(to output: UIView?) {
        guard output == externalOutputView.displayView else {
            externalOutputView.isHidden = true
            audioPlayerView.thumbnailView.isHidden = false
            return
        }

        externalOutputView.updateUI(rendererItem: playbackService.renderer, title: nil)
        externalOutputView.isHidden = false
        audioPlayerView.thumbnailView.isHidden = true
    }

    override func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        let screenWidth: CGFloat = view.frame.size.width
        let middleBoundary: CGFloat = screenWidth / 2.0

        let tapPosition = sender.location(in: view)

        // Reset number(set to -1/1) of seek when orientation has been changed.
        if tapPosition.x < middleBoundary {
            numberOfGestureSeek = previousSeekState == .forward ? -1 : numberOfGestureSeek - 1
        } else {
            numberOfGestureSeek = previousSeekState == .backward ? 1 : numberOfGestureSeek + 1
        }

        super.handleDoubleTapGesture(sender)
    }

    // MARK: - Private methods

    private func setupAudioPlayerViewConstraints() {
        audioPlayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(audioPlayerView)

        NSLayoutConstraint.activate([
            audioPlayerView.topAnchor.constraint(equalTo: view.topAnchor),
            audioPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            audioPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            audioPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupOptionsNavigationBar() {
        let padding: CGFloat = 10.0

        view.addSubview(optionsNavigationBar)
        NSLayoutConstraint.activate([
            optionsNavigationBar.topAnchor.constraint(equalTo: audioPlayerView.navigationBarView.bottomAnchor, constant: padding),
            optionsNavigationBar.trailingAnchor.constraint(equalTo: audioPlayerView.layoutGuide.trailingAnchor, constant: -padding)
        ])
    }

    private func setupStatusLabel() {
        audioPlayerView.addSubview(statusLabel)
        audioPlayerView.bringSubviewToFront(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: audioPlayerView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: audioPlayerView.centerYAnchor)
        ])
    }

    private func showPlayqueue(from qvc: QueueViewController) {
        qvc.view.removeFromSuperview()
        qvc.removeFromParent()
        qvc.show()
        qvc.topView.isHidden = true
        addChild(qvc)
        qvc.didMove(toParent: self)
        view.layoutIfNeeded()
        qvc.bottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
        qvc.reloadBackground(with: audioPlayerView.thumbnailImageView.image)
        qvc.delegate = nil
    }

    private func updateNavigationBar(with title: String?) {
        mediaNavigationBar.setMediaTitleLabelText(title)
    }

    private func setPlayerInterfaceEnabled(_ enabled: Bool) {
        mediaNavigationBar.closePlaybackButton.isEnabled = enabled
        mediaNavigationBar.queueButton.isEnabled = enabled
        mediaNavigationBar.deviceButton.isEnabled = enabled
        if #available(iOS 11.0, *) {
            mediaNavigationBar.airplayRoutePickerView.isUserInteractionEnabled = enabled
            mediaNavigationBar.airplayRoutePickerView.alpha = !enabled ? 0.5 : 1
        } else {
            mediaNavigationBar.airplayVolumeView.isUserInteractionEnabled = enabled
            mediaNavigationBar.airplayVolumeView.alpha = !enabled ? 0.5 : 1
        }

        mediaScrubProgressBar.progressSlider.isEnabled = enabled
        mediaScrubProgressBar.remainingTimeButton.isEnabled = enabled

        audioPlayerView.setControlsEnabled(enabled)

        shouldDisableGestures(!enabled)

        playerController.isInterfaceLocked = !enabled
    }

    private func getDeviceOrientation() -> UIDeviceOrientation {
        // Return the correct device orientation even if it is detected
        // as flat.
        let orientation = UIDevice.current.orientation

        if orientation.isFlat {
            let statusBarOrientation = UIApplication.shared.statusBarOrientation
            switch statusBarOrientation {
            case .portrait:
                return .portrait
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .unknown
            }
        }

        return orientation
    }
}

// MARK: - AudioPlayerViewDelegate

extension AudioPlayerViewController: AudioPlayerViewDelegate {
    func audioPlayerViewDelegateGetThumbnail(_ audioPlayerView: AudioPlayerView) -> UIImage? {
        guard let image = playbackService.metadata.artworkImage else {
            return PresentationTheme.current.isDark ? UIImage(named: "song-placeholder-dark")
                                                    : UIImage(named: "song-placeholder-white")
        }

        return image
    }
    
    func audioPlayerViewDelegateGetPlaybackSpeed(_ audioPlayerView: AudioPlayerView) -> Float {
        return playbackService.playbackRate
    }

    func audioPlayerViewDelegateDidTapShuffleButton(_ audioPlayerView: AudioPlayerView) {
        updateShuffleState()
    }

    func audioPlayerViewDelegateDidTapPreviousButton(_ audioPlayerView: AudioPlayerView) {
        playbackService.previous()
    }

    func audioPlayerViewDelegateDidTapPlayButton(_ audioPlayerView: AudioPlayerView) {
        playbackService.playPause()
        audioPlayerView.updatePlayButton(isPlaying: playbackService.isPlaying)
    }

    func audioPlayerViewDelegateDidTapNextButton(_ audioPlayerView: AudioPlayerView) {
        playbackService.next()
    }

    func audioPlayerViewDelegateDidTapRepeatButton(_ audioPlayerView: AudioPlayerView) {
        updateRepeatMode()
    }

    func audioPlayerViewDelegateDidTapPlaybackSpeedButton(_ audioPlayerView: AudioPlayerView) {
        var currentSpeed = playbackService.playbackRate
        let speedOffset: Float = 0.25

        if currentSpeed + speedOffset > 2.0 {
            currentSpeed = 1.0
            mediaMoreOptionsActionSheetHideIcon(for: .playbackSpeed)
        } else {
            currentSpeed += speedOffset
            mediaMoreOptionsActionSheetShowIcon(for: .playbackSpeed)
        }

        playbackService.playbackRate = currentSpeed
        audioPlayerView.setupPlaybackSpeed()
        NotificationCenter.default.post(name: Notification.Name("ChangePlaybackSpeed"), object: nil)
    }

    func audioPlayerViewDelegateDidLongPressPlaybackSpeedButton(_ audioPlayerView: AudioPlayerView) {
        present(moreOptionsActionSheet, animated: false) {
            [unowned self] in
            self.moreOptionsActionSheet.addView(.playback)
        }
    }

    func audioPlayerViewDelegateGetBrightnessSlider(_ audioPlayerView: AudioPlayerView) -> BrightnessControlView {
        return brightnessControlView
    }

    func audioPlayerViewDelegateGetVolumeSlider(_ audioPlayerView: AudioPlayerView) -> VolumeControlView {
        return volumeControlView
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension AudioPlayerViewController {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        audioPlayerView.updatePlayButton(isPlaying: playbackService.isPlaying)
        audioPlayerView.updateShuffleRepeatState(shuffleEnabled: playbackService.isShuffleMode, repeatMode: playbackService.repeatMode)

        let metadata = playbackService.metadata
        audioPlayerView.updateLabels(title: metadata.title, artist: metadata.artist, isQueueHidden: isQueueHidden)
        updateNavigationBar(with: isQueueHidden ? nil : metadata.title)

        if let qvc = queueViewController, !isQueueHidden {
            showPlayqueue(from: qvc)
        } else if isQueueHidden {
            var isThumbnailViewHidden: Bool = false
            if playbackService.isPlayingOnExternalScreen() {
                isThumbnailViewHidden = true
            }

            audioPlayerView.thumbnailView.isHidden = isThumbnailViewHidden
        }
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                 isPlaying: Bool,
                                 currentMediaHasTrackToChooseFrom: Bool, currentMediaHasChapters: Bool,
                                 for playbackService: PlaybackService) {
        audioPlayerView.updatePlayButton(isPlaying: isPlaying)

        let image: UIImage? = isPlaying ? UIImage(named: "minimize") : UIImage(named: "close")
        let accessibilityLabel: String = isPlaying ? NSLocalizedString("MINIMIZE_BUTTON", comment: "") : NSLocalizedString("STOP_BUTTON", comment: "")
        let accessibilityHint: String = isPlaying ? NSLocalizedString("MINIMIZE_HINT", comment: "") : NSLocalizedString("CLOSE_HINT", comment: "")
        mediaNavigationBar.updateCloseButton(with: image, accessibility: (accessibilityLabel, accessibilityHint))

        if let queueCollectionView = queueViewController?.queueCollectionView {
            queueCollectionView.reloadData()
        }

        if currentState == .error {
            statusLabel.showStatusMessage(NSLocalizedString("PLAYBACK_FAILED",
                                                            comment: ""))
        }

        if currentState == .buffering {
            mediaDuration = playbackService.mediaDuration
        }

        moreOptionsActionSheet.currentMediaHasChapters = currentMediaHasChapters
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        audioPlayerView.updateLabels(title: metadata.title, artist: metadata.artist, isQueueHidden: isQueueHidden)
        updateNavigationBar(with: isQueueHidden ? nil : metadata.title)

        if metadata.artworkImage != audioPlayerView.thumbnailImageView.image {
            audioPlayerView.updateThumbnailImageView()
            audioPlayerView.setupBackgroundColor()

            if let qvc = queueViewController, !isQueueHidden {
                qvc.reloadBackground(with: audioPlayerView.thumbnailImageView.image)
            }
        }
    }

    func playModeUpdated() {
        audioPlayerView.updateShuffleRepeatState(shuffleEnabled: playbackService.isShuffleMode, repeatMode: playbackService.repeatMode)
    }
}

// MARK: - PlayerControllerDelegate

extension AudioPlayerViewController: PlayerControllerDelegate {
    func playerControllerExternalScreenDidConnect(_ playerController: PlayerController) {
        // TODO
    }

    func playerControllerExternalScreenDidDisconnect(_ playerController: PlayerController) {
        // TODO
    }

    func playerControllerApplicationBecameActive(_ playerController: PlayerController) {
        // TODO
    }

    func playerControllerPlaybackDidStop(_ playerController: PlayerController) {
        delegate?.audioPlayerViewControllerDidMinimize(self)
    }
}

// MARK: - MediaNavigationBarDelegate

extension AudioPlayerViewController {
    override func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar) {
        if playbackService.isPlaying {
            delegate?.audioPlayerViewControllerDidMinimize(self)
        } else {
            playbackService.stopPlayback()
            self.dismiss(animated: true)
            isQueueHidden = true
        }
    }

    func mediaNavigationBarDidToggleQueueView(_ mediaNavigationBar: MediaNavigationBar) {
        let metadata = playbackService.metadata
        audioPlayerView.updateLabels(title: metadata.title, artist: metadata.artist, isQueueHidden: !isQueueHidden)
        updateNavigationBar(with: !isQueueHidden ? nil : metadata.title)

        var isThumbnailViewHidden: Bool = isQueueHidden
        if playbackService.isPlayingOnExternalScreen() {
            isThumbnailViewHidden = true
        }

        audioPlayerView.thumbnailView.isHidden = isThumbnailViewHidden
        audioPlayerView.playqueueView.isHidden = !isQueueHidden

        if let qvc = queueViewController, isQueueHidden {
            showPlayqueue(from: qvc)
        } else if let qvc = queueViewController, !isQueueHidden {
            qvc.dismissFromAudioPlayer()
        }

        shouldDisableGestures(isQueueHidden)

        isQueueHidden = !isQueueHidden
    }

    override func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar) {
        super.mediaNavigationBarDidCloseLongPress(mediaNavigationBar)
        isQueueHidden = true
    }

    func mediaNavigationBarDisplayCloseAlert(_ mediaNavigationBar: MediaNavigationBar) {
        statusLabel.showStatusMessage(NSLocalizedString("CLOSE_HINT", comment: ""))
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension AudioPlayerViewController {
    override func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        setPlayerInterfaceEnabled(!state)
    }

    override func mediaMoreOptionsActionSheetDisplayAddBookmarksView(_ bookmarksView: AddBookmarksView) {
        super.mediaMoreOptionsActionSheetDisplayAddBookmarksView(bookmarksView)

        if let bookmarksView = addBookmarksView {
            view.addSubview(bookmarksView)
            NSLayoutConstraint.activate([
                bookmarksView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                bookmarksView.leadingAnchor.constraint(equalTo: audioPlayerView.layoutGuide.leadingAnchor),
                bookmarksView.trailingAnchor.constraint(equalTo: audioPlayerView.layoutGuide.trailingAnchor),
                bookmarksView.topAnchor.constraint(equalTo: audioPlayerView.layoutGuide.topAnchor, constant: 16),
                bookmarksView.bottomAnchor.constraint(equalTo: audioPlayerView.controlsStackView.topAnchor),
            ])
        }

        audioPlayerView.shouldDisableControls(true)
    }

    override func mediaMoreOptionsActionSheetRemoveAddBookmarksView() {
        super.mediaMoreOptionsActionSheetRemoveAddBookmarksView()

        audioPlayerView.shouldDisableControls(false)
    }

    func mediaMoreOptionsActionSheetShowPlaybackSpeedShortcut(_ displayView: Bool) {
        audioPlayerView.shouldDisplaySecondaryStackView(displayView)
    }
}

// MARK: - PopupViewDelegate

extension AudioPlayerViewController {
    override func popupViewDidClose(_ popupView: PopupView) {
        super.popupViewDidClose(popupView)
        moreOptionsButton.isEnabled = true
    }
}
