/*****************************************************************************
 * AudioPlayerViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
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
        get { return UIInterfaceOrientationMask.portrait }
    }

    lazy var audioPlayerView: AudioPlayerView = {
        let audioPlayerView: AudioPlayerView = Bundle.main.loadNibNamed("AudioPlayerView", owner: nil)?.first as! AudioPlayerView
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

        self.playerController.delegate = self
        mediaNavigationBar.addMoreOptionsButton(moreOptionsButton)
        audioPlayerView.setupNavigationBar(with: mediaNavigationBar)
        audioPlayerView.setupThumbnailView()
        audioPlayerView.setupBackgroundColor()
        audioPlayerView.setupPlayerControls()
        mediaScrubProgressBar.updateBackgroundAlpha(with: 0.0)
        audioPlayerView.setupProgressView(with: mediaScrubProgressBar)
        audioPlayerView.setupExternalOutputView(with: externalOutputView)
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
        seekForwardBy = UserDefaults.standard.integer(forKey: kVLCSettingPlaybackForwardSkipLength)
        seekBackwardBy = UserDefaults.standard.integer(forKey: kVLCSettingPlaybackBackwardSkipLength)
        audioPlayerView.setupThumbnailView()
        audioPlayerView.setupBackgroundColor()
        setupGestures()

        if playbackService.isPlayingOnExternalScreen() {
            changeOutputView(to: externalOutputView.displayView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        playerController.isInterfaceLocked = false
    }

    // MARK: Public methods

    override func minimizePlayer() {
        delegate?.audioPlayerViewControllerDidMinimize(self)
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
            optionsNavigationBar.trailingAnchor.constraint(equalTo: audioPlayerView.trailingAnchor, constant: -padding)
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

    private func getCurrentMediaTitle() -> String? {
        if let audiotrack = VLCMLMedia.init(forPlaying: playbackService.currentlyPlayingMedia) {
            return audiotrack.title
        } else {
            return playbackService.metadata.title
        }
    }

    private func getCurrentMediaArtist() -> String? {
        if let audiotrack = VLCMLMedia.init(forPlaying: playbackService.currentlyPlayingMedia) {
            return audiotrack.albumTrackArtistName()
        } else {
            return nil
        }
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

    func audioPlayerViewDelegateDidTapBackwardButton(_ audioPlayerView: AudioPlayerView) {
        playbackService.jumpBackward(Int32(seekBackwardBy))
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

    func audioPlayerViewDelegateDidTapForwardButton(_ audioPlayerView: AudioPlayerView) {
        playbackService.jumpForward(Int32(seekForwardBy))
    }

    func audioPlayerViewDelegateGetBrightnessSlider(_ audioPlayerView: AudioPlayerView) -> BrightnessControlView {
        return brightnessControlView
    }

    func audioPlayerViewDeleagteGetVolumeSlider(_ audioPlayerView: AudioPlayerView) -> VolumeControlView {
        return volumeControlView
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension AudioPlayerViewController {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        audioPlayerView.updatePlayButton(isPlaying: playbackService.isPlaying)

        let title = getCurrentMediaTitle()
        let artist = getCurrentMediaArtist()
        audioPlayerView.updateLabels(title: title, artist: artist, isQueueHidden: isQueueHidden)
        updateNavigationBar(with: isQueueHidden ? nil : playbackService.metadata.title)

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
        mediaNavigationBar.updateCloseButton(with: image)

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
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        let title = getCurrentMediaTitle()
        let artist = getCurrentMediaArtist()
        audioPlayerView.updateLabels(title: title, artist: artist, isQueueHidden: isQueueHidden)
        updateNavigationBar(with: isQueueHidden ? nil : metadata.title)

        audioPlayerView.setupThumbnailView()
        audioPlayerView.setupBackgroundColor()

        if let qvc = queueViewController, !isQueueHidden {
            qvc.reloadBackground(with: audioPlayerView.thumbnailImageView.image)
        }
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
        let title = getCurrentMediaTitle()
        let artist = getCurrentMediaArtist()
        audioPlayerView.updateLabels(title: title, artist: artist, isQueueHidden: !isQueueHidden)
        updateNavigationBar(with: !isQueueHidden ? nil : playbackService.metadata.title)

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
                bookmarksView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bookmarksView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bookmarksView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
                bookmarksView.bottomAnchor.constraint(lessThanOrEqualTo: audioPlayerView.controlsStackView.topAnchor),
            ])
        }
    }
}

// MARK: - PopupViewDelegate

extension AudioPlayerViewController {
    override func popupViewDidClose(_ popupView: PopupView) {
        super.popupViewDidClose(popupView)
        moreOptionsButton.isEnabled = true
    }
}
