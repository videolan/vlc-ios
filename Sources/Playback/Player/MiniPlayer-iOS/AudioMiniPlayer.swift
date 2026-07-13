/*****************************************************************************
 * AudioMiniPlayer.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

#if os(iOS)
import Foundation
import WidgetKit
#endif

enum MiniPlayerVerticalPosition {
    case bottom
    case top
}

enum MiniPlayerHorizontalPosition {
    case left
    case right
    case center
}

struct MiniPlayerPosition {
    var vertical: MiniPlayerVerticalPosition
    var horizontal: MiniPlayerHorizontalPosition
}

@objc enum PanDirection: Int {
    case vertical
    case horizontal
}

@objc(VLCAudioMiniPlayer)
class AudioMiniPlayer: UIView, MiniPlayer, QueueViewControllerDelegate {
    @objc static let height: Float = 72.0
    private static let extraControlsMinWidth: CGFloat = 500.0
    var visible: Bool = false
    var contentHeight: Float {
        return AudioMiniPlayer.height
    }

    private let audioMiniPlayer = UIView()
    private let infoContainer = UIView()
    private let artworkImageView = UIImageView()
    private var artworkBlurImageView: UIImageView?
    private var artworkBlurView: UIVisualEffectView?
    private let titleLabel = VLCMarqueeLabel(frame: .zero, rate: 30, fadeLength: 20)
    private let artistLabel = VLCMarqueeLabel(frame: .zero, rate: 30, fadeLength: 20)
    private let progressBarView = UIProgressView(progressViewStyle: .bar)
    private let playPauseButton = UIButton(type: .custom)
    private let previousButton = UIButton(type: .custom)
    private let nextButton = UIButton(type: .custom)
    private let repeatButton = UIButton(type: .custom)
    private let shuffleButton = UIButton(type: .custom)
    private let controlStack = UIStackView()
    private let previousNextOverlay = UIView()
    private let previousNextImage = UIImageView()

    private let draggingDelegate: MiniPlayerDraggingDelegate

    private let animationDuration = 0.2

    private lazy var playbackService = PlaybackService.sharedInstance()

    private var queueViewController: QueueViewController?

    var position = MiniPlayerPosition(vertical: .bottom, horizontal: .center)
    var originY: CGFloat = 0.0
    var tapticPosition = MiniPlayerPosition(vertical: .bottom, horizontal: .center)
    var panDirection: PanDirection = .vertical

    var stopGestureEnabled: Bool {
        if #available(iOS 13.0, *) {
            return false
        } else {
            return true
        }
    }

    @objc init(draggingDelegate: MiniPlayerDraggingDelegate) {
        self.draggingDelegate = draggingDelegate
        super.init(frame: .zero)
        initView()
        setupConstraint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let hasRoomForExtraControls = bounds.width >= AudioMiniPlayer.extraControlsMinWidth
        if repeatButton.isHidden == hasRoomForExtraControls {
            repeatButton.isHidden = !hasRoomForExtraControls
        }
        if shuffleButton.isHidden == hasRoomForExtraControls {
            shuffleButton.isHidden = !hasRoomForExtraControls
        }
    }

    func updatePlayPauseButton() {
        playPauseButton.isSelected = playbackService.isPlaying
    }

    func updateRepeatButton() {
        switch playbackService.repeatMode {
        case .doNotRepeat:
            repeatButton.setImage(UIImage(named: "iconRepeatLarge"), for: .normal)
            repeatButton.tintColor = inactiveControlTintColor
        case .repeatCurrentItem:
            repeatButton.setImage(UIImage(named: "iconRepeatOneOnLarge"), for: .normal)
            repeatButton.tintColor = PresentationTheme.current.colors.orangeUI
        case .repeatAllItems:
            repeatButton.setImage(UIImage(named: "iconRepeatOnLarge"), for: .normal)
            repeatButton.tintColor = PresentationTheme.current.colors.orangeUI
        @unknown default:
            assertionFailure("AudioMiniPlayer.updateRepeatButton: unhandled case.")
        }
    }

    func updateShuffleButton() {
        let colors = PresentationTheme.current.colors
        let isShuffleMode = playbackService.isShuffleMode
        let image = isShuffleMode ? UIImage(named: "iconShuffleOnLarge") : UIImage(named: "iconShuffleLarge")

        shuffleButton.setImage(image, for: .normal)
        shuffleButton.tintColor = isShuffleMode ? colors.orangeUI : inactiveControlTintColor
    }

    private var inactiveControlTintColor: UIColor {
        if #available(iOS 26.0, *) {
            return .label
        }
        return .white
    }

    @objc func setupQueueViewController(with view: QueueViewController) {
        queueViewController = view
        queueViewController?.delegate = self
    }
}

// MARK: - Private initializers

private extension AudioMiniPlayer {
    private func initView() {
        let modern: Bool
        if #available(iOS 26.0, *) {
            modern = true
        } else {
            modern = false
        }

        audioMiniPlayer.translatesAutoresizingMaskIntoConstraints = false
        audioMiniPlayer.clipsToBounds = true
        addSubview(audioMiniPlayer)
        isUserInteractionEnabled = true

        setupBackground(modern: modern)
        setupControls(modern: modern)
        setupInfo(modern: modern)
        setupProgressBar(modern: modern)
        setupPreviousNextOverlay()
        setupGestures()

        updatePlayPauseButton()
        updateRepeatButton()
        updateShuffleButton()

        if #available(iOS 13.0, *) {
            addContextMenu()
        }
    }

    private func setupBackground(modern: Bool) {
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            audioMiniPlayer.backgroundColor = .clear
            audioMiniPlayer.clipsToBounds = false

            let corners = UICornerConfiguration.capsule()
            audioMiniPlayer.cornerConfiguration = corners

            let glassEffect = UIGlassEffect()
            glassEffect.isInteractive = true
            let glassView = UIVisualEffectView(effect: glassEffect)
            glassView.cornerConfiguration = corners
            glassView.translatesAutoresizingMaskIntoConstraints = false
            audioMiniPlayer.addSubview(glassView)
            pin(glassView, filling: audioMiniPlayer)
            return
        }
#endif
        audioMiniPlayer.backgroundColor = UIColor(red: 0.133, green: 0.157, blue: 0.173, alpha: 1)
        audioMiniPlayer.layer.cornerRadius = 4
        audioMiniPlayer.layer.borderWidth = 0.5
        audioMiniPlayer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        let blurImageView = UIImageView()
        blurImageView.translatesAutoresizingMaskIntoConstraints = false
        blurImageView.clipsToBounds = true
        blurImageView.accessibilityIgnoresInvertColors = true
        audioMiniPlayer.addSubview(blurImageView)

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isHidden = true
        audioMiniPlayer.addSubview(blurView)

        pin(blurImageView, filling: audioMiniPlayer)
        pin(blurView, filling: audioMiniPlayer)

        artworkBlurImageView = blurImageView
        artworkBlurView = blurView
    }

    private func setupControls(modern: Bool) {
        let buttons = [repeatButton, previousButton, playPauseButton, nextButton, shuffleButton]
        buttons.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
        }

        playPauseButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        nextButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON", comment: "")
        previousButton.accessibilityLabel = NSLocalizedString("PREV_BUTTON", comment: "")

        repeatButton.addTarget(self, action: #selector(handelRepeat(_:)), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(handlePrevious(_:)), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(handlePlayPause(_:)), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(handleNext(_:)), for: .touchUpInside)
        shuffleButton.addTarget(self, action: #selector(handleShuffle(_:)), for: .touchUpInside)

        if #available(iOS 26.0, *) {
            playPauseButton.setImage(UIImage(named: "MiniPlay")?.withRenderingMode(.alwaysTemplate), for: .normal)
            playPauseButton.setImage(UIImage(named: "MiniPause")?.withRenderingMode(.alwaysTemplate), for: .selected)
            previousButton.setImage(UIImage(named: "MiniPrev")?.withRenderingMode(.alwaysTemplate), for: .normal)
            nextButton.setImage(UIImage(named: "MiniNext")?.withRenderingMode(.alwaysTemplate), for: .normal)
            [previousButton, playPauseButton, nextButton].forEach { $0.tintColor = .label }
        } else {
            playPauseButton.setImage(UIImage(named: "MiniPlay"), for: .normal)
            playPauseButton.setImage(UIImage(named: "MiniPause"), for: .selected)
            previousButton.setImage(UIImage(named: "MiniPrev"), for: .normal)
            nextButton.setImage(UIImage(named: "MiniNext"), for: .normal)
        }

        controlStack.axis = .horizontal
        controlStack.alignment = .fill
        controlStack.distribution = .fill
        controlStack.semanticContentAttribute = .forceLeftToRight
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        controlStack.setContentHuggingPriority(.required, for: .horizontal)
        controlStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        buttons.forEach { controlStack.addArrangedSubview($0) }

        audioMiniPlayer.addSubview(controlStack)
        NSLayoutConstraint.activate([
            audioMiniPlayer.heightAnchor.constraint(equalToConstant: 56),
            controlStack.trailingAnchor.constraint(equalTo: audioMiniPlayer.trailingAnchor,
                                                   constant: modern ? -8 : 0),
            controlStack.topAnchor.constraint(equalTo: audioMiniPlayer.topAnchor),
            controlStack.bottomAnchor.constraint(equalTo: audioMiniPlayer.bottomAnchor),
        ])
    }

    private func setupInfo(modern: Bool) {
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.clipsToBounds = true
        artworkImageView.accessibilityIgnoresInvertColors = true
        artworkImageView.layer.cornerRadius = modern ? 8 : 2

        titleLabel.font = .systemFont(ofSize: 14)
        artistLabel.font = .systemFont(ofSize: 12)
        if #available(iOS 26.0, *) {
            titleLabel.textColor = .label
            artistLabel.textColor = .secondaryLabel
        } else {
            titleLabel.textColor = .white
            artistLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        }
        [titleLabel, artistLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        let labelStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.alignment = .fill
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        infoContainer.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(artworkImageView)
        infoContainer.addSubview(labelStack)
        audioMiniPlayer.addSubview(infoContainer)

        let artInset: CGFloat = modern ? 8 : 0
        NSLayoutConstraint.activate([
            infoContainer.leadingAnchor.constraint(equalTo: audioMiniPlayer.leadingAnchor),
            infoContainer.topAnchor.constraint(equalTo: audioMiniPlayer.topAnchor),
            infoContainer.bottomAnchor.constraint(equalTo: audioMiniPlayer.bottomAnchor),
            infoContainer.trailingAnchor.constraint(equalTo: controlStack.leadingAnchor),

            artworkImageView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor,
                                                      constant: modern ? 12 : 0),
            artworkImageView.centerYAnchor.constraint(equalTo: infoContainer.centerYAnchor),
            artworkImageView.heightAnchor.constraint(equalToConstant: 56 - 2 * artInset),
            artworkImageView.widthAnchor.constraint(equalTo: artworkImageView.heightAnchor),

            labelStack.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            labelStack.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor,
                                                 constant: modern ? -8 : 0),
            labelStack.centerYAnchor.constraint(equalTo: infoContainer.centerYAnchor),
        ])
    }

    private func setupProgressBar(modern: Bool) {
        progressBarView.translatesAutoresizingMaskIntoConstraints = false
        progressBarView.clipsToBounds = true
        progressBarView.progressTintColor = PresentationTheme.current.colors.orangeUI
        if modern {
            progressBarView.trackTintColor = .clear
        } else {
            progressBarView.backgroundColor = UIColor(red: 0.146, green: 0.161, blue: 0.173, alpha: 1)
        }

        audioMiniPlayer.addSubview(progressBarView)
        let inset: CGFloat = modern ? 28 : 0
        let bottomInset: CGFloat = modern ? -5 : 0
        NSLayoutConstraint.activate([
            progressBarView.leadingAnchor.constraint(equalTo: audioMiniPlayer.leadingAnchor, constant: inset),
            progressBarView.trailingAnchor.constraint(equalTo: audioMiniPlayer.trailingAnchor, constant: -inset),
            progressBarView.bottomAnchor.constraint(equalTo: audioMiniPlayer.bottomAnchor, constant: bottomInset),
            progressBarView.heightAnchor.constraint(equalToConstant: 2),
        ])
    }

    private func setupPreviousNextOverlay() {
        previousNextOverlay.translatesAutoresizingMaskIntoConstraints = false
        previousNextOverlay.backgroundColor = .black
        previousNextOverlay.isHidden = true

        previousNextImage.translatesAutoresizingMaskIntoConstraints = false
        previousNextImage.clipsToBounds = true
        previousNextImage.contentMode = .scaleAspectFill
        previousNextOverlay.addSubview(previousNextImage)
        audioMiniPlayer.addSubview(previousNextOverlay)

        pin(previousNextOverlay, filling: audioMiniPlayer)
        NSLayoutConstraint.activate([
            previousNextImage.centerXAnchor.constraint(equalTo: previousNextOverlay.centerXAnchor),
            previousNextImage.topAnchor.constraint(equalTo: previousNextOverlay.topAnchor, constant: 3.5),
            previousNextImage.bottomAnchor.constraint(equalTo: previousNextOverlay.bottomAnchor, constant: -3.5),
            previousNextImage.widthAnchor.constraint(equalTo: previousNextImage.heightAnchor),
        ])
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didDrag(_:)))
        pan.minimumNumberOfTouches = 1
        audioMiniPlayer.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFullScreen(_:)))
        infoContainer.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressPlayPause(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.allowableMovement = 10
        playPauseButton.addGestureRecognizer(longPress)
    }

    private func setupConstraint() {
        NSLayoutConstraint.activate([
            audioMiniPlayer.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            audioMiniPlayer.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8),
            audioMiniPlayer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    private func pin(_ view: UIView, filling container: UIView) {
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    private func applyCustomEqualizerProfileIfNeeded() {
        let userDefaults = UserDefaults.standard
        guard userDefaults.bool(forKey: kVLCCustomProfileEnabled) else {
            return
        }

        let profileIndex = userDefaults.integer(forKey: kVLCSettingEqualizerProfile)
        let encodedData = userDefaults.data(forKey: kVLCCustomEqualizerProfiles)

        guard let encodedData = encodedData,
              let customProfiles = CustomEqualizerProfiles.unarchive(from: encodedData),
              profileIndex < customProfiles.profiles.count else {
            return
        }

        let selectedProfile = customProfiles.profiles[profileIndex]
        playbackService.preAmplification = CGFloat(selectedProfile.preAmpLevel)

        for (index, frequency) in selectedProfile.frequencies.enumerated() {
            playbackService.setAmplification(CGFloat(frequency), forBand: UInt32(index))
        }
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension AudioMiniPlayer: VLCPlaybackServiceDelegate {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        updatePlayPauseButton()
        updateRepeatButton()
        updateShuffleButton()
        playbackService.delegate = self
        playbackService.recoverDisplayedMetadata()
        // For now, AudioMiniPlayer will be used for all media
        if !playbackService.isPlayingOnExternalScreen() && !playbackService.playAsAudio {
            playbackService.videoOutputView = artworkImageView
        }
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                 isPlaying: Bool,
                                 currentMediaHasTrackToChooseFrom: Bool,
                                 currentMediaHasChapters: Bool,
                                 for playbackService: PlaybackService) {
        updatePlayPauseButton()
        updateRepeatButton()
        updateShuffleButton()
        if let queueCollectionView = queueViewController?.queueCollectionView {
            queueCollectionView.reloadData()
        }

        if currentState == .opening {
            applyCustomEqualizerProfileIfNeeded()
        }
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        setMediaInfo(metadata)
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        progressBarView.progress = playbackService.playbackPosition
    }

    func reloadPlayQueue() {
        guard let queueViewController = queueViewController else {
            return
        }

        queueViewController.reload()
    }

#if os(iOS)
    func updateWidgetsIfNeeded() {
        guard #available(iOS 14.0, *) else {
            return
        }

        let widgetCenter = WidgetCenter.shared
        widgetCenter.getCurrentConfigurations({ result in
            switch result {
            case let .success(widgetInfo):
                if !widgetInfo.isEmpty {
                    widgetCenter.reloadAllTimelines()
                }
            case let .failure(error):
                assertionFailure("AudioMiniPlayer: \(error)")
            }
        })
    }
#endif
}

// MARK: - UI Receivers

private extension AudioMiniPlayer {
    @objc private func handlePrevious(_ sender: UIButton) {
        playbackService.previous()
    }

    @objc private func handlePlayPause(_ sender: UIButton) {
        playbackService.playPause()
        updatePlayPauseButton()
    }

    @objc private func handleNext(_ sender: UIButton) {
        playbackService.next()
    }

    @objc private func handelRepeat(_ sender: UIButton) {
        playbackService.toggleRepeatMode()
        updateRepeatButton()
    }

    @objc private func handleShuffle(_ sender: UIButton? = nil) {
        playbackService.isShuffleMode = !playbackService.isShuffleMode
        updateShuffleButton()
    }

    @objc private func handleFullScreen(_ sender: Any) {
        if position.vertical == .top {
            dismissPlayqueue(with: nil)
        }

        let currentMedia: VLCMedia? = playbackService.currentlyPlayingMedia
        let mlMedia: VLCMLMedia? = VLCMLMedia.init(forPlaying: currentMedia)
        let isStream: Bool = mlMedia == nil || mlMedia?.isExternalMedia() == true
        let isAudioMedia: Bool = (mlMedia?.type() == .audio || isStream) && playbackService.numberOfVideoTracks == 0

        let selector: Selector
        if isAudioMedia || playbackService.playAsAudio {
            selector = #selector(VLCPlayerDisplayController.showAudioPlayer)
        } else {
            selector = #selector(VLCPlayerDisplayController.showFullscreenPlayback)
        }

        UIApplication.shared.sendAction(selector,
                                        to: nil,
                                        from: self,
                                        for: nil)
    }

    @objc private func handleLongPressPlayPause(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
            // case .began:
            // In the case of .began we could a an icon like the old miniplayer
        case .ended:
            playbackService.stopPlayback()
        case .cancelled, .failed:
            playbackService.playPause()
            updatePlayPauseButton()
        default:
            break
        }
    }
}

// MARK: - Playqueue UI

extension AudioMiniPlayer {

    // MARK: Drag gesture handlers
    @objc func didDrag(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            dragDidBegin(sender)
        case .changed:
            dragStateDidChange(sender)
        case .ended:
            dragDidEnd(sender)
        default:
            break
        }
    }

    private func dragDidBegin(_ sender: UIPanGestureRecognizer) {
        getPanDirection(sender)
        switch panDirection {
        case .vertical:
            queueViewController?.show()
        case .horizontal:
            break
        }
        originY = frame.minY
    }

    private func dragStateDidChange(_ sender: UIPanGestureRecognizer) {
        draggingDelegate.miniPlayerDragStateDidChange(self, sender: sender, panDirection: panDirection)
        sender.setTranslation(CGPoint.zero, in: UIApplication.shared.delegate?.window??.rootViewController!.view)
        handleHapticFeedback()
        draggingDelegate.miniPlayerNeedsLayout(self)
    }

    private func dragDidEnd(_ sender: UIPanGestureRecognizer) {

        let velocity = sender.velocity(in: UIApplication.shared.delegate?.window??.rootViewController!.view)
        if let superview = superview {
            switch panDirection {
            case .vertical:
                let limit = topBottomLimit(for: superview, with: position.vertical)
                switch position.vertical {
                case .top:
                    if self.frame.minY > limit || velocity.y > 1000.0 {
                        let completion: ((Bool) -> Void) = { _ in
                            self.queueViewController?.hide()
                        }
                        dismissPlayqueue(with: completion)
                    } else {
                        showPlayqueue(in: superview)
                    }
                case .bottom:
                    if stopGestureEnabled && self.frame.minY > originY + 10 {
                        playbackService.stopPlayback()
                    } else if self.frame.minY > limit && velocity.y > -1000.0 {
                        let completion: ((Bool) -> Void) = { _ in
                            self.queueViewController?.hide()
                        }
                        dismissPlayqueue(with: completion)
                    } else {
                        showPlayqueue(in: superview)
                    }
                }
            case .horizontal:
                switch position.horizontal {
                case .right:
                    playbackService.previous()
                case .left:
                    playbackService.next()
                case .center:
                    break
                }
                draggingDelegate.miniPlayerCenterHorizontaly(self)
                position.horizontal = .center
            }
            hidePreviousNextOverlay()
            draggingDelegate.miniPlayerDragDidEnd(self, sender: sender, panDirection: panDirection)
            UIView.animate(withDuration: animationDuration, animations: {
                self.draggingDelegate.miniPlayerNeedsLayout(self)
            })
        }
    }

    // MARK: Drag helpers

    private func topBottomLimit(for superview: UIView, with position: MiniPlayerVerticalPosition) -> CGFloat {
        switch position {
        case .top:
            return superview.frame.maxY / 3
        case .bottom:
            return 2 * superview.frame.maxY / 3
        }
    }

    private func getPanDirection(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: UIApplication.shared.delegate?.window??.rootViewController!.view)
        panDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
    }

    private func verticalTranslation(in superview: UIView) -> Bool {
        var hapticFeedbackNeeded = false
        let limit = topBottomLimit(for: superview, with: position.vertical)
        if frame.minY < limit && tapticPosition.vertical == .bottom {
            hapticFeedbackNeeded = true
            queueViewController?.show()
            queueViewController?.view.alpha = 1.0
            tapticPosition.vertical = .top
        } else if frame.minY > limit && tapticPosition.vertical == .top {
            hapticFeedbackNeeded = true
            queueViewController?.view.alpha = 0.5
            tapticPosition.vertical = .bottom
        }
        if position.vertical == .bottom {
            if stopGestureEnabled && frame.minY > originY + 10 {
                previousNextImage.image = UIImage(named: "stopIcon")
                previousNextOverlay.alpha = 0.8
                previousNextOverlay.isHidden = false
            } else if frame.minY > originY {
                queueViewController?.hide()
            } else {
                hidePreviousNextOverlay()
            }
        }
        return hapticFeedbackNeeded
    }

    private func horizontalTranslation(in superview: UIView) -> Bool {
        var hapticFeedbackNeeded = false
        switch position.horizontal {
        case .center:
            if center.x < superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                position.horizontal = .left
            } else if center.x > 2 * superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                position.horizontal = .right
            }
        case .left:
            if center.x > superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                position.horizontal = .center
                hidePreviousNextOverlay()
            } else {
                previousNextImage.image = UIImage(named: "MiniNext")
                previousNextOverlay.alpha = abs(superview.center.x - center.x) / (superview.frame.width / 2)
                previousNextOverlay.isHidden = false
            }
        case .right:
            if center.x < 2 * superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                position.horizontal = .center
                hidePreviousNextOverlay()
            } else {
                previousNextImage.image = UIImage(named: "MiniPrev")
                previousNextOverlay.alpha = abs(superview.center.x - center.x) / (superview.frame.width / 2)
                previousNextOverlay.isHidden = false
            }
        }
        return hapticFeedbackNeeded
    }

    private func handleHapticFeedback() {
        var hapticFeedbackNeeded = false
        if let superview = superview {
            switch panDirection {
            case .vertical:
                hapticFeedbackNeeded = verticalTranslation(in: superview)
            case .horizontal:
                hapticFeedbackNeeded = horizontalTranslation(in: superview)
            }
        }
#if os(iOS)
        if hapticFeedbackNeeded {
            ImpactFeedbackGenerator().limitOverstepped()
        }
#endif
    }

    // MARK: Show hide playqueue

    func showPlayqueue(in superview: UIView) {
        if let queueView = queueViewController?.view {
            position.vertical = .top
            tapticPosition.vertical = .top
            queueView.setNeedsUpdateConstraints()
            draggingDelegate.miniPlayerPositionToTop(self)
        }
    }

    func dismissPlayqueue(with completion: ((Bool) -> Void)?) {
        position.vertical = .bottom
        tapticPosition.vertical = .bottom

        draggingDelegate.miniPlayerPositionToBottom(self, completion: completion)
    }

    func hidePreviousNextOverlay() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.previousNextOverlay.alpha = 0.0
            self.previousNextOverlay.isHidden = true
        })
    }
}

// MARK: - Setters

private extension AudioMiniPlayer {
    private func setMediaInfo(_ metadata: VLCMetaData) {
        if metadata.descriptiveTitle != nil {
            titleLabel.text = metadata.descriptiveTitle
        } else {
            titleLabel.text = metadata.title
        }
        artistLabel.text = metadata.artist
        artistLabel.isHidden = artistLabel.text?.isEmpty ?? true
        if (!UIAccessibility.isReduceTransparencyEnabled && metadata.isAudioOnly) ||
            playbackService.playAsAudio {
            // Only update the artwork image when the media is being played
            if playbackService.isPlaying {
                let placeholder = PresentationTheme.current.isDark ? UIImage(named: "song-placeholder-dark")
                                                                   : UIImage(named: "song-placeholder-white")
                artworkImageView.image = metadata.artworkImage ?? placeholder
                artworkBlurImageView?.image = metadata.artworkImage
                artworkBlurView?.isHidden = false
            }

            playbackService.videoOutputView = nil
        } else {
            artworkImageView.image = nil
            artworkBlurImageView?.image = nil
            artworkBlurView?.isHidden = true
            playbackService.videoOutputView = artworkImageView
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension AudioMiniPlayer: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: generateContextMenu)
    }

    private func generateContextMenu(_ suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions: [UIMenuElement] = []
        let defaultButtonColor: UIColor = PresentationTheme.current.colors.cellTextColor

        do {
            let shuffleState: UIMenuElement.State = playbackService.isShuffleMode ? .on : .off
            let shuffleIconTint: UIColor = playbackService.isShuffleMode ? PresentationTheme.current.colors.orangeUI : defaultButtonColor
            let shuffleIcon = shuffleButton.image(for: .normal)?.withTintColor(shuffleIconTint, renderingMode: .alwaysOriginal)
            actions.append(
                UIAction(title: shuffleButton.currentTitle ?? NSLocalizedString("SHUFFLE", comment: ""),
                         image: shuffleIcon, state: shuffleState) {
                             action in
                             self.handleShuffle()
                         }
            )
        }

        do {
            let repeatMode = playbackService.repeatMode
            var repeatActions: [UIMenuElement] = []

            let noRepeatState: UIMenuElement.State = repeatMode == .doNotRepeat ? .on : .off
            let noRepeatIconTint = repeatMode == .doNotRepeat ? PresentationTheme.current.colors.orangeUI : defaultButtonColor
            let noRepeatIcon = UIImage(named: "iconNoRepeat")?.withTintColor(noRepeatIconTint, renderingMode: .alwaysOriginal)
            repeatActions.append(
                UIAction(title: NSLocalizedString("MENU_REPEAT_DISABLED", comment: ""), image: noRepeatIcon, state: noRepeatState) {
                    action in
                    self.playbackService.repeatMode = .doNotRepeat
                    self.updateRepeatButton()
                }
            )

            let repeatOneState: UIMenuElement.State = repeatMode == .repeatCurrentItem ? .on : .off
            let repeatOneIconTint = repeatMode == .repeatCurrentItem ? PresentationTheme.current.colors.orangeUI : defaultButtonColor
            let repeatOneIcon = UIImage(named: "iconRepeatOne")?.withTintColor(repeatOneIconTint, renderingMode: .alwaysOriginal)
            repeatActions.append(
                UIAction(title: NSLocalizedString("MENU_REPEAT_SINGLE", comment: ""), image: repeatOneIcon, state: repeatOneState) {
                    action in
                    self.playbackService.repeatMode = .repeatCurrentItem
                    self.updateRepeatButton()
                }
            )

            let repeatAllState: UIMenuElement.State = repeatMode == .repeatAllItems ? .on : .off
            let repeatAllIconTint = repeatMode == .repeatAllItems ? PresentationTheme.current.colors.orangeUI : defaultButtonColor
            let repeatAllIcon = UIImage(named: "iconRepeat")?.withTintColor(repeatAllIconTint, renderingMode: .alwaysOriginal)
            repeatActions.append(
                UIAction(title: NSLocalizedString("MENU_REPEAT_ALL", comment: ""), image: repeatAllIcon, state: repeatAllState) {
                    action in
                    self.playbackService.repeatMode = .repeatAllItems
                    self.updateRepeatButton()
                }
            )

            actions.append(UIMenu(title: "", options: .displayInline, children: repeatActions))
        }

        actions.append(
            UIAction(title: NSLocalizedString("STOP_BUTTON", comment: ""),
                     image: UIImage(named: "stopIcon")?.withTintColor(defaultButtonColor, renderingMode: .alwaysOriginal)) {
                         action in
                         self.playbackService.stopPlayback()
                         let completion: ((Bool) -> Void) = { _ in
                             self.queueViewController?.hide()
                         }
                         self.dismissPlayqueue(with: completion)
                     }
        )

        return UIMenu(title: NSLocalizedString("MENU_PLAYBACK_CONTROLS", comment: ""), children: actions)
    }

    private func addContextMenu() {
        audioMiniPlayer.addInteraction(UIContextMenuInteraction(delegate: self))
    }
}

@objc protocol MiniPlayerDraggingDelegate {
    func miniPlayerDragStateDidChange(_ miniPlayer: AudioMiniPlayer, sender: UIPanGestureRecognizer, panDirection: PanDirection)
    func miniPlayerDragDidEnd(_ miniPlayer: AudioMiniPlayer, sender: UIPanGestureRecognizer, panDirection: PanDirection)
    func miniPlayerPositionToTop(_ miniPlayer: AudioMiniPlayer)
    func miniPlayerPositionToBottom(_ miniPlayer: AudioMiniPlayer, completion: ((Bool) -> Void)?)
    func miniPlayerCenterHorizontaly(_ miniPlayer: AudioMiniPlayer)
    func miniPlayerNeedsLayout(_ miniPlayer: AudioMiniPlayer)
}
