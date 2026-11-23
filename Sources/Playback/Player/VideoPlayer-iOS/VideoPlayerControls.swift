/*****************************************************************************
 * VideoPlayerControls.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2020-2026 VideoLAN. All rights reserved.
 * Copyright © 2020-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
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
    func videoPlayerControlsDelegateDidTapRotate(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateShuffle(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateRepeat(_ videoPlayerControls: VideoPlayerControls)
}


class VideoPlayerControls: UIView {

    // MARK: - Left Controls

    private(set) lazy var rotationLockButton = makeBarButton(image: nil,
                                                             action: #selector(handleRotationLockButton(_:)))

    private(set) lazy var subtitleButton = makeBarButton(image: UIImage(named: "iconSubtitle"),
                                                         action: #selector(handleSubtitleButton(_:)))

    private(set) lazy var repeatButton: UIButton = {
        let button = makeBarButton(image: UIImage(named: "iconRepeat"), action: #selector(handleRepeatButton(_:)))
        button.isHidden = true
        return button
    }()

    private(set) lazy var leftControls = PlayerControlGroupView(arrangedSubviews: [rotationLockButton,
                                                                                   subtitleButton,
                                                                                   repeatButton])

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

    private static let sideButtonSize: CGFloat = 56

    private static let sideButtonRatio = sideButtonSize / playPauseCircleSize

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

    private var transportSizeConstraints: [NSLayoutConstraint] = []

    // MARK: - Right Controls

    private(set) lazy var shuffleButton: UIButton = {
        let button = makeBarButton(image: UIImage(named: "shuffle"), action: #selector(handleShuffleButton(_:)))
        button.isHidden = true
        return button
    }()

    private(set) lazy var aspectRatioButton: MenuButton = {
        let button = MenuButton(type: .custom)
        button.setImage(UIImage(named: "aspectRatio"), for: .normal)
        button.tintColor = .white
        button.overrideUserInterfaceStyle = .dark
        if #available(iOS 16.0, *) {
            button.preferredMenuElementOrder = .fixed
        }
        button.addTarget(self, action: #selector(handleAspectRatioButton(_:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var rotateButton: UIButton = {
        let button = makeBarButton(image: UIImage(named: "rectangle.landscape.rotate"),
                                   action: #selector(handleRotateButton(_:)))
        if #available(iOS 16.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            button.isHidden = true
        }
        return button
    }()

    private(set) lazy var moreActionsButton: MenuButton = {
        let button = MenuButton(type: .custom)
        button.setImage(UIImage(named: "iconMoreOptions"), for: .normal)
        button.tintColor = .white
        button.overrideUserInterfaceStyle = .dark
        button.showsMenuAsPrimaryAction = true
        if #available(iOS 16.0, *) {
            button.preferredMenuElementOrder = .fixed
        }
        return button
    }()

    private(set) lazy var rightControls = PlayerControlGroupView(arrangedSubviews: [shuffleButton,
                                                                                    aspectRatioButton,
                                                                                    rotateButton,
                                                                                    moreActionsButton])

    // MARK: -

    weak var delegate: VideoPlayerControlsDelegate?

    init() {
        super.init(frame: .zero)
        setupViews()
        setupTransportConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftControls)
        addSubview(rightControls)
        NSLayoutConstraint.activate([
            leftControls.leftAnchor.constraint(equalTo: leftAnchor),
            leftControls.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightControls.rightAnchor.constraint(equalTo: rightAnchor),
            rightControls.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func makeBarButton(image: UIImage?, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    /// Call inside an animation block; keep this view and its ancestors at alpha 1.
    func setControlsVisible(_ visible: Bool, isQueueShown: Bool) {
        leftControls.setVisible(visible, dimmed: isQueueShown)
        rightControls.setVisible(visible && !isQueueShown)
        transportControls.isUserInteractionEnabled = visible
        transportControls.accessibilityElementsHidden = !visible
        let transportAlpha = visible ? (isQueueShown ? PlayerControlGroupView.dimmedAlpha : 1) : 0
        for case let button as UIButton in transportControls.arrangedSubviews {
            guard let background = button.configuration?.background.customView as? VideoControlBackgroundView else {
                button.alpha = transportAlpha
                continue
            }
            if visible {
                UIView.performWithoutAnimation {
                    button.alpha = 1
                }
            }
            button.imageView?.alpha = transportAlpha
            background.setVisible(visible)
        }
    }

    func controlsDidHide() {
        playPauseButton.alpha = 0
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

        rotateButton.accessibilityLabel = NSLocalizedString("ROTATE_BUTTON",
                                                            comment: "Accessibility label for rotate button on the player")
        rotateButton.accessibilityHint = NSLocalizedString("ROTATE_BUTTON_HINT",
                                                           comment: "Accessibility hint for rotate button on the player")

        moreActionsButton.accessibilityLabel = NSLocalizedString("MORE_OPTIONS_BUTTON",
                                                                 comment: "")
        moreActionsButton.accessibilityHint = NSLocalizedString("MORE_OPTIONS_HINT",
                                                                comment: "")
        moreActionsButton.accessibilityIdentifier = VLCAccessibilityIdentifier.moreOptions

        // Play/pause is the most important.
        // Then, next track, then previous.
        transportControls.applyAccessibilityControls(
            playPauseButton,
            nextMediaButton,
            previousMediaButton,
            backwardButton,
            forwardButton
        )
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
        let touchOutset = Self.playPauseTouchOutset
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: systemImageName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: hasGlassBackground ? 26 : 22, weight: .semibold)
        if hasGlassBackground {
            configuration.background.customView = VideoControlBackgroundView()
            configuration.background.backgroundInsets = NSDirectionalEdgeInsets(
                top: touchOutset, leading: touchOutset, bottom: touchOutset, trailing: touchOutset)
        }
        let button = WideTouchButton(configuration: configuration)
        if hasGlassBackground {
            button.horizontalTouchOutset = Self.playPauseSideTouchOutset - touchOutset
        } else {
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

    private func setupTransportConstraints() {
        let touchOutset = Self.playPauseTouchOutset
        let preferredPlayPauseWidth = playPauseButton.widthAnchor.constraint(
            equalToConstant: Self.playPauseCircleSize + 2 * touchOutset)
        preferredPlayPauseWidth.priority = .defaultHigh
        let minimumSideButtonSize: CGFloat = 44
        let minimumPlayPauseWidth = playPauseButton.widthAnchor.constraint(
            greaterThanOrEqualToConstant: minimumSideButtonSize / Self.sideButtonRatio + 2 * touchOutset)
        let preferredWidth = transportControls.widthAnchor.constraint(
            equalToConstant: 2 * Self.sideButtonSize + Self.playPauseCircleSize + 2 * Self.transportGap)
        // Close gaps before shrinking buttons.
        preferredWidth.priority = .defaultHigh - 1
        NSLayoutConstraint.activate([preferredPlayPauseWidth, minimumPlayPauseWidth, preferredWidth])
        updateTransportSizeConstraints()
    }

    private func updateTransportSizeConstraints() {
        NSLayoutConstraint.deactivate(transportSizeConstraints)

        let touchOutset = Self.playPauseTouchOutset
        let sideButtonRatio = Self.sideButtonRatio
        // Hidden stack buttons have zero width; constrain only the visible pair.
        let leftButton = previousMediaButton.isHidden ? backwardButton : previousMediaButton
        let rightButton = nextMediaButton.isHidden ? forwardButton : nextMediaButton
        transportSizeConstraints = [leftButton, rightButton].map {
            $0.widthAnchor.constraint(equalTo: playPauseButton.widthAnchor,
                                      multiplier: sideButtonRatio,
                                      constant: -2 * touchOutset * sideButtonRatio)
        }
        // Shrink buttons before reducing the minimum gap.
        let leftGap = playPauseButton.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.trailingAnchor,
                                                               constant: 24)
        let rightGap = rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: playPauseButton.trailingAnchor,
                                                            constant: 24)
        leftGap.priority = .defaultHigh + 1
        rightGap.priority = .defaultHigh + 1
        transportSizeConstraints += [leftGap, rightGap]
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

// MARK: - Actions

// MARK: - Left Controls

extension VideoPlayerControls {
    @objc func handleSubtitleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapSubtitle(self)
    }

    @objc func handleRotationLockButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapRotationLock(self)
    }
    @objc func handleRepeatButton(_ sender: Any) {
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
    @objc func handleAspectRatioButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapAspectRatio(self)
    }

    @objc func handleRotateButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapRotate(self)
    }

    @objc func handleShuffleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateShuffle(self)
    }
}

final class WideTouchButton: UIButton {
    var horizontalTouchOutset: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -horizontalTouchOutset, dy: 0).contains(point)
    }
}
