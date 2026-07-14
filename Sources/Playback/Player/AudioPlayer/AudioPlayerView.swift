/*****************************************************************************
 * AudioPlayerView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol AudioPlayerViewDelegate: AnyObject {
    func audioPlayerViewDelegateGetThumbnail(_ audioPlayerView: AudioPlayerView) -> UIImage?
    func audioPlayerViewDelegateGetPlaybackSpeed(_ audioPlayerView: AudioPlayerView) -> Float
    func audioPlayerViewDelegateDidTapShuffleButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapBackwardButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapPreviousButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapPlayButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapNextButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapForwardButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapRepeatButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapPlaybackSpeedButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidLongPressPlaybackSpeedButton(_ audioPlayerView: AudioPlayerView)
}

class AudioPlayerView: UIView, UIGestureRecognizerDelegate {
    // MARK: - Properties

    private lazy var backgroundView: UIView = UIView()

    private lazy var backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        return backgroundImageView
    }()

    private lazy var overlayView: UIView = UIView()

    private lazy var blurView: UIVisualEffectView = UIVisualEffectView()

    lazy var navigationBarView: UIView = UIView()

    lazy var thumbnailView: UIView = UIView()

    lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFit
        // The artwork size is driven by layout constraints, never by the
        // bitmap's intrinsic size.
        thumbnailImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        thumbnailImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        thumbnailImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        thumbnailImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return thumbnailImageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: 20.0)
        titleLabel.accessibilityLabel = NSLocalizedString("TITLE", comment: "")
        return titleLabel
    }()

    private lazy var artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 18.0)
        artistLabel.accessibilityLabel = NSLocalizedString("ARTIST", comment: "")
        return artistLabel
    }()

    private lazy var albumLabel: UILabel = {
        let albumLabel = UILabel()
        albumLabel.textAlignment = .center
        albumLabel.font = .systemFont(ofSize: 15.0)
        albumLabel.numberOfLines = 3
        albumLabel.accessibilityLabel = NSLocalizedString("ALBUM", comment: "")
        return albumLabel
    }()

    lazy var playqueueView: UIView = UIView()

    lazy var controlsStackView: UIStackView = UIStackView()
    lazy var secondaryControlStackView: UIStackView = UIStackView()

    private lazy var shuffleButton: UIButton = {
        let shuffleButton = UIButton(type: .system)
        shuffleButton.setImage(controlImage(symbol: "shuffle", fallback: "iconShuffleLarge", pointSize: 16), for: .normal)
        shuffleButton.contentMode = .scaleAspectFit
        shuffleButton.imageView?.contentMode = .scaleAspectFit
        shuffleButton.tintColor = .white
        shuffleButton.addTarget(self, action: #selector(handleShuffleButton(_:)), for: .touchUpInside)
        shuffleButton.accessibilityLabel = NSLocalizedString("SHUFFLE", comment: "")
        shuffleButton.accessibilityHint = NSLocalizedString("SHUFFLE_HINT", comment: "")
        return shuffleButton
    }()

    private lazy var backwardButton: UIButton = {
        let backwardButton = UIButton(type: .system)
        backwardButton.setImage(controlImage(symbol: "gobackward", fallback: "iconSkipBack", pointSize: 18), for: .normal)
        backwardButton.contentMode = .scaleAspectFit
        backwardButton.imageView?.contentMode = .scaleAspectFit
        backwardButton.tintColor = .white
        backwardButton.addTarget(self, action: #selector(handleBackwardButton), for: .touchUpInside)
        backwardButton.accessibilityLabel = NSLocalizedString("BACKWARD_BUTTON", comment: "")
        backwardButton.accessibilityHint = NSLocalizedString("BACKWARD_HINT", comment: "")
        backwardButton.isHidden = true
        return backwardButton
    }()

    private lazy var previousButton: UIButton = {
        let previousButton = UIButton(type: .system)
        previousButton.setImage(controlImage(symbol: "backward.end.fill", fallback: "previous-media", pointSize: 19), for: .normal)
        previousButton.contentMode = .scaleAspectFit
        previousButton.imageView?.contentMode = .scaleAspectFit
        previousButton.tintColor = .white
        previousButton.addTarget(self, action: #selector(handlePreviousButton(_:)), for: .touchUpInside)
        previousButton.accessibilityLabel = NSLocalizedString("PREVIOUS_BUTTON", comment: "")
        previousButton.accessibilityHint = NSLocalizedString("PREVIOUS_HINT", comment: "")
        return previousButton
    }()
    
    private lazy var playbackSpeedButton: UIButton = {
        let playbackButton = UIButton(type: .system)
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressPlaybackSpeedButton(_:)))
        playbackButton.contentMode = .scaleAspectFit
        playbackButton.imageView?.contentMode = .scaleAspectFit
        playbackButton.tintColor = .white
        playbackButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        playbackButton.addTarget(self, action: #selector(handlePlaybackSpeedButton(_:)), for: .touchUpInside)
        longPressGestureRecognizer.minimumPressDuration = 0.5
        longPressGestureRecognizer.delaysTouchesBegan = true
        longPressGestureRecognizer.delegate = self
        playbackButton.addGestureRecognizer(longPressGestureRecognizer)
        return playbackButton
    }()

    private lazy var playButton: UIButton = {
        let playButton = UIButton(type: .system)
        playButton.setImage(controlImage(symbol: "play.fill", fallback: "iconPlay", pointSize: 26), for: .normal)
        playButton.contentMode = .scaleAspectFit
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(handlePlayButton(_:)), for: .touchUpInside)
        playButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        playButton.accessibilityHint = NSLocalizedString("PLAY_PAUSE_HINT", comment: "")
        return playButton
    }()

    private lazy var nextButton: UIButton = {
        let nextButton = UIButton(type: .system)
        nextButton.setImage(controlImage(symbol: "forward.end.fill", fallback: "next-media", pointSize: 19), for: .normal)
        nextButton.contentMode = .scaleAspectFit
        nextButton.imageView?.contentMode = .scaleAspectFit
        nextButton.tintColor = .white
        nextButton.addTarget(self, action: #selector(handleNextButton(_:)), for: .touchUpInside)
        nextButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON", comment: "")
        nextButton.accessibilityHint = NSLocalizedString("NEXT_HINT", comment: "")
        return nextButton
    }()

    private lazy var forwardButton: UIButton = {
        let forwardButton = UIButton(type: .system)
        forwardButton.setImage(controlImage(symbol: "goforward", fallback: "iconSkipForward", pointSize: 18), for: .normal)
        forwardButton.contentMode = .scaleAspectFit
        forwardButton.imageView?.contentMode = .scaleAspectFit
        forwardButton.tintColor = .white
        forwardButton.addTarget(self, action: #selector(handleForwardButton), for: .touchUpInside)
        forwardButton.accessibilityLabel = NSLocalizedString("FORWARD_BUTTON", comment: "")
        forwardButton.accessibilityHint = NSLocalizedString("FORWARD_HINT", comment: "")
        forwardButton.isHidden = true
        return forwardButton
    }()

    private lazy var repeatButton: UIButton = {
        let repeatButton = UIButton(type: .system)
        repeatButton.setImage(controlImage(symbol: "repeat", fallback: "iconRepeatLarge", pointSize: 16), for: .normal)
        repeatButton.contentMode = .scaleAspectFit
        repeatButton.imageView?.contentMode = .scaleAspectFit
        repeatButton.tintColor = .white
        repeatButton.addTarget(self, action: #selector(handleRepeatButton(_:)), for: .touchUpInside)
        repeatButton.accessibilityLabel = NSLocalizedString("REPEAT_MODE", comment: "")
        repeatButton.accessibilityHint = NSLocalizedString("REPEAT_HINT", comment: "")
        return repeatButton
    }()

    lazy var progressionView: UIView = UIView()

    private lazy var progressionViewHeightConstraint: NSLayoutConstraint = progressionView.heightAnchor.constraint(equalToConstant: 70)

    private lazy var albumLabelHeightConstraint: NSLayoutConstraint = albumLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: albumLabel.font.lineHeight)

    private lazy var secondaryControlStackViewHeightConstraint: NSLayoutConstraint = secondaryControlStackView.heightAnchor.constraint(equalToConstant: 30.0)

    private lazy var controlsStackViewMinSpacing: CGFloat = 25.0

    private var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

#if os(iOS)
    private var currentScreen: UIScreen? {
        guard let window = window else {
            return nil
        }

        if #available(iOS 13.0, *), let screen = window.windowScene?.screen {
            return screen
        }

        return window.screen
    }
#endif

    private var isCompactScreen: Bool {
#if os(iOS)
        return bounds.width <= DeviceDimensions.iPhone4sPortrait.rawValue
#else
        return false
#endif
    }

    // Portrait keeps a wide, iPad-like border on all regular-sized devices so
    // the artwork and slider line up with generous margins to the edges.
    private var portraitContentInset: CGFloat {
        return isCompactScreen ? 24.0 : 60.0
    }

    // Landscape margin: wide on iPad, tighter on the narrower iPhone panes.
    private var horizontalContentInset: CGFloat {
        if isPad {
            return 60.0
        }
        return isCompactScreen ? 10.0 : 24.0
    }

    private let minimumThumbnailSize: CGFloat = 80.0

    private lazy var thumbnailViewCenterYConstraint: NSLayoutConstraint = {
        let constraint = thumbnailView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        constraint.priority = .defaultHigh
        return constraint
    }()

    private lazy var landscapeRightLayoutGuide: UILayoutGuide = UILayoutGuide()

    private lazy var landscapeRightContentLayoutGuide: UILayoutGuide = UILayoutGuide()

    private var sharedConstraints: [NSLayoutConstraint] = []
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    private var isLandscapeLayout: Bool = false

    private var thumbnailImageViewLeadingConstraint: NSLayoutConstraint?
    private var thumbnailImageViewTrailingConstraint: NSLayoutConstraint?
    private var portraitThumbnailWidthCompactConstraint: NSLayoutConstraint?
    private var portraitThumbnailWidthRegularConstraint: NSLayoutConstraint?
    private var portraitProgressionLeadingConstraint: NSLayoutConstraint?
    private var portraitProgressionTrailingConstraint: NSLayoutConstraint?
    private var landscapeProgressionTopConstraint: NSLayoutConstraint?
    private var landscapeProgressionLeadingConstraint: NSLayoutConstraint?
    private var landscapeProgressionTrailingConstraint: NSLayoutConstraint?
    private var landscapeProgressionBottomConstraint: NSLayoutConstraint?

    weak var delegate: AudioPlayerViewDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLabels()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func setupViews() {
        setupBackgroundView()
        setupOverlayView()
        setupNavigationBarView()
        setupLandscapeLayoutGuide()
        setupThumbnailView()
        setupPlayqueueView()
        setupControlsStackView()
        setupProgressionView()

        NSLayoutConstraint.activate(sharedConstraints)
        NSLayoutConstraint.activate(portraitConstraints)
    }

    func setupNavigationBar(with view: MediaNavigationBar) {
        view.translatesAutoresizingMaskIntoConstraints = false

        navigationBarView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: navigationBarView.leadingAnchor),
            view.topAnchor.constraint(equalTo: navigationBarView.topAnchor),
            view.trailingAnchor.constraint(equalTo: navigationBarView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: navigationBarView.bottomAnchor)
        ])
    }

    func updateThumbnailImageView() {
        thumbnailImageView.image = delegate?.audioPlayerViewDelegateGetThumbnail(self)
        thumbnailImageView.clipsToBounds = true
    }
    
    func setupPlaybackSpeed() {
        let defaultPlaybackSpeed = delegate?.audioPlayerViewDelegateGetPlaybackSpeed(self)
        playbackSpeedButton.setTitle(PlaybackSpeedFormatter.string(forSpeed: defaultPlaybackSpeed ?? 1.00), for: .normal)
    }

    func setupBackgroundColor() {
        if #available(iOS 26.0, *) {
            backgroundImageView.image = thumbnailImageView.image
        } else {
            backgroundView.backgroundColor = thumbnailImageView.image?.averageColor()
        }
    }

    func setupLabels() {
        titleLabel.textColor = .white
        artistLabel.textColor = .white
        albumLabel.textColor = .white
    }

    func setupProgressView(with view: MediaScrubProgressBar) {
        view.translatesAutoresizingMaskIntoConstraints = false
        progressionView.addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: progressionView.bottomAnchor)
        ])
    }

    func setupExternalOutputView(with externalOutputView: UIView) {
        addSubview(externalOutputView)

        let constant: CGFloat = 320
        NSLayoutConstraint.activate([
            externalOutputView.heightAnchor.constraint(equalToConstant: constant),
            externalOutputView.widthAnchor.constraint(equalToConstant: constant),
            externalOutputView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            externalOutputView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
        ])
    }

    func setupSliders(with brightnessControlView: BrightnessControlView, and volumeControlView: VolumeControlView) {
        thumbnailView.addSubview(brightnessControlView)
        thumbnailView.addSubview(volumeControlView)

        setupCommonSliderConstraints(for: brightnessControlView)
        setupCommonSliderConstraints(for: volumeControlView)

        NSLayoutConstraint.activate([
            brightnessControlView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: 10),
            volumeControlView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -10)
        ])
    }

    func updateLabels(title: String?, artist: String?, album: String?, isQueueHidden: Bool) {
        if isQueueHidden {
            titleLabel.isHidden = false
            artistLabel.isHidden = false

            titleLabel.text = title
            titleLabel.accessibilityValue = title
            artistLabel.text = artist
            artistLabel.accessibilityValue = artist

            let hasAlbum: Bool = !(album?.isEmpty ?? true)
            albumLabel.isHidden = !hasAlbum
            albumLabel.text = album
            albumLabel.accessibilityValue = album
            updateAlbumLabelHeight()
        } else {
            titleLabel.isHidden = true
            artistLabel.isHidden = true
            albumLabel.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateContentInsets()
        updateAlbumLabelHeight()
    }

    private func updateContentInsets() {
        let portraitInset = portraitContentInset

        thumbnailImageViewLeadingConstraint?.constant = portraitInset
        thumbnailImageViewTrailingConstraint?.constant = -portraitInset
        portraitThumbnailWidthCompactConstraint?.constant = -2 * portraitInset
        portraitThumbnailWidthRegularConstraint?.constant = -2 * portraitInset
        portraitProgressionLeadingConstraint?.constant = portraitInset
        portraitProgressionTrailingConstraint?.constant = -portraitInset

        let landscapeInset = horizontalContentInset

        landscapeProgressionTopConstraint?.constant = landscapeInset
        landscapeProgressionLeadingConstraint?.constant = landscapeInset
        landscapeProgressionTrailingConstraint?.constant = -landscapeInset
        landscapeProgressionBottomConstraint?.constant = -landscapeInset

        updatePortraitThumbnailWidthConstraint()
    }

    private func updatePortraitThumbnailWidthConstraint() {
        guard let compactConstraint = portraitThumbnailWidthCompactConstraint,
              let regularConstraint = portraitThumbnailWidthRegularConstraint else {
            return
        }

        if isLandscapeLayout {
            compactConstraint.isActive = false
            return
        }

        let useCompact = isCompactScreen

        regularConstraint.isActive = !useCompact
        compactConstraint.isActive = useCompact
    }

    private func updateAlbumLabelHeight() {
        guard !albumLabel.isHidden, let text = albumLabel.text, !text.isEmpty,
              let font = albumLabel.font else {
            if albumLabelHeightConstraint.constant != 0 {
                albumLabelHeightConstraint.constant = 0
            }
            return
        }

        let width = albumLabel.bounds.width
        let target: CGFloat
        if width > 0 {
            let bounding = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                           options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                           attributes: [.font: font], context: nil)
            target = min(ceil(bounding.height), ceil(font.lineHeight * 3))
        } else {
            target = font.lineHeight
        }

        if abs(albumLabelHeightConstraint.constant - target) > 0.5 {
            albumLabelHeightConstraint.constant = target
            setNeedsLayout()
        }
    }

    private func controlImage(symbol: String, fallback: String, pointSize: CGFloat) -> UIImage? {
        if #available(iOS 26.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
            return UIImage(systemName: symbol, withConfiguration: configuration)
        }
        return UIImage(named: fallback)
    }

    func updatePlayButton(isPlaying: Bool) {
        let icon = controlImage(symbol: isPlaying ? "pause.fill" : "play.fill",
                                fallback: isPlaying ? "iconPause" : "iconPlay",
                                pointSize: 26)
        playButton.setImage(icon, for: .normal)
        updateArtworkScale(isPlaying: isPlaying)
    }

    private func updateArtworkScale(isPlaying: Bool) {
        let targetTransform: CGAffineTransform = isPlaying ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
        guard thumbnailImageView.transform != targetTransform else { return }

        UIView.animate(withDuration: 0.4, delay: 0,
                       usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
                       options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.thumbnailImageView.transform = targetTransform
        }
    }

    func updateShuffleRepeatState(shuffleEnabled: Bool, repeatMode: VLCRepeatMode) {
        var color = PresentationTheme.current.colors.orangeUI

        let shuffleIcon = controlImage(symbol: "shuffle",
                                       fallback: shuffleEnabled ? "iconShuffleOnLarge" : "iconShuffleLarge",
                                       pointSize: 16)
        shuffleButton.setImage(shuffleIcon, for: .normal)
        shuffleButton.tintColor = shuffleEnabled ? color : .white
        shuffleButton.accessibilityLabel = shuffleEnabled ? NSLocalizedString("SHUFFLE", comment: "") : NSLocalizedString("SHUFFLE_DISABLED", comment: "")
        shuffleButton.accessibilityHint = shuffleEnabled ? NSLocalizedString("SHUFFLE_HINT", comment: "") : NSLocalizedString("SHUFFLE_OFF_HINT", comment: "")

        var icon: UIImage?
        var accessibilityLabel: String
        var accessibilityHint: String
        switch repeatMode {
        case .doNotRepeat:
            icon = controlImage(symbol: "repeat", fallback: "iconRepeatLarge", pointSize: 16)
            color = .white
            accessibilityLabel = NSLocalizedString("MENU_REPEAT_DISABLED", comment: "")
            accessibilityHint = NSLocalizedString("DO_NOT_REPEAT_HINT", comment: "")
        case .repeatCurrentItem:
            icon = controlImage(symbol: "repeat.1", fallback: "iconRepeatOneOnLarge", pointSize: 16)
            accessibilityLabel = NSLocalizedString("MENU_REPEAT_SINGLE", comment: "")
            accessibilityHint = NSLocalizedString("REPEAT_HINT", comment: "")
        case .repeatAllItems:
            icon = controlImage(symbol: "repeat", fallback: "iconRepeatOnLarge", pointSize: 16)
            accessibilityLabel = NSLocalizedString("MENU_REPEAT_ALL", comment: "")
            accessibilityHint = NSLocalizedString("REPEAT_ALL_HINT", comment: "")
        @unknown default:
            assertionFailure("AudioPlayerView: unhandled case.")
            return
        }

        repeatButton.setImage(icon, for: .normal)
        repeatButton.tintColor = color
        repeatButton.accessibilityLabel = accessibilityLabel
        repeatButton.accessibilityHint = accessibilityHint
    }

    func setControlsEnabled(_ enabled: Bool) {
        shuffleButton.isEnabled = enabled
        shuffleButton.alpha = enabled ? 1.0 : 0.5

        backwardButton.isEnabled = enabled
        backwardButton.alpha = enabled ? 1.0 : 0.5

        previousButton.isEnabled = enabled
        previousButton.alpha = enabled ? 1.0 : 0.5

        playButton.isEnabled = enabled
        playButton.alpha = enabled ? 1.0 : 0.5

        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.5

        forwardButton.isEnabled = enabled
        forwardButton.alpha = enabled ? 1.0 : 0.5

        repeatButton.isEnabled = enabled
        repeatButton.alpha = enabled ? 1.0 : 0.5
        
        playbackSpeedButton.isEnabled = enabled
        playbackSpeedButton.alpha = enabled ? 1.0 : 0.5
    }

    func shouldEnableSeekButtons(_ enabled: Bool) {
        backwardButton.isEnabled = enabled
        backwardButton.isHidden = !enabled
        forwardButton.isEnabled = enabled
        forwardButton.isHidden = !enabled

        previousButton.isEnabled = !enabled
        previousButton.isHidden = enabled
        nextButton.isEnabled = !enabled
        nextButton.isHidden = enabled
    }

    func updateLayout(isLandscape: Bool) {
        isLandscapeLayout = isLandscape

        if isLandscape {
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
            progressionViewHeightConstraint.constant = 30
        } else {
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
            progressionViewHeightConstraint.constant = 70
        }

        updatePortraitThumbnailWidthConstraint()

        setNeedsLayout()
        layoutIfNeeded()
    }

    func shouldDisableControls(_ disable: Bool) {
        shuffleButton.isEnabled = !disable
        previousButton.isEnabled = !disable
        nextButton.isEnabled = !disable
        repeatButton.isEnabled = !disable
    }

    func shouldDisplaySecondaryStackView(_ display: Bool) {
        secondaryControlStackView.isHidden = !display
        secondaryControlStackViewHeightConstraint.constant = display ? 30 : 0
    }

    func applyCornerRadius() {
#if os(iOS)
        let cornerRadius = currentScreen?.displayCornerRadius ?? 0.0
#else
        let cornerRadius = 5.0
#endif
        overlayView.layer.cornerRadius = cornerRadius
        backgroundView.layer.cornerRadius = cornerRadius
    }

    func resetCornerRadius() {
        overlayView.layer.cornerRadius = 0.0
        backgroundView.layer.cornerRadius = 0.0
    }

    // MARK: - Private methods

    private func setupCommonSliderConstraints(for slider: UIView) {
        let heightConstraint = slider.heightAnchor.constraint(lessThanOrEqualToConstant: 170)
        let topConstraint = slider.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor)
        let bottomConstraint = slider.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -10)
        let yConstraint = slider.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor)

        heightConstraint.priority = .required
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh
        yConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            heightConstraint,
            topConstraint,
            bottomConstraint,
            slider.widthAnchor.constraint(equalToConstant: 50),
            yConstraint,
        ])
    }

    private func setupBackgroundView() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if #available(iOS 26.0, *) {
            blurView.translatesAutoresizingMaskIntoConstraints = false
            themeDidChange()

            backgroundView.addSubview(backgroundImageView)
            backgroundView.addSubview(blurView)
            NSLayoutConstraint.activate([
                backgroundImageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
                backgroundImageView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
                blurView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
                blurView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
                blurView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            ])
        }
    }

    @objc private func themeDidChange() {
        if #available(iOS 26.0, *) {
            let style: UIBlurEffect.Style = PresentationTheme.current.isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
            blurView.effect = UIBlurEffect(style: style)
        }
    }

    private func setupOverlayView() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .black.withAlphaComponent(0.4)

        addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            overlayView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            overlayView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
    }

    private func setupNavigationBarView() {
        let padding: CGFloat = 10.0
        navigationBarView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(navigationBarView)
        NSLayoutConstraint.activate([
            navigationBarView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: padding),
            navigationBarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: padding),
            navigationBarView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -padding)
        ])
    }

    private func setupLandscapeLayoutGuide() {
        addLayoutGuide(landscapeRightLayoutGuide)
        addLayoutGuide(landscapeRightContentLayoutGuide)

        landscapeConstraints.append(contentsOf: [
            landscapeRightLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: 8),
            landscapeRightLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            landscapeRightLayoutGuide.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor),
            landscapeRightLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupThumbnailView() {
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(thumbnailView)

        sharedConstraints.append(thumbnailView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor))

        portraitConstraints.append(contentsOf: [
            thumbnailView.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor, constant: 16),
            thumbnailView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])

        landscapeConstraints.append(contentsOf: [
            thumbnailView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: -8),
            thumbnailView.topAnchor.constraint(greaterThanOrEqualTo: navigationBarView.bottomAnchor, constant: 10),
            thumbnailView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            thumbnailViewCenterYConstraint,
        ])

        setupThumbnailSubviews()
    }

    private func setupThumbnailSubviews() {
        let padding: CGFloat = 20.0
        let labelSpacing: CGFloat = 8.0

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        albumLabel.translatesAutoresizingMaskIntoConstraints = false

        thumbnailView.addSubview(thumbnailImageView)
        addSubview(titleLabel)
        addSubview(artistLabel)
        addSubview(albumLabel)

        // Landscape: the artwork is a centered square filling the left column,
        // capped by the height available there. iPad has the room for it, so the
        // match is near-required; iPhone keeps it high-priority so it yields on
        // short panes. It cannot be required: a wide, short pane has no square
        // that satisfies both the column width and the height bounds.
        let landscapeThumbnailWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor,
                                                                                          constant: -2 * padding)
        landscapeThumbnailWidthConstraint.priority = isPad ? UILayoutPriority(999) : .defaultHigh

        // Portrait: the artwork is a square that fills the content width.
        // Regular screens have the vertical room, so the size is required;
        // compact screens keep it high-priority so it yields when too short.
        let compactWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor)
        compactWidthConstraint.priority = .defaultHigh
        portraitThumbnailWidthCompactConstraint = compactWidthConstraint

        let regularWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor)
        regularWidthConstraint.priority = .required
        portraitThumbnailWidthRegularConstraint = regularWidthConstraint

        // The width constraints yield when the pane is too short. Without a floor
        // they yield all the way to zero in a resizable window, hiding the artwork.
        let minimumWidthConstraint = thumbnailImageView.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumThumbnailSize)
        minimumWidthConstraint.priority = UILayoutPriority(999)

        let landscapeTitleLeading = titleLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor)
        let landscapeTitleTrailing = titleLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor)
        let landscapeArtistLeading = artistLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor)
        let landscapeArtistTrailing = artistLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor)
        let landscapeAlbumLeading = albumLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor)
        let landscapeAlbumTrailing = albumLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor)
        let landscapeAlbumBottom = albumLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -padding)

        sharedConstraints.append(contentsOf: [
            titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight),
            artistLabel.heightAnchor.constraint(equalToConstant: artistLabel.font.lineHeight),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: labelSpacing),
            albumLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: labelSpacing),
            albumLabelHeightConstraint,
            minimumWidthConstraint,
        ])

        let thumbnailImageViewLeading = thumbnailImageView.leadingAnchor.constraint(greaterThanOrEqualTo: thumbnailView.leadingAnchor)
        let thumbnailImageViewTrailing = thumbnailImageView.trailingAnchor.constraint(lessThanOrEqualTo: thumbnailView.trailingAnchor)
        thumbnailImageViewLeadingConstraint = thumbnailImageViewLeading
        thumbnailImageViewTrailingConstraint = thumbnailImageViewTrailing

        portraitConstraints.append(contentsOf: [
            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: padding),
            thumbnailImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            thumbnailImageViewLeading,
            thumbnailImageViewTrailing,
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor),
            regularWidthConstraint,

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: padding),
            titleLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),

            artistLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            artistLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),

            albumLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            albumLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            albumLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),
            albumLabel.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -padding),
        ])

        landscapeConstraints.append(contentsOf: [
            thumbnailImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            thumbnailImageView.leadingAnchor.constraint(greaterThanOrEqualTo: thumbnailView.leadingAnchor, constant: padding),
            thumbnailImageView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailView.topAnchor, constant: padding),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor),
            landscapeThumbnailWidthConstraint,

            landscapeRightContentLayoutGuide.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            landscapeRightContentLayoutGuide.bottomAnchor.constraint(equalTo: progressionView.bottomAnchor),
            landscapeRightContentLayoutGuide.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
            artistLabel.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
            albumLabel.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
            landscapeAlbumBottom,
            landscapeTitleLeading,
            landscapeTitleTrailing,
            landscapeArtistLeading,
            landscapeArtistTrailing,
            landscapeAlbumLeading,
            landscapeAlbumTrailing,
        ])
    }

    private func setupPlayqueueView() {
        playqueueView.translatesAutoresizingMaskIntoConstraints = false
        playqueueView.isHidden = true

        addSubview(playqueueView)
        NSLayoutConstraint.activate([
            playqueueView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            playqueueView.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            playqueueView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor),
            playqueueView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
            playqueueView.heightAnchor.constraint(equalTo: thumbnailView.heightAnchor, multiplier: 1)
        ])
    }

    private func setupControlsStackView() {
        let topPadding: CGFloat = 20.0
        [controlsStackView, secondaryControlStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.alignment = .fill
            $0.distribution = .equalCentering

            addSubview($0)
        }

        controlsStackView.spacing = controlsStackViewMinSpacing

        let controlsStackViewLeading = controlsStackView.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor)
        controlsStackViewLeading.priority = .defaultHigh
        let controlsStackViewTrailing = controlsStackView.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor)
        controlsStackViewTrailing.priority = .defaultHigh

        sharedConstraints.append(contentsOf: [
            controlsStackView.heightAnchor.constraint(equalToConstant: 50.0),
            controlsStackViewLeading,
            controlsStackViewTrailing,
            secondaryControlStackView.topAnchor.constraint(equalTo: controlsStackView.bottomAnchor, constant: topPadding/4),
            secondaryControlStackViewHeightConstraint
        ])

        let portraitSecondaryControlBottom = secondaryControlStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        portraitSecondaryControlBottom.priority = .defaultHigh

        portraitConstraints.append(contentsOf: [
            controlsStackView.topAnchor.constraint(equalTo: progressionView.bottomAnchor, constant: topPadding),
            secondaryControlStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            portraitSecondaryControlBottom,
        ])

        if isPad {
            let controlsWidth = controlsStackView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, multiplier: 0.5)
            portraitConstraints.append(contentsOf: [
                controlsStackView.centerXAnchor.constraint(equalTo: progressionView.centerXAnchor),
                controlsWidth,
            ])
        }

        landscapeConstraints.append(contentsOf: [
            secondaryControlStackView.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
        ])

        controlsStackView.addArrangedSubview(shuffleButton)
        controlsStackView.addArrangedSubview(backwardButton)
        controlsStackView.addArrangedSubview(previousButton)
        controlsStackView.addArrangedSubview(playButton)
        controlsStackView.addArrangedSubview(nextButton)
        controlsStackView.addArrangedSubview(forwardButton)
        controlsStackView.addArrangedSubview(repeatButton)
        
        secondaryControlStackView.addArrangedSubview(playbackSpeedButton)

        let displaySecondaryStackView: Bool = UserDefaults.standard.bool(forKey: kVLCPlayerShowPlaybackSpeedShortcut)
        secondaryControlStackView.isHidden = !displaySecondaryStackView
        secondaryControlStackViewHeightConstraint.constant = displaySecondaryStackView ? 30 : 0
    }

    private func setupProgressionView() {
        progressionView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressionView)

        sharedConstraints.append(progressionViewHeightConstraint)

        let portraitProgressionLeading = progressionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor)
        let portraitProgressionTrailing = progressionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        portraitProgressionLeadingConstraint = portraitProgressionLeading
        portraitProgressionTrailingConstraint = portraitProgressionTrailing

        portraitConstraints.append(contentsOf: [
            progressionView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailView.bottomAnchor, constant: 16),
            portraitProgressionLeading,
            portraitProgressionTrailing,
        ])

        let landscapeProgressionTop = progressionView.topAnchor.constraint(equalTo: secondaryControlStackView.bottomAnchor)
        let landscapeProgressionLeading = progressionView.leadingAnchor.constraint(equalTo: landscapeRightLayoutGuide.leadingAnchor)
        let landscapeProgressionTrailing = progressionView.trailingAnchor.constraint(equalTo: landscapeRightLayoutGuide.trailingAnchor)
        let landscapeProgressionBottom = progressionView.bottomAnchor.constraint(lessThanOrEqualTo: landscapeRightLayoutGuide.bottomAnchor)
        landscapeProgressionBottom.priority = .defaultHigh

        landscapeProgressionTopConstraint = landscapeProgressionTop
        landscapeProgressionLeadingConstraint = landscapeProgressionLeading
        landscapeProgressionTrailingConstraint = landscapeProgressionTrailing
        landscapeProgressionBottomConstraint = landscapeProgressionBottom

        landscapeConstraints.append(contentsOf: [
            landscapeProgressionTop,
            landscapeProgressionLeading,
            landscapeProgressionTrailing,
            landscapeProgressionBottom,
        ])
    }

    // MARK: - Buttons handlers

    @objc func handleShuffleButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapShuffleButton(self)
    }

    @objc func handleBackwardButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapBackwardButton(self)
    }

    @objc func handlePreviousButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPreviousButton(self)
    }

    @objc func handlePlayButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPlayButton(self)
    }

    @objc func handleNextButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapNextButton(self)
    }

    @objc func handleForwardButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapForwardButton(self)
    }

    @objc func handleRepeatButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapRepeatButton(self)
    }
    
    @objc func handlePlaybackSpeedButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPlaybackSpeedButton(self)
    }
    
    @objc func handleLongPressPlaybackSpeedButton(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.audioPlayerViewDelegateDidLongPressPlaybackSpeedButton(self)
        }
    }
}
