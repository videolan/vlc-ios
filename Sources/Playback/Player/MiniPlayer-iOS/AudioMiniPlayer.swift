/*****************************************************************************
 * AudioMiniPlayer.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Neo Salmon <neos_dev@outlook.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

#if os(iOS)
import Foundation
import WidgetKit
#endif

enum MiniPlayerHorizontalPosition {
    case left
    case right
    case center
}

enum PanDirection: Int {
    case vertical
    case horizontal
}

@objc(VLCAudioMiniPlayer)
class AudioMiniPlayer: UIView {
    private static let extraControlsMinWidth: CGFloat = 500.0
    var contentHeight: Float {
        return 56
    }

    public static let largeScreenWidthFactor: CGFloat = 2/3
    // UITabAccessory incorrectly sizes the miniplayer if there is no instrinsic
    // content size or it is set too low for the screen.
    override var intrinsicContentSize: CGSize {
        return CGSize(width: intrinsicWidth, height: CGFloat(contentHeight))
    }

    private var intrinsicWidth: CGFloat {
        #if os(visionOS)
        return 750
        #else
        guard let window else { return UIView.noIntrinsicMetric }
        let width = window.bounds.width
        return traitCollection.horizontalSizeClass == .regular ? width * Self.largeScreenWidthFactor : width
        #endif
    }

    private var appliedIntrinsicWidth: CGFloat = UIView.noIntrinsicMetric

    private let audioMiniPlayer = UIView()
    private let infoContainer = UIView()
    private let artworkImageView = VLCArtworkImageView()
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
    private var previousNextOverlay = UIView()
    private let previousNextImage = UIImageView()

    private let animationDuration = 0.2

    private lazy var playbackService = PlaybackService.sharedInstance()

    var horizontalPosition = MiniPlayerHorizontalPosition.center
    var panDirection: PanDirection = .vertical
    private var topGestureWasPerformed: Bool = false

    private var internalTopAnchorConstraint: NSLayoutConstraint!
    private var internalBottomAnchorConstraint: NSLayoutConstraint!
    private var internalLeadingAnchorConstraint: NSLayoutConstraint!
    private var internalTrailingAnchorConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        initView()
        setupConstraint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var miniPlayerIsMinimized: Bool = false
        #if os(iOS)
        if #available(iOS 26, *) {
            miniPlayerIsMinimized = traitCollection.tabAccessoryEnvironment == .inline
        }
        #endif
        let hasRoomForControls = bounds.width >= AudioMiniPlayer.extraControlsMinWidth
        let hasRoomForExtraControls = hasRoomForControls && !miniPlayerIsMinimized
        if repeatButton.isHidden == hasRoomForExtraControls {
            repeatButton.isHidden = !hasRoomForExtraControls
        }
        if shuffleButton.isHidden == hasRoomForExtraControls {
            shuffleButton.isHidden = !hasRoomForExtraControls
        }
        let hasRoomForSkipControls = hasRoomForControls || !miniPlayerIsMinimized
        if previousButton.isHidden == hasRoomForSkipControls {
            previousButton.isHidden = !hasRoomForSkipControls
        }
        if nextButton.isHidden == hasRoomForSkipControls {
            nextButton.isHidden = !hasRoomForSkipControls
        }
        let width = intrinsicWidth
        if width != appliedIntrinsicWidth {
            appliedIntrinsicWidth = width
            invalidateIntrinsicContentSize()
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
        clipsToBounds = true
        isUserInteractionEnabled = true

        setupBackground(modern: modern)
        addSubview(audioMiniPlayer)
        setupControls(modern: modern)
        setupInfo(modern: modern)
        setupProgressBar(modern: modern)
        setupPreviousNextOverlay()
        setupGestures()

        updatePlayPauseButton()
        updateRepeatButton()
        updateShuffleButton()

        addContextMenu()
    }

    private func setupBackground(modern: Bool) {
        if #available(iOS 26.0, *) {
            return
        }
        self.backgroundColor = UIColor(red: 0.133, green: 0.157, blue: 0.173, alpha: 1)
        self.layer.cornerRadius = 4
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        let blurImageView = UIImageView()
        blurImageView.translatesAutoresizingMaskIntoConstraints = false
        blurImageView.clipsToBounds = true
        blurImageView.accessibilityIgnoresInvertColors = true
        self.addSubview(blurImageView)

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isHidden = true
        self.addSubview(blurView)

        pin(blurImageView, filling: self)
        pin(blurView, filling: self)

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
            controlStack.trailingAnchor.constraint(equalTo: audioMiniPlayer.trailingAnchor,
                                                   constant: modern ? -8 : 0),
            controlStack.topAnchor.constraint(equalTo: audioMiniPlayer.topAnchor),
            controlStack.bottomAnchor.constraint(equalTo: audioMiniPlayer.bottomAnchor),
        ])
    }

    private func setupInfo(modern: Bool) {
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.clipsToBounds = true
        artworkImageView.contentMode = .scaleAspectFit
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
            infoContainer.leadingAnchor.constraint(equalTo: audioMiniPlayer.leadingAnchor, constant: artInset),
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

        self.addSubview(progressBarView)
        let inset: CGFloat = modern ? 28 : 0
        let bottomInset: CGFloat = modern ? -5 : 0
        NSLayoutConstraint.activate([
            progressBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            progressBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            progressBarView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomInset),
            progressBarView.heightAnchor.constraint(equalToConstant: 2),
        ])
    }

    private func setupPreviousNextOverlay() {
        if #available(iOS 26, *) {
            let effectView = UIVisualEffectView(effect: nil)
            effectView.contentView.addSubview(previousNextImage)
            previousNextOverlay = effectView
            previousNextImage.tintColor = .label
        } else {
            previousNextOverlay.backgroundColor = .black
            previousNextOverlay.addSubview(previousNextImage)
            previousNextImage.tintColor = .white
        }
        previousNextOverlay.translatesAutoresizingMaskIntoConstraints = false
        previousNextOverlay.isHidden = true

        previousNextImage.translatesAutoresizingMaskIntoConstraints = false
        previousNextImage.clipsToBounds = true
        previousNextImage.contentMode = .scaleAspectFill
        self.addSubview(previousNextOverlay)
        pin(previousNextOverlay, filling: self)

        #if os(iOS)
        if #available(iOS 26.0, *) {
            let corners = UICornerConfiguration.capsule()
            previousNextOverlay.cornerConfiguration = corners
        }
        #endif

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
        self.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFullScreen(_:)))
        infoContainer.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressPlayPause(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.allowableMovement = 10
        playPauseButton.addGestureRecognizer(longPress)
    }

    private func setupConstraint() {
        internalLeadingAnchorConstraint = audioMiniPlayer.leadingAnchor.constraint(equalTo: leadingAnchor)
        internalTrailingAnchorConstraint = audioMiniPlayer.trailingAnchor.constraint(equalTo: trailingAnchor)
        internalBottomAnchorConstraint = audioMiniPlayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        internalTopAnchorConstraint = audioMiniPlayer.topAnchor.constraint(equalTo: topAnchor)
        NSLayoutConstraint.activate([
            internalLeadingAnchorConstraint,
            internalTrailingAnchorConstraint,
            internalBottomAnchorConstraint,
            internalTopAnchorConstraint
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
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        setMediaInfo(metadata)
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        progressBarView.progress = playbackService.playbackPosition
    }

#if os(iOS)
    func updateWidgetsIfNeeded() {
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
                                        to: PlaybackService.sharedInstance().playerDisplayController,
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
        topGestureWasPerformed = false
    }

    private func dragStateDidChange(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)

        switch panDirection {
        case .horizontal:
            internalLeadingAnchorConstraint.constant += translation.x
            internalTrailingAnchorConstraint.constant += translation.x
            handleHorizontalTranslation(in: self)
            setNeedsLayout()
            layoutIfNeeded()
            sender.setTranslation(CGPoint.zero, in: nil)
        case .vertical:
            if translation.y < -bounds.height / 2 && !topGestureWasPerformed {
                topGestureWasPerformed = true
                #if os(iOS)
                ImpactFeedbackGenerator().limitOverstepped()
                #endif
                handleFullScreen(self)
            }
        }
    }

    private func dragDidEnd(_ sender: UIPanGestureRecognizer) {
        guard panDirection == .horizontal else { return }

        switch horizontalPosition {
        case .right:
            playbackService.next()
        case .left:
            playbackService.previous()
        case .center:
            break
        }
        internalLeadingAnchorConstraint.constant = 0
        internalTrailingAnchorConstraint.constant = 0
        horizontalPosition = .center
        hidePreviousNextOverlay()
        UIView.animate(withDuration: animationDuration, animations: {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        })
    }

    // MARK: Drag helpers

    private func getPanDirection(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: nil)
        panDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
    }

    private func handleHorizontalTranslation(in superview: UIView) {
        var hapticFeedbackNeeded = false
        switch horizontalPosition {
        case .center:
            if audioMiniPlayer.center.x < superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                horizontalPosition = .left
            } else if audioMiniPlayer.center.x > 2 * superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                horizontalPosition = .right
            }
        case .left:
            if audioMiniPlayer.center.x > superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                horizontalPosition = .center
                hidePreviousNextOverlay()
            } else {
                showPreviousNextOverlay(imageNamed: "MiniPrev",
                                        alpha: abs(superview.bounds.midX - audioMiniPlayer.center.x) / (superview.frame.width / 2))
            }
        case .right:
            if audioMiniPlayer.center.x < 2 * superview.frame.width / 3 {
                hapticFeedbackNeeded = true
                horizontalPosition = .center
                hidePreviousNextOverlay()
            } else {
                showPreviousNextOverlay(imageNamed: "MiniNext",
                                        alpha: abs(superview.bounds.midX - audioMiniPlayer.center.x) / (superview.frame.width / 2))
            }
        }

        #if os(iOS)
        if hapticFeedbackNeeded {
            ImpactFeedbackGenerator().limitOverstepped()
        }
        #endif
    }

    private func showPreviousNextOverlay(imageNamed imageName: String, alpha: CGFloat) {
        previousNextImage.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        previousNextOverlay.isHidden = false
        guard let effectView = previousNextOverlay as? UIVisualEffectView else {
            previousNextOverlay.alpha = alpha
            return
        }
        previousNextImage.alpha = alpha
        if effectView.effect == nil {
            UIView.animate(withDuration: animationDuration) {
                effectView.effect = UIBlurEffect(style: .systemThinMaterial)
            }
        }
    }

    func hidePreviousNextOverlay() {
        UIView.animate(withDuration: animationDuration, animations: {
            if let effectView = self.previousNextOverlay as? UIVisualEffectView {
                effectView.effect = nil
                self.previousNextImage.alpha = 0.0
            } else {
                self.previousNextOverlay.alpha = 0.0
            }
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
            artworkImageView.setImage(metadata.artworkImage, placeholderName: metadata.placeholderName)
            artworkBlurImageView?.image = metadata.artworkImage
            artworkBlurView?.isHidden = false
            playbackService.videoOutputView = nil
        } else {
            artworkImageView.setImage(nil, placeholderName: nil)
            artworkBlurImageView?.image = nil
            artworkBlurView?.isHidden = true
            playbackService.videoOutputView = artworkImageView
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

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
            let shuffleIcon = UIImage(named: "iconShuffle")?.withTintColor(shuffleIconTint, renderingMode: .alwaysOriginal)
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
                         guard self.playbackService.playerIsSetup else { return }
                         self.playbackService.stopPlayback()
                     }
        )

        return UIMenu(title: NSLocalizedString("MENU_PLAYBACK_CONTROLS", comment: ""), children: actions)
    }

    private func addContextMenu() {
        self.addInteraction(UIContextMenuInteraction(delegate: self))
    }
}

// MARK: - ZoomTransitionEndpoint

extension AudioMiniPlayer: ZoomTransitionEndpoint {
    var zoomTransitionArtworkView: VLCArtworkImageView? {
        return artworkImageView
    }
}
