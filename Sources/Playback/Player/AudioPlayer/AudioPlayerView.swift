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

    private lazy var overlayView: UIView = UIView()

    lazy var navigationBarView: UIView = UIView()

    lazy var thumbnailView: UIView = UIView()

    lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFit
        return thumbnailImageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: 17.0)
        titleLabel.accessibilityLabel = NSLocalizedString("TITLE", comment: "")
        return titleLabel
    }()

    private lazy var artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 16.0)
        artistLabel.accessibilityLabel = NSLocalizedString("ARTIST", comment: "")
        return artistLabel
    }()

    lazy var playqueueView: UIView = UIView()

    lazy var controlsStackView: UIStackView = UIStackView()
    lazy var secondaryControlStackView: UIStackView = UIStackView()

    private lazy var shuffleButton: UIButton = {
        let shuffleButton = UIButton(type: .system)
        shuffleButton.setImage(UIImage(named: "iconShuffleLarge"), for: .normal)
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
        backwardButton.setImage(UIImage(named: "iconSkipBack"), for: .normal)
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
        previousButton.setImage(UIImage(named: "previous-media"), for: .normal)
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
        playButton.setImage(UIImage(named: "iconPlay"), for: .normal)
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
        nextButton.setImage(UIImage(named: "next-media"), for: .normal)
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
        forwardButton.setImage(UIImage(named: "iconSkipForward"), for: .normal)
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
        repeatButton.setImage(UIImage(named: "iconRepeatLarge"), for: .normal)
        repeatButton.contentMode = .scaleAspectFit
        repeatButton.imageView?.contentMode = .scaleAspectFit
        repeatButton.tintColor = .white
        repeatButton.addTarget(self, action: #selector(handleRepeatButton(_:)), for: .touchUpInside)
        repeatButton.accessibilityLabel = NSLocalizedString("REPEAT_MODE", comment: "")
        repeatButton.accessibilityHint = NSLocalizedString("REPEAT_HINT", comment: "")
        return repeatButton
    }()

    lazy var progressionView: UIView = UIView()

    private lazy var progressionViewBottomConstant: CGFloat = {
#if os(iOS)
        let isSmallerScreen: Bool = UIScreen.main.bounds.width <= DeviceDimensions.iPhone4sPortrait.rawValue
        return isSmallerScreen ? 40 : 60
#else
        return 60
#endif
    }()

    private lazy var progressionViewBottomConstraint: NSLayoutConstraint = progressionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -progressionViewBottomConstant)

    private lazy var progressionViewHeightConstraint: NSLayoutConstraint = progressionView.heightAnchor.constraint(equalToConstant: 70)

    private lazy var thumbnailViewTopConstraint: NSLayoutConstraint = thumbnailView.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor, constant: 35)

    private lazy var controlsStackViewMinSpacing: CGFloat = 25.0
    private lazy var controlsStackViewMaxSpacing: CGFloat = 50.0

    private lazy var thumbnailViewCenterYConstraint: NSLayoutConstraint = {
        let constraint = thumbnailView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        constraint.priority = .defaultHigh
        return constraint
    }()

    private lazy var landscapeRightLayoutGuide: UILayoutGuide = UILayoutGuide()

    private var sharedConstraints: [NSLayoutConstraint] = []
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    weak var delegate: AudioPlayerViewDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLabels()
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
        backgroundView.backgroundColor = thumbnailImageView.image?.averageColor()
    }

    func setupLabels() {
        titleLabel.textColor = .white
        artistLabel.textColor = .white
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

    func updateLabels(title: String?, artist: String?, isQueueHidden: Bool) {
        if isQueueHidden {
            titleLabel.isHidden = false
            artistLabel.isHidden = false

            titleLabel.text = title
            titleLabel.accessibilityValue = title
            artistLabel.text = artist
            artistLabel.accessibilityValue = artist
        } else {
            titleLabel.isHidden = true
            artistLabel.isHidden = true
        }
    }

    func updatePlayButton(isPlaying: Bool) {
        let icon: UIImage? = isPlaying ? UIImage(named: "iconPause") : UIImage(named: "iconPlay")
        playButton.setImage(icon, for: .normal)
    }

    func updateShuffleRepeatState(shuffleEnabled: Bool, repeatMode: VLCRepeatMode) {
        var color = PresentationTheme.current.colors.orangeUI

        let shuffleIcon = shuffleEnabled ? UIImage(named: "iconShuffleOnLarge") : UIImage(named: "iconShuffleLarge")
        shuffleButton.setImage(shuffleIcon, for: .normal)
        shuffleButton.tintColor = shuffleEnabled ? color : .white
        shuffleButton.accessibilityLabel = shuffleEnabled ? NSLocalizedString("SHUFFLE", comment: "") : NSLocalizedString("SHUFFLE_DISABLED", comment: "")
        shuffleButton.accessibilityHint = shuffleEnabled ? NSLocalizedString("SHUFFLE_HINT", comment: "") : NSLocalizedString("SHUFFLE_OFF_HINT", comment: "")

        var icon: UIImage?
        var accessibilityLabel: String
        var accessibilityHint: String
        switch repeatMode {
        case .doNotRepeat:
            icon = UIImage(named: "iconRepeatLarge")
            color = .white
            accessibilityLabel = NSLocalizedString("MENU_REPEAT_DISABLED", comment: "")
            accessibilityHint = NSLocalizedString("DO_NOT_REPEAT_HINT", comment: "")
        case .repeatCurrentItem:
            icon = UIImage(named: "iconRepeatOneOnLarge")
            accessibilityLabel = NSLocalizedString("MENU_REPEAT_SINGLE", comment: "")
            accessibilityHint = NSLocalizedString("REPEAT_HINT", comment: "")
        case .repeatAllItems:
            icon = UIImage(named: "iconRepeatOnLarge")
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

    func updateConstraints(for orientation: UIDeviceOrientation) {
#if os(iOS)
        let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape: Bool = orientation.isLandscape
        let spacingMultiplier: CGFloat = isPad ? 2 : 1
#else
        let isLandscape: Bool = true
        let spacingMultiplier: CGFloat = 2
#endif

        if isLandscape {
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
            progressionViewHeightConstraint.constant = 30
            controlsStackView.spacing = controlsStackViewMaxSpacing * spacingMultiplier
        } else {
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
            thumbnailViewTopConstraint.constant = 35
            progressionViewBottomConstraint.constant = -progressionViewBottomConstant
            progressionViewHeightConstraint.constant = 70
            controlsStackView.spacing = controlsStackViewMinSpacing * spacingMultiplier
        }

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
    }

    func applyCornerRadius() {
#if os(iOS)
        var cornerRadius = UIScreen.main.displayCornerRadius
#else
        var cornerRadius = 5.0
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
            thumbnailViewTopConstraint,
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
        let thumbnailImageViewEdgesPadding: CGFloat = 40.0

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.translatesAutoresizingMaskIntoConstraints = false

        thumbnailView.addSubview(thumbnailImageView)
        addSubview(titleLabel)
        addSubview(artistLabel)

        let thumbnailViewHeightConstraint = thumbnailView.heightAnchor.constraint(equalToConstant: thumbnailImageView.frame.height + titleLabel.font.lineHeight + artistLabel.font.lineHeight)
        thumbnailViewHeightConstraint.priority = .defaultLow

        // Landscape: the artwork fills the left pane as a large centered square,
        // growing up to the pane's width and height.
        let landscapeThumbnailWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor, constant: -2 * padding)
        landscapeThumbnailWidthConstraint.priority = .defaultHigh
        let landscapeThumbnailHeightConstraint = thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailView.heightAnchor, constant: -2 * padding)
        landscapeThumbnailHeightConstraint.priority = .defaultHigh

        let landscapeTitleLeading = titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: landscapeRightLayoutGuide.leadingAnchor, constant: padding)
        let landscapeTitleTrailing = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: landscapeRightLayoutGuide.trailingAnchor, constant: -padding)
        let landscapeArtistLeading = artistLabel.leadingAnchor.constraint(greaterThanOrEqualTo: landscapeRightLayoutGuide.leadingAnchor, constant: padding)
        let landscapeArtistTrailing = artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: landscapeRightLayoutGuide.trailingAnchor, constant: -padding)

        sharedConstraints.append(contentsOf: [
            titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight),
            artistLabel.heightAnchor.constraint(equalToConstant: artistLabel.font.lineHeight),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            thumbnailViewHeightConstraint
        ])

        portraitConstraints.append(contentsOf: [
            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: padding),
            thumbnailImageView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: thumbnailImageViewEdgesPadding),
            thumbnailImageView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -thumbnailImageViewEdgesPadding),

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: padding),
            titleLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -padding),

            artistLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            artistLabel.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: padding),
            artistLabel.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -padding),
            artistLabel.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -padding),
        ])

        landscapeConstraints.append(contentsOf: [
            thumbnailImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            thumbnailImageView.leadingAnchor.constraint(greaterThanOrEqualTo: thumbnailView.leadingAnchor, constant: padding),
            thumbnailImageView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailView.topAnchor, constant: padding),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor),
            landscapeThumbnailWidthConstraint,
            landscapeThumbnailHeightConstraint,

            titleLabel.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
            artistLabel.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
            artistLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -padding),
            landscapeTitleLeading,
            landscapeTitleTrailing,
            landscapeArtistLeading,
            landscapeArtistTrailing,
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
        
        sharedConstraints.append(contentsOf: [
            controlsStackView.heightAnchor.constraint(equalToConstant: 50.0),
            secondaryControlStackView.topAnchor.constraint(equalTo: controlsStackView.bottomAnchor, constant: topPadding/4),
            secondaryControlStackView.heightAnchor.constraint(equalToConstant: 30.0)
        ])

        portraitConstraints.append(contentsOf: [
            controlsStackView.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: topPadding),
            controlsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            secondaryControlStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        landscapeConstraints.append(contentsOf: [
            controlsStackView.centerYAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerYAnchor),
            controlsStackView.centerXAnchor.constraint(equalTo: landscapeRightLayoutGuide.centerXAnchor),
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
    }

    private func setupProgressionView() {
#if os(iOS)
        let isSmallerScreen: Bool = UIScreen.main.bounds.width <= DeviceDimensions.iPhone4sPortrait.rawValue
        let padding: CGFloat = isSmallerScreen ? 10.0 : 25.0
#else
        let padding: CGFloat = 25.0
#endif

        progressionView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressionView)

        sharedConstraints.append(contentsOf: [
            progressionView.topAnchor.constraint(equalTo: secondaryControlStackView.bottomAnchor, constant: padding),
            progressionViewHeightConstraint
        ])

        portraitConstraints.append(contentsOf: [
            progressionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: padding),
            progressionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            progressionViewBottomConstraint,
        ])

        let landscapeProgressionBottomConstraint = progressionView.bottomAnchor.constraint(lessThanOrEqualTo: landscapeRightLayoutGuide.bottomAnchor, constant: -padding)
        landscapeProgressionBottomConstraint.priority = .defaultHigh

        landscapeConstraints.append(contentsOf: [
            progressionView.leadingAnchor.constraint(equalTo: landscapeRightLayoutGuide.leadingAnchor, constant: padding),
            progressionView.trailingAnchor.constraint(equalTo: landscapeRightLayoutGuide.trailingAnchor, constant: -padding),
            landscapeProgressionBottomConstraint,
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
