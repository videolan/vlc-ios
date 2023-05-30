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
    var visible: Bool = false
    var contentHeight: Float {
        return AudioMiniPlayer.height
    }

    @IBOutlet private weak var audioMiniPlayer: UIView!
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var artworkBlurImageView: UIImageView!
    @IBOutlet weak var artworkBlurView: UIVisualEffectView!
    @IBOutlet private weak var titleLabel: VLCMarqueeLabel!
    @IBOutlet private weak var artistLabel: VLCMarqueeLabel!
    @IBOutlet private weak var progressBarView: UIProgressView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var repeatButton: UIButton!
    @IBOutlet private weak var shuffleButton: UIButton!
    @IBOutlet private weak var previousNextOverlay: UIView!
    @IBOutlet private weak var previousNextImage: UIImageView!

    private let draggingDelegate: MiniPlayerDraggingDelegate

    private let animationDuration = 0.2

    private var mediaService: MediaLibraryService
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

    @objc init(service: MediaLibraryService, draggingDelegate: MiniPlayerDraggingDelegate) {
        self.mediaService = service
        self.draggingDelegate = draggingDelegate
        super.init(frame: .zero)
        initView()
        setupConstraint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePlayPauseButton() {
        playPauseButton.isSelected = playbackService.isPlaying
    }

    func updateRepeatButton() {
        switch playbackService.repeatMode {
        case .doNotRepeat:
            repeatButton.setImage(UIImage(named: "iconNoRepeat"), for: .normal)
            repeatButton.tintColor = .white
        case .repeatCurrentItem:
            repeatButton.setImage(UIImage(named: "iconRepeatOne"), for: .normal)
            repeatButton.tintColor = PresentationTheme.current.colors.orangeUI
        case .repeatAllItems:
            repeatButton.setImage(UIImage(named: "iconRepeat"), for: .normal)
            repeatButton.tintColor = PresentationTheme.current.colors.orangeUI
        @unknown default:
            assertionFailure("AudioMiniPlayer.updateRepeatButton: unhandled case.")
        }
    }

    func updateShuffleButton() {
        let colors = PresentationTheme.current.colors
        shuffleButton.tintColor =
        playbackService.isShuffleMode ? colors.orangeUI : colors.cellTextColor
    }

    @objc func setupQueueViewController(with view: QueueViewController) {
        queueViewController = view
        queueViewController?.delegate = self
    }
}

// MARK: - Private initializers

private extension AudioMiniPlayer {
    private func initView() {
        Bundle.main.loadNibNamed("AudioMiniPlayer", owner: self, options: nil)
        addSubview(audioMiniPlayer)

        audioMiniPlayer.clipsToBounds = true
        audioMiniPlayer.layer.cornerRadius = 4
        audioMiniPlayer.layer.borderWidth = 0.5
        audioMiniPlayer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        progressBarView.clipsToBounds = true

        if #available(iOS 11.0, *) {
            artworkImageView.accessibilityIgnoresInvertColors = true
            artworkBlurImageView.accessibilityIgnoresInvertColors = true
        }
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 2

        playPauseButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        nextButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON", comment: "")
        previousButton.accessibilityLabel = NSLocalizedString("PREV_BUTTON", comment: "")
        isUserInteractionEnabled = true

        if #available(iOS 13.0, *) {
            addContextMenu()
        }
    }

    private func setupConstraint() {
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        audioMiniPlayer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([audioMiniPlayer.leadingAnchor.constraint(equalTo: guide.leadingAnchor,
                                                                              constant: 8),
                                     audioMiniPlayer.trailingAnchor.constraint(equalTo: guide.trailingAnchor,
                                                                               constant: -8),
                                     audioMiniPlayer.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                                             constant: -8),
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
        if let queueCollectionView = queueViewController?.queueCollectionView {
            queueCollectionView.reloadData()
        }
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        setMediaInfo(metadata)
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        progressBarView.progress = playbackService.playbackPosition
    }
}

// MARK: - UI Receivers

private extension AudioMiniPlayer {
    @IBAction private func handlePrevious(_ sender: UIButton) {
        playbackService.previous()
    }

    @IBAction private func handlePlayPause(_ sender: UIButton) {
        playbackService.playPause()
        updatePlayPauseButton()
    }

    @IBAction private func handleNext(_ sender: UIButton) {
        playbackService.next()
    }

    @IBAction private func handelRepeat(_ sender: UIButton) {
        playbackService.toggleRepeatMode()
        updateRepeatButton()
    }

    @IBAction private func handleShuffle(_ sender: UIButton? = nil) {
        playbackService.isShuffleMode = !playbackService.isShuffleMode
        updateShuffleButton()
    }

    @IBAction private func handleFullScreen(_ sender: Any) {
        if position.vertical == .top {
            dismissPlayqueue(with: nil)
        }

        let currentMedia: VLCMedia? = playbackService.currentlyPlayingMedia
        let mlMedia: VLCMLMedia? = VLCMLMedia.init(forPlaying: currentMedia)

        let selector: Selector
        if let mlMedia = mlMedia, mlMedia.type() == .audio {
            selector = #selector(VLCPlayerDisplayController.showAudioPlayer)
        } else {
            selector = #selector(VLCPlayerDisplayController.showFullscreenPlayback)
        }

        UIApplication.shared.sendAction(selector,
                                        to: nil,
                                        from: self,
                                        for: nil)
    }

    @IBAction private func handleLongPressPlayPause(_ sender: UILongPressGestureRecognizer) {
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
    @IBAction func didDrag(_ sender: UIPanGestureRecognizer) {
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
        sender.setTranslation(CGPoint.zero, in: UIApplication.shared.keyWindow?.rootViewController?.view)
        handleHapticFeedback()
        draggingDelegate.miniPlayerNeedsLayout(self)
    }

    private func dragDidEnd(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: UIApplication.shared.keyWindow?.rootViewController?.view)
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
        let velocity = sender.velocity(in: UIApplication.shared.keyWindow?.rootViewController?.view)
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
        if hapticFeedbackNeeded, #available(iOS 10.0, *) {
            ImpactFeedbackGenerator().limitOverstepped()
        }
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
        if (!UIAccessibility.isReduceTransparencyEnabled && metadata.isAudioOnly) ||
            playbackService.playAsAudio {
            // Only update the artwork image when the media is being played
            if playbackService.isPlaying {
                artworkImageView.image = metadata.artworkImage ?? UIImage(named: "no-artwork")
                artworkBlurImageView.image = metadata.artworkImage
                queueViewController?.reloadBackground(with: metadata.artworkImage)
                artworkBlurView.isHidden = false
            }

            playbackService.videoOutputView = nil
        } else {
            artworkBlurImageView.image = nil
            queueViewController?.reloadBackground(with: nil)
            artworkBlurView.isHidden = true
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

        if shuffleButton.isHidden {
            let shuffleState: UIMenuElement.State = playbackService.isShuffleMode ? .on : .off
            let shuffleIconTint: UIColor = shuffleButton.tintColor
            let shuffleIcon = shuffleButton.image(for: .normal)?.withTintColor(shuffleIconTint, renderingMode: .alwaysOriginal)
            actions.append(
                UIAction(title: shuffleButton.currentTitle ?? NSLocalizedString("SHUFFLE", comment: ""),
                         image: shuffleIcon, state: shuffleState) {
                    action in
                    self.handleShuffle()
                }
            )
        }

        if repeatButton.isHidden {
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
