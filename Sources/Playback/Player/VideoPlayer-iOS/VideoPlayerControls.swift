/*****************************************************************************
 * VideoPlayerControls.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2020-2026 VideoLAN. All rights reserved.
 * Copyright © 2020-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
*****************************************************************************/

@objc(VLCVideoPlayerControlsDelegate)
protocol VideoPlayerControlsDelegate: AnyObject {
    // MARK: - Left Controls

    func videoPlayerControlsDelegateDidTapSubtitle(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls)

    // MARK: - Main Controls

    func videoPlayerControlsDelegateDidTapBackward(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapPreviousMedia(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapPlayPause(_ videoPlayerControls: VideoPlayerControls)
    @objc optional func videoPlayerControlsDelegateDidLongPressPlayPauseBegan(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidLongPressPlayPauseEnded(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapNextMedia(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapForward(_ videoPlayerControls: VideoPlayerControls)

    // MARK: - Right Controls

    func videoPlayerControlsDelegateDidTapAspectRatio(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidLongPressAspectRatio(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidMoreActions(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateShuffle(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateRepeat(_ videoPlayerControls: VideoPlayerControls)
}


class VideoPlayerControls: UIView {

    // MARK: - IB properties

    // MARK: - Left Controls

    @IBOutlet weak var leftControls: UIStackView!

    @IBOutlet weak var subtitleButton: UIButton!

    @IBOutlet weak var rotationLockButton: UIButton!

    @IBOutlet weak var repeatButton: UIButton!
    // MARK: - Main Controls

    private(set) lazy var backwardButton = makeTransportButton(systemImageName: "gobackward",
                                                               action: #selector(handleBackwardButton(_:)))

    private(set) lazy var previousMediaButton = makeTransportButton(systemImageName: "backward.end.fill",
                                                                    action: #selector(handlePreviousButton(_:)))

    private(set) lazy var playPauseButton: WideTouchButton = {
        let button = makeTransportButton(systemImageName: "play.fill",
                                         action: #selector(handlePlayPauseButton(_:)),
                                         hasGlassBackground: true)
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(handlePlayPauseLongPressButton(_:)))
        longPressGesture.minimumPressDuration = 1
        longPressGesture.allowableMovement = 10
        button.addGestureRecognizer(longPressGesture)
        return button
    }()

    private(set) lazy var nextMediaButton = makeTransportButton(systemImageName: "forward.end.fill",
                                                                action: #selector(handleNextButton(_:)))

    private(set) lazy var forwardButton = makeTransportButton(systemImageName: "goforward",
                                                              action: #selector(handleForwardButton(_:)))

    static let playPauseCircleSize: CGFloat = 72

    private static let transportGap: CGFloat = 40

    private static let playPauseTouchOutset: CGFloat = 12

    private static let playPauseSideTouchOutset: CGFloat = 44

    private(set) lazy var transportControls: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [backwardButton,
                                                       previousMediaButton,
                                                       playPauseButton,
                                                       nextMediaButton,
                                                       forwardButton])
        stackView.semanticContentAttribute = .forceLeftToRight
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.overrideUserInterfaceStyle = .dark
        stackView.translatesAutoresizingMaskIntoConstraints = false
        backwardButton.isHidden = true
        forwardButton.isHidden = true
        // Give skip buttons priority over the expanded play target.
        stackView.sendSubviewToBack(playPauseButton)
        return stackView
    }()

    /// Uses smaller controls above the play queue.
    var isTransportCompact = false {
        didSet {
            updateTransportSizeConstraints()
        }
    }

    private var transportSizeConstraints: [NSLayoutConstraint] = []

    // MARK: - Right Controls

    @IBOutlet weak var aspectRatioButton: UIButton!

    @IBOutlet weak var moreActionsButton: UIButton!

    @IBOutlet weak var shuffleButton: UIButton!

    @IBOutlet weak var rightControls: UIStackView!
    // MARK: -

    weak var delegate: VideoPlayerControlsDelegate?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateTransportSizeConstraints()
    }

    func setupAccessibility() {
        subtitleButton.accessibilityLabel = NSLocalizedString("SUBTITLE_AND_TRACK_BUTTON",
                                                              comment: "")
        subtitleButton.accessibilityHint = NSLocalizedString("SUBTITLE_AND_TRACK_HINT",
                                                             comment: "")

        rotationLockButton.accessibilityLabel = NSLocalizedString("ROTATION_LOCK_BUTTON",
                                                                  comment: "")
        rotationLockButton.accessibilityHint = NSLocalizedString("ROTATION_LOCK_HINT",
                                                                 comment: "")
        
        repeatButton.accessibilityLabel = NSLocalizedString("REPEAT_MODE",
                                                            comment: "")
        repeatButton.accessibilityHint = NSLocalizedString("REPEAT_HINT",
                                                           comment: "")

        backwardButton.accessibilityLabel = NSLocalizedString("BACKWARD_BUTTON",
                                                              comment: "")
        backwardButton.accessibilityHint = NSLocalizedString("BACKWARD_HINT",
                                                             comment: "")

        previousMediaButton.accessibilityLabel = NSLocalizedString("PREVIOUS_BUTTON",
                                                                   comment: "")
        previousMediaButton.accessibilityHint = NSLocalizedString("PREVIOUS_HINT",
                                                                  comment: "")

        playPauseButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON",
                                                               comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("PLAY_PAUSE_HINT",
                                                              comment: "")

        nextMediaButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON",
                                                               comment: "")
        nextMediaButton.accessibilityHint = NSLocalizedString("NEXT_HINT",
                                                              comment: "")

        forwardButton.accessibilityLabel = NSLocalizedString("FORWARD_BUTTON",
                                                             comment: "")
        forwardButton.accessibilityHint = NSLocalizedString("FORWARD_HINT",
                                                            comment: "")

        shuffleButton.accessibilityLabel = NSLocalizedString("SHUFFLE",
                                                             comment: "")
        shuffleButton.accessibilityHint = NSLocalizedString("SHUFFLE_HINT",
                                                            comment: "")
        
        aspectRatioButton.accessibilityLabel = NSLocalizedString("VIDEO_ASPECT_RATIO_BUTTON",
                                                                 comment: "")
        aspectRatioButton.accessibilityHint = NSLocalizedString("VIDEO_ASPECT_RATIO_HINT",
                                                                comment: "")

        moreActionsButton.accessibilityLabel = NSLocalizedString("MORE_OPTIONS_BUTTON",
                                                                 comment: "")
        moreActionsButton.accessibilityHint = NSLocalizedString("MORE_OPTIONS_HINT",
                                                                comment: "")
        moreActionsButton.accessibilityIdentifier = VLCAccessibilityIdentifier.moreOptions

        self.accessibilityLabel = NSLocalizedString("PLAYBACK_CONTROLS_BAR_TITLE",
                                                    comment: "")
        self.accessibilityHint = NSLocalizedString("PLAYBACK_CONTROLS_BAR_HINT",
                                                   comment: "")

        // Play/pause is the most important.
        // Then, next track, then previous.
        // Lastly, iterate over the remaining controls left to right.
        transportControls.applyAccessibilityControls(
            playPauseButton,
            nextMediaButton,
            previousMediaButton,
            backwardButton,
            forwardButton
        )
        applyAccessibilityControls(
            rotationLockButton,
            subtitleButton,
            repeatButton,
            shuffleButton,
            aspectRatioButton,
            moreActionsButton
        )
    }

    func setupLongPressGestureRecognizer() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleAspectRatioLongPress(_:)))
        aspectRatioButton.addGestureRecognizer(longPressGesture)
    }

    func updatePlayPauseButton(toState isPlaying: Bool) {
        playPauseButton.configuration?.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
    }

    func updateSkipButtonImages(backwardBy: Int, forwardBy: Int) {
        backwardButton.configuration?.image = Self.skipImage(named: "gobackward", seconds: backwardBy)
        forwardButton.configuration?.image = Self.skipImage(named: "goforward", seconds: forwardBy)
    }

    private static func skipImage(named name: String, seconds: Int) -> UIImage? {
        // Some skip lengths have no numbered SF Symbol.
        return UIImage(systemName: "\(name).\(seconds)") ?? UIImage(systemName: name)
    }

    private func makeTransportButton(systemImageName: String, action: Selector,
                                     hasGlassBackground: Bool = false) -> WideTouchButton {
        var configuration = Self.transportButtonConfiguration()
        configuration.image = UIImage(systemName: systemImageName)
        if hasGlassBackground {
            configuration.background.customView = VideoControlBackgroundView()
        }
        let button = WideTouchButton(configuration: configuration)
        if !hasGlassBackground {
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 3
            button.layer.shadowOpacity = 0.45
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        // Let size constraints override the icon's intrinsic size.
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private static func transportButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        return configuration
    }

    /// Call inside an animation block to fade the main buttons.
    func setTransportControlsVisible(_ visible: Bool) {
        transportControls.isUserInteractionEnabled = visible
        transportControls.accessibilityElementsHidden = !visible
        for case let button as UIButton in transportControls.arrangedSubviews {
            button.imageView?.alpha = visible ? 1 : 0
            let background = button.configuration?.background.customView as? VideoControlBackgroundView
            background?.setVisible(visible)
        }
    }

    private func updateTransportSizeConstraints() {
        NSLayoutConstraint.deactivate(transportSizeConstraints)

        // Match the 44pt bar above the queue.
        let buttonSize: CGFloat = isTransportCompact ? 44 : 56
        let playPauseCircleSize = isTransportCompact ? buttonSize : Self.playPauseCircleSize
        let touchOutset = isTransportCompact ? 0 : Self.playPauseTouchOutset
        playPauseButton.configuration?.background.backgroundInsets = NSDirectionalEdgeInsets(
            top: touchOutset, leading: touchOutset, bottom: touchOutset, trailing: touchOutset)
        playPauseButton.horizontalTouchOutset = isTransportCompact ? 0 : Self.playPauseSideTouchOutset - touchOutset
        let iconSize: CGFloat = isTransportCompact ? 20 : 22
        for case let button as UIButton in transportControls.arrangedSubviews {
            let pointSize = button == playPauseButton && !isTransportCompact ? 26 : iconSize
            button.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: pointSize, weight: .semibold)
        }

        let preferredPlayPauseWidth = playPauseButton.widthAnchor.constraint(
            equalToConstant: playPauseCircleSize + 2 * touchOutset)
        preferredPlayPauseWidth.priority = .defaultHigh
        let sideButtonRatio = buttonSize / playPauseCircleSize
        let minimumSideButtonSize: CGFloat = isTransportCompact ? 32 : 44
        let minimumPlayPauseWidth = playPauseButton.widthAnchor.constraint(
            greaterThanOrEqualToConstant: minimumSideButtonSize / sideButtonRatio + 2 * touchOutset)
        let preferredWidth = transportControls.widthAnchor.constraint(
            equalToConstant: isTransportCompact ? 180 : 2 * buttonSize + playPauseCircleSize + 2 * Self.transportGap)
        // Close gaps before shrinking buttons.
        preferredWidth.priority = .defaultHigh - 1

        // Hidden stack buttons have zero width; constrain only the visible pair.
        let leftButton = previousMediaButton.isHidden ? backwardButton : previousMediaButton
        let rightButton = nextMediaButton.isHidden ? forwardButton : nextMediaButton
        transportSizeConstraints = [leftButton, rightButton].map {
            $0.widthAnchor.constraint(equalTo: playPauseButton.widthAnchor,
                                      multiplier: sideButtonRatio,
                                      constant: -2 * touchOutset * sideButtonRatio)
        }
        transportSizeConstraints += [preferredPlayPauseWidth, minimumPlayPauseWidth, preferredWidth]
        if isTransportCompact {
            let clearOfLeftControls = transportControls.leadingAnchor.constraint(
                greaterThanOrEqualTo: leftControls.trailingAnchor, constant: 8)
            let clearOfRightControls = transportControls.trailingAnchor.constraint(
                lessThanOrEqualTo: rightControls.leadingAnchor, constant: -8)
            clearOfLeftControls.priority = .required - 1
            clearOfRightControls.priority = .required - 1
            transportSizeConstraints += [clearOfLeftControls, clearOfRightControls]
        } else {
            // Shrink buttons before reducing the minimum gap.
            let leftGap = playPauseButton.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.trailingAnchor,
                                                                   constant: 24)
            let rightGap = rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: playPauseButton.trailingAnchor,
                                                                constant: 24)
            leftGap.priority = .defaultHigh + 1
            rightGap.priority = .defaultHigh + 1
            transportSizeConstraints += [leftGap, rightGap]
        }
        NSLayoutConstraint.activate(transportSizeConstraints)
    }

    func shouldEnableSeekButtons(_ enable: Bool) {
        let swapsButtons = backwardButton.isHidden == enable
        backwardButton.isEnabled = enable
        backwardButton.isHidden = !enable
        forwardButton.isEnabled = enable
        forwardButton.isHidden = !enable

        previousMediaButton.isEnabled = !enable
        previousMediaButton.isHidden = enable
        nextMediaButton.isEnabled = !enable
        nextMediaButton.isHidden = enable
        if swapsButtons {
            updateTransportSizeConstraints()
        }
    }

    func shouldDisableControls(_ disable: Bool) {
        subtitleButton.isEnabled = !disable
        rotationLockButton.isEnabled = !disable
        repeatButton.isEnabled = !disable
        backwardButton.isEnabled = !disable
        previousMediaButton.isEnabled = !disable
        nextMediaButton.isEnabled = !disable
        forwardButton.isEnabled = !disable
        aspectRatioButton.isEnabled = !disable
        moreActionsButton.isEnabled = !disable
        shuffleButton.isEnabled = !disable
    }
}

// MARK: - IB Actions

// MARK: - Left Controls

extension VideoPlayerControls {
    @IBAction func handleSubtitleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapSubtitle(self)
    }

    @IBAction func handleRotationLockButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapRotationLock(self)
    }
    @IBAction func handleRepeatButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateRepeat(self)
    }
}

// MARK: - Main Controls

extension VideoPlayerControls {
    @objc func handleBackwardButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapBackward(self)
    }

    @objc func handlePreviousButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapPreviousMedia(self)
    }

    @objc func handlePlayPauseButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapPlayPause(self)
    }

    @objc func handlePlayPauseLongPressButton(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            delegate?.videoPlayerControlsDelegateDidLongPressPlayPauseBegan?(self)
        case .ended:
            delegate?.videoPlayerControlsDelegateDidLongPressPlayPauseEnded(self)
        case .cancelled, .failed:
            delegate?.videoPlayerControlsDelegateDidTapPlayPause(self)
        default:
            break
        }
    }

    @objc func handleNextButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapNextMedia(self)
    }

    @objc func handleForwardButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapForward(self)
    }
}

// MARK: - Right Controls

extension VideoPlayerControls {
    @IBAction func handleAspectRatioButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapAspectRatio(self)
    }

    @objc func handleAspectRatioLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.videoPlayerControlsDelegateDidLongPressAspectRatio(self)
        }
    }

    @IBAction func handleMoreActionsButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidMoreActions(self)
    }

    @IBAction func handleShuffleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateShuffle(self)
    }
}

final class WideTouchButton: UIButton {
    var horizontalTouchOutset: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -horizontalTouchOutset, dy: 0).contains(point)
    }
}
