/*****************************************************************************
 * AudioMiniPlayer.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

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

enum PanDirection {
    case vertical
    case horizontal
}

@objc(VLCAudioMiniPlayer)
class AudioMiniPlayer: UIView, MiniPlayer {
    @objc static let height: Float = 72.0
    var visible: Bool = false
    var contentHeight: Float {
        return AudioMiniPlayer.height
    }

    @IBOutlet private weak var audioMiniPlayer: UIView!
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: VLCMarqueeLabel!
    @IBOutlet private weak var artistLabel: VLCMarqueeLabel!
    @IBOutlet private weak var progressBarView: UIProgressView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var previousNextOverlay: UIView!
    @IBOutlet private weak var previousNextImage: UIImageView!

    private var mediaService: MediaLibraryService
    private lazy var playbackController = PlaybackService.sharedInstance()

    @objc public var queueViewController: QueueViewController?

    var position = MiniPlayerPosition(vertical: .bottom, horizontal: .center)
    var originY: CGFloat = 0.0
    var tapticPosition = MiniPlayerPosition(vertical: .bottom, horizontal: .center)
    var panDirection: PanDirection = .vertical

    @objc init(service: MediaLibraryService) {
        self.mediaService = service
        super.init(frame: .zero)
        initView()
        setupConstraint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePlayPauseButton() {
        let imageName = playbackController.isPlaying ? "MiniPause" : "MiniPlay"
        playPauseButton.imageView?.image = UIImage(named: imageName)
    }
}

// MARK: - Private initializers

private extension AudioMiniPlayer {
    private func initView() {
        Bundle.main.loadNibNamed("AudioMiniPlayer", owner: self, options: nil)
        addSubview(audioMiniPlayer)

        audioMiniPlayer.clipsToBounds = true
        audioMiniPlayer.layer.cornerRadius = 4

        progressBarView.clipsToBounds = true
        progressBarView.layer.cornerRadius = 1

        if #available(iOS 11.0, *) {
            artworkImageView.accessibilityIgnoresInvertColors = true
        }
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 2

        playPauseButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        nextButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON", comment: "")
        previousButton.accessibilityLabel = NSLocalizedString("PREV_BUTTON", comment: "")
        isUserInteractionEnabled = true
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
        playbackService.delegate = self
        playbackService.recoverDisplayedMetadata()
        // For now, AudioMiniPlayer will be used for all media
        if !playbackService.isPlayingOnExternalScreen() {
            playbackService.videoOutputView = artworkImageView
        }
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                 isPlaying: Bool,
                                 currentMediaHasTrackToChooseFrom: Bool,
                                 currentMediaHasChapters: Bool,
                                 for playbackService: PlaybackService) {
        updatePlayPauseButton()
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

    func savePlaybackState(_ playbackService: PlaybackService) {
        mediaService.savePlaybackState(from: playbackService)
    }

    func media(forPlaying media: VLCMedia?) -> VLCMLMedia? {
        guard let media = media else {
            return nil
        }

        return mediaService.fetchMedia(with: media.url)
    }
}

// MARK: - UI Receivers

private extension AudioMiniPlayer {
    @IBAction private func handlePrevious(_ sender: UIButton) {
        playbackController.previous()
    }

    @IBAction private func handlePlayPause(_ sender: UIButton) {
        playbackController.playPause()
    }

    @IBAction private func handleNext(_ sender: UIButton) {
        playbackController.next()
    }

    @IBAction private func handleFullScreen(_ sender: Any) {
        if position.vertical == .top {
            dismissPlayqueue()
        }
        UIApplication.shared.sendAction(#selector(VLCPlayerDisplayController.showFullscreenPlayback),
                                        to: nil,
                                        from: self,
                                        for: nil)
    }

    @IBAction private func handleLongPressPlayPause(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        // case .began:
        // In the case of .began we could a an icon like the old miniplayer
        case .ended:
            playbackController.stopPlayback()
        case .cancelled, .failed:
            playbackController.playPause()
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

    func dragDidBegin(_ sender: UIPanGestureRecognizer) {
        getPanDirection(sender)
        switch panDirection {
            case .vertical:
                queueViewController?.show()
                queueViewController?.initDelegate()
            case .horizontal:
                break
        }
        originY = frame.minY
    }

    func dragStateDidChange(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: UIApplication.shared.keyWindow?.rootViewController?.view)
        switch panDirection {
            case .vertical:
                center = CGPoint(x: center.x, y: center.y + translation.y)
                if let queueView = queueViewController?.view {
                    queueView.center = CGPoint(x: queueView.center.x, y: queueView.center.y + translation.y)
                }
            case .horizontal:
                center = CGPoint(x: center.x + translation.x, y: center.y)
        }
        sender.setTranslation(CGPoint.zero, in: UIApplication.shared.keyWindow?.rootViewController?.view)

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

    func dragDidEnd(_ sender: UIPanGestureRecognizer) {
        if let superview = superview {
            switch panDirection {
                case .vertical:
                    let limit = topBottomLimit(for: superview, with: position.vertical)
                    switch position.vertical {
                        case .top:
                            if self.frame.minY > limit {
                                dismissPlayqueue()
                            } else {
                                showPlayqueue(in: superview)
                            }
                        case .bottom:
                            if self.frame.minY > originY {
                                hideMiniPlayer(from: superview)
                            } else if self.frame.minY > limit {
                                dismissPlayqueue()
                            } else {
                                showPlayqueue(in: superview)
                            }
                    }
                case .horizontal:
                    switch position.horizontal {
                        case .right:
                            playbackController.next()
                        case .left:
                            playbackController.previous()
                        case .center:
                            break
                    }
                    repositionMiniPlayer(in: superview)
                    position.horizontal = .center
            }
            hidePreviousNextOverlay()
        }
    }

// MARK: Drag helpers

    func topBottomLimit(for superview: UIView, with position: MiniPlayerVerticalPosition) -> CGFloat {
        switch position {
            case .top:
                return superview.frame.maxY / 3
            case .bottom:
                return 2 * superview.frame.maxY / 3
        }
    }

    func getPanDirection(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: UIApplication.shared.keyWindow?.rootViewController?.view)
        panDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
    }


    func verticalTranslation(in superview: UIView) -> Bool {
        var hapticFeedbackNeeded = false
        let limit = topBottomLimit(for: superview, with: position.vertical)
        if frame.minY < limit && tapticPosition.vertical == .bottom {
            hapticFeedbackNeeded = true
            queueViewController?.show()
            tapticPosition.vertical = .top
        } else if frame.minY > limit && tapticPosition.vertical == .top {
            hapticFeedbackNeeded = true
            queueViewController?.hide()
            tapticPosition.vertical = .bottom
        }
        if position.vertical == .bottom {
            if frame.minY > originY {
                previousNextImage.image = UIImage(named: "stopIcon")
                previousNextOverlay.alpha = 0.8
                previousNextOverlay.isHidden = false
            } else {
                hidePreviousNextOverlay()
            }
        }
        return hapticFeedbackNeeded
    }

    func horizontalTranslation(in superview: UIView) -> Bool {
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
                    previousNextImage.image = UIImage(named: "MiniPrev")
                    previousNextOverlay.alpha = abs(superview.center.x - center.x) / (superview.frame.width / 2)
                    previousNextOverlay.isHidden = false
                }
            case .right:
                if center.x < 2 * superview.frame.width / 3 {
                    hapticFeedbackNeeded = true
                    position.horizontal = .center
                    hidePreviousNextOverlay()
                } else {
                    previousNextImage.image = UIImage(named: "MiniNext")
                    previousNextOverlay.alpha = abs(superview.center.x - center.x) / (superview.frame.width / 2)
                    previousNextOverlay.isHidden = false
                }
        }
        return hapticFeedbackNeeded
    }

// MARK: Show hide playqueue

    func showPlayqueue(in superview: UIView) {
        if let queueView = queueViewController?.view {
            position.vertical = .top
            tapticPosition.vertical = .top
            let newY: CGFloat = miniPlayerTopPosition(in: superview)
            queueView.setNeedsUpdateConstraints()
            if #available(iOS 10.0, *) {
                let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut)
                animator.addAnimations {
                    self.frame.origin.y = newY
                    queueView.frame.origin.y = newY + self.frame.height
                }
                animator.startAnimation()
            } else {
                frame.origin.y = newY
                queueView.frame.origin.y = newY + frame.height
            }
        }
    }

    func miniPlayerTopPosition(in superview: UIView) -> CGFloat {
        var topPosition: CGFloat
        if #available(iOS 11.0, *) {
            topPosition = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        } else {
            topPosition = superview.frame.origin.y + 25
        }
        if UIApplication.shared.statusBarFrame.height == 0 {
            topPosition += 20
        }
        return topPosition
    }

    func dismissPlayqueue() {
        position.vertical = .bottom
        tapticPosition.vertical = .bottom
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut)
            animator.addCompletion({
                _ in
                self.dismissPlayqueueCompletion()
            })
            animator.addAnimations {
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }
            animator.startAnimation()
        } else {
            superview?.setNeedsLayout()
            superview?.layoutIfNeeded()
            dismissPlayqueueCompletion()
        }
    }

    func dismissPlayqueueCompletion() {
        queueViewController?.hide()
    }

    func hideMiniPlayer(from superview: UIView) {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut)
            animator.addCompletion({
                _ in
                self.playbackController.stopPlayback()
                self.queueViewController?.hide()
            })
            animator.addAnimations {
                self.frame.origin.y = superview.frame.maxY
            }
            animator.startAnimation()
        } else {
            frame.origin.y = superview.frame.maxY
            playbackController.stopPlayback()
            queueViewController?.hide()
        }
    }

    func repositionMiniPlayer(in superview: UIView) {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut)
            animator.addAnimations {
                self.center.x = superview.center.x
            }
            animator.startAnimation()
        } else {
            center.x = superview.center.x
        }
    }

    func hidePreviousNextOverlay() {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut)
            animator.addAnimations {
                self.previousNextOverlay.alpha = 0.0
                self.previousNextOverlay.isHidden = true
            }
            animator.startAnimation()
        } else {
            previousNextOverlay.alpha = 0.0
            previousNextOverlay.isHidden = true
        }
    }

    internal override func layoutSubviews() {
        super.layoutSubviews()
        dismissPlayqueue()
    }
}

// MARK: - Setters

private extension AudioMiniPlayer {
    private func setMediaInfo(_ metadata: VLCMetaData) {
        titleLabel.text = metadata.title
        artistLabel.text = metadata.artist
        if metadata.isAudioOnly {
            artworkImageView.image = metadata.artworkImage ?? UIImage(named: "no-artwork")
        }
    }
}
