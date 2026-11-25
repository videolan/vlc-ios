/*****************************************************************************
 * AudioPlayerView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022-2026 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol AudioPlayerViewDelegate: AnyObject {
    func audioPlayerViewDelegateGetThumbnail(_ audioPlayerView: AudioPlayerView) -> UIImage?
    func audioPlayerViewDelegateGetPlaceholderName(_ audioPlayerView: AudioPlayerView) -> String?
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

    lazy var thumbnailImageView: VLCArtworkImageView = {
        let thumbnailImageView = VLCArtworkImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 14.0
        thumbnailImageView.layer.borderWidth = 0.5
        thumbnailImageView.layer.borderColor = PresentationTheme.currentExcludingWhite.colors.overlayHairlineColor.cgColor
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
        titleLabel.font = .boldSystemFont(ofSize: 22.0)
        titleLabel.numberOfLines = 2
        titleLabel.accessibilityLabel = NSLocalizedString("TITLE", comment: "")
        return titleLabel
    }()

    private lazy var artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 17.0)
        artistLabel.numberOfLines = 2
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
        shuffleButton.applyOverlayToggleStyle(image: controlImage(symbol: "shuffle", fallback: "iconShuffleLarge", pointSize: 16),
                                              isActive: false, cornerRadius: toggleButtonSize / 2)
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
        var configuration = UIButton.Configuration.plain()
        configuration.image = controlImage(symbol: "play.fill", fallback: "iconPlay", pointSize: 26)
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.background.customView = VideoControlBackgroundView()
        let playButton = UIButton(configuration: configuration)
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
        repeatButton.applyOverlayToggleStyle(image: controlImage(symbol: "repeat", fallback: "iconRepeatLarge", pointSize: 16),
                                             isActive: false, cornerRadius: toggleButtonSize / 2)
        repeatButton.addTarget(self, action: #selector(handleRepeatButton(_:)), for: .touchUpInside)
        repeatButton.accessibilityLabel = NSLocalizedString("REPEAT_MODE", comment: "")
        repeatButton.accessibilityHint = NSLocalizedString("REPEAT_HINT", comment: "")
        return repeatButton
    }()

    lazy var progressionView: UIView = UIView()

    private lazy var progressionViewHeightConstraint: NSLayoutConstraint = progressionView.heightAnchor.constraint(equalToConstant: 70)

    private lazy var titleLabelHeightConstraint: NSLayoutConstraint = titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: titleLabel.font.lineHeight)

    private lazy var artistLabelHeightConstraint: NSLayoutConstraint = artistLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: artistLabel.font.lineHeight)

    private lazy var albumLabelHeightConstraint: NSLayoutConstraint = albumLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: albumLabel.font.lineHeight)

    private lazy var secondaryControlStackViewHeightConstraint: NSLayoutConstraint = secondaryControlStackView.heightAnchor.constraint(equalToConstant: 30.0)

    private lazy var controlsStackViewMinSpacing: CGFloat = 0.0
    private let transportPreferredSpacing: CGFloat = 8.0

    private let playButtonSize: CGFloat = 72.0
    private let compactPlayButtonSize: CGFloat = 56.0
    private let sideButtonSize: CGFloat = 56.0
    private let compactSideButtonSize: CGFloat = 44.0
    private let toggleButtonSize: CGFloat = 44.0
    private let transportMaximumWidth: CGFloat = 380.0

    private lazy var playButtonWidthConstraint: NSLayoutConstraint = playButton.widthAnchor.constraint(equalToConstant: playButtonSize)

    private lazy var sideButtonWidthConstraints: [NSLayoutConstraint] = [backwardButton, previousButton, nextButton, forwardButton].map {
        $0.widthAnchor.constraint(equalToConstant: sideButtonSize)
    }

    private var isShuffleEnabled = false
    private var currentRepeatMode: VLCRepeatMode = .doNotRepeat

    private var isCompactScreen: Bool {
#if os(iOS)
        return bounds.width <= LayoutWidth.narrowest.rawValue
#else
        return false
#endif
    }

    // Portrait keeps a wide, iPad-like border on all regular-sized devices so
    // the artwork and slider line up with generous margins to the edges.
    private var portraitContentInset: CGFloat {
        return isCompactScreen ? 24.0 : 60.0
    }

    private var portraitVerticalSpacing: CGFloat {
        return isCompactScreen ? 10.0 : 20.0
    }

    // Landscape margin: wide when both size classes are regular, tighter on
    // the narrower panes.
    private var horizontalContentInset: CGFloat {
        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            return 60.0
        }
        return isCompactScreen ? 10.0 : 24.0
    }

    private let minimumThumbnailSize: CGFloat = 80.0

    private let navigationBarPadding: CGFloat = 10.0

    private(set) lazy var navigationBarLayout = MediaNavigationBarLayout(
        navigationBar: navigationBarView,
        container: self,
        leftAnchor: safeAreaLayoutGuide.leftAnchor,
        rightAnchor: safeAreaLayoutGuide.rightAnchor,
        horizontalInset: navigationBarPadding,
        topPadding: navigationBarPadding)

    private lazy var thumbnailViewCenterYConstraint: NSLayoutConstraint = {
        let constraint = thumbnailView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        constraint.priority = .defaultHigh
        return constraint
    }()

    private lazy var centeredLayoutGuide: UILayoutGuide = UILayoutGuide()

    private let landscapeColumnSpacing: CGFloat = 8.0

    private lazy var landscapeDividerLayoutGuide: UILayoutGuide = UILayoutGuide()

    private lazy var landscapeDividerCenterXConstraint: NSLayoutConstraint = {
        landscapeDividerLayoutGuide.centerXAnchor.constraint(equalTo: centerXAnchor)
    }()

    private lazy var landscapeDividerWidthConstraint: NSLayoutConstraint = {
        landscapeDividerLayoutGuide.widthAnchor.constraint(equalToConstant: 2 * landscapeColumnSpacing)
    }()

    private lazy var landscapeRightLayoutGuide: UILayoutGuide = UILayoutGuide()

    private lazy var landscapeRightContentLayoutGuide: UILayoutGuide = UILayoutGuide()

    private var sharedConstraints: [NSLayoutConstraint] = []
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var unfoldedPortraitConstraints: [NSLayoutConstraint] = []
    private var tabletopConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []
    private var activeLayoutConstraints: [NSLayoutConstraint] = []

    private var isLandscapeLayout: Bool = false
    private var isTabletopLayout = false

    private lazy var tabletopThumbnailBottomConstraint: NSLayoutConstraint = {
        thumbnailView.bottomAnchor.constraint(equalTo: topAnchor)
    }()

    private var centeredLayoutGuideLeadingConstraint: NSLayoutConstraint?
    private var centeredLayoutGuideTrailingConstraint: NSLayoutConstraint?
    private var thumbnailImageViewLeadingConstraint: NSLayoutConstraint?
    private var thumbnailImageViewTrailingConstraint: NSLayoutConstraint?
    private var portraitThumbnailWidthConstraint: NSLayoutConstraint?
    private var portraitThumbnailTopConstraint: NSLayoutConstraint?
    private var portraitAlbumBottomConstraint: NSLayoutConstraint?
    private var portraitControlsTopConstraint: NSLayoutConstraint?
    private var portraitProgressionLeadingConstraint: NSLayoutConstraint?
    private var portraitProgressionTrailingConstraint: NSLayoutConstraint?
    private var landscapeProgressionTopConstraint: NSLayoutConstraint?
    private var landscapeProgressionLeadingConstraint: NSLayoutConstraint?
    private var landscapeProgressionTrailingConstraint: NSLayoutConstraint?
    private var landscapeProgressionBottomConstraint: NSLayoutConstraint?
    private var landscapeThumbnailWidthConstraint: NSLayoutConstraint?

    weak var delegate: AudioPlayerViewDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLabels()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateToggleButtonStyles),
                                               name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateToggleButtonStyles),
                                               name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func setupViews() {
        setupBackgroundView()
        setupOverlayView()
        setupNavigationBarView()
        setupCenteredLayoutGuide()
        setupLandscapeLayoutGuide()
        setupThumbnailView()
        setupPlayqueueView()
        setupControlsStackView()
        setupProgressionView()

        NSLayoutConstraint.activate(sharedConstraints)
        updateLayoutConstraints()
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
        thumbnailImageView.setImage(delegate?.audioPlayerViewDelegateGetThumbnail(self),
                                    placeholderName: delegate?.audioPlayerViewDelegateGetPlaceholderName(self))
        thumbnailImageView.clipsToBounds = true
    }
    
    func updatePlaybackSpeedButton(with playbackSpeed: Float) {
        playbackSpeedButton.setTitle(PlaybackSpeedFormatter.string(forSpeed: playbackSpeed), for: .normal)
    }

    func setupBackgroundColor() {
        let image = thumbnailImageView.image
        let placeholderColor = image == nil ? thumbnailImageView.placeholderName.map {
            VLCPlaceholderArtwork.backgroundColor(forName: $0)
        } : nil

        if #available(iOS 26.0, *) {
            backgroundImageView.image = image
            backgroundImageView.backgroundColor = placeholderColor
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let averageColor = placeholderColor ?? image?.averageColor()

            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.backgroundView.backgroundColor = averageColor
                }
            }
        }
    }

    func setupLabels() {
        titleLabel.textColor = .white
        artistLabel.textColor = .white
        albumLabel.textColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
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
            externalOutputView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            externalOutputView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
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
        } else {
            titleLabel.isHidden = true
            artistLabel.isHidden = true
            albumLabel.isHidden = true
        }

        updateLabelHeights()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateContentInsets()
        updateLabelHeights()
        updateTransportButtonSizes()
    }

    private func updateContentInsets() {
        let centeredInset = isLandscapeLayout
            ? (safeAreaInsets.left + safeAreaInsets.right) / 2
            : min(safeAreaInsets.left, safeAreaInsets.right)

        centeredLayoutGuideLeadingConstraint?.constant = centeredInset
        centeredLayoutGuideTrailingConstraint?.constant = -centeredInset

        let portraitInset = portraitContentInset

        thumbnailImageViewLeadingConstraint?.constant = portraitInset
        thumbnailImageViewTrailingConstraint?.constant = -portraitInset
        portraitThumbnailWidthConstraint?.constant = -2 * portraitInset
        portraitProgressionLeadingConstraint?.constant = portraitInset
        portraitProgressionTrailingConstraint?.constant = -portraitInset

        let portraitSpacing = portraitVerticalSpacing

        portraitThumbnailTopConstraint?.constant = portraitSpacing
        portraitAlbumBottomConstraint?.constant = -portraitSpacing
        portraitControlsTopConstraint?.constant = portraitSpacing

        let landscapeInset = horizontalContentInset

        landscapeProgressionTopConstraint?.constant = landscapeInset
        landscapeProgressionLeadingConstraint?.constant = landscapeInset
        landscapeProgressionTrailingConstraint?.constant = -landscapeInset
        landscapeProgressionBottomConstraint?.constant = -landscapeInset

        let landscapeThumbnailPriority: UILayoutPriority = traitCollection.verticalSizeClass == .regular ? UILayoutPriority(999) : .defaultHigh
        if let constraint = landscapeThumbnailWidthConstraint, constraint.priority != landscapeThumbnailPriority {
            constraint.priority = landscapeThumbnailPriority
        }
    }

    private func updateTransportButtonSizes() {
        let availableWidth = progressionView.bounds.width
        guard availableWidth > 0 else {
            return
        }

        let playSize: CGFloat
        let sideSize: CGFloat
        if availableWidth >= transportWidth(playSize: playButtonSize, sideSize: sideButtonSize) {
            playSize = playButtonSize
            sideSize = sideButtonSize
        } else if availableWidth >= transportWidth(playSize: compactPlayButtonSize, sideSize: compactSideButtonSize) {
            playSize = compactPlayButtonSize
            sideSize = compactSideButtonSize
        } else {
            playSize = compactSideButtonSize
            sideSize = compactSideButtonSize
        }

        guard playButtonWidthConstraint.constant != playSize else {
            return
        }

        playButtonWidthConstraint.constant = playSize
        sideButtonWidthConstraints.forEach { $0.constant = sideSize }
    }

    private func transportWidth(playSize: CGFloat, sideSize: CGFloat) -> CGFloat {
        return playSize + 2 * sideSize + 2 * toggleButtonSize + 4 * transportPreferredSpacing
    }

    private func updateLabelHeights() {
        updateHeight(of: titleLabel, constraint: titleLabelHeightConstraint, maximumLines: 2)
        updateHeight(of: artistLabel, constraint: artistLabelHeightConstraint, maximumLines: 2)
        updateHeight(of: albumLabel, constraint: albumLabelHeightConstraint, maximumLines: 3)
    }

    private func updateHeight(of label: UILabel, constraint: NSLayoutConstraint, maximumLines: Int) {
        guard !label.isHidden, let text = label.text, !text.isEmpty,
              let font = label.font else {
            if constraint.constant != 0 {
                constraint.constant = 0
            }
            return
        }

        let width = label.bounds.width
        let target: CGFloat
        if width > 0 {
            let bounding = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                           options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                           attributes: [.font: font], context: nil)
            target = min(ceil(bounding.height), ceil(font.lineHeight * CGFloat(maximumLines)))
        } else {
            target = font.lineHeight
        }

        if abs(constraint.constant - target) > 0.5 {
            constraint.constant = target
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
        playButton.configuration?.image = icon
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
        isShuffleEnabled = shuffleEnabled
        currentRepeatMode = repeatMode

        let shuffleIcon = controlImage(symbol: "shuffle",
                                       fallback: shuffleEnabled ? "iconShuffleOnLarge" : "iconShuffleLarge",
                                       pointSize: 16)
        shuffleButton.applyOverlayToggleStyle(image: shuffleIcon, isActive: shuffleEnabled, cornerRadius: toggleButtonSize / 2)
        shuffleButton.accessibilityLabel = shuffleEnabled ? NSLocalizedString("SHUFFLE", comment: "") : NSLocalizedString("SHUFFLE_DISABLED", comment: "")
        shuffleButton.accessibilityHint = shuffleEnabled ? NSLocalizedString("SHUFFLE_HINT", comment: "") : NSLocalizedString("SHUFFLE_OFF_HINT", comment: "")

        var icon: UIImage?
        var accessibilityLabel: String
        var accessibilityHint: String
        switch repeatMode {
        case .doNotRepeat:
            icon = controlImage(symbol: "repeat", fallback: "iconRepeatLarge", pointSize: 16)
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

        repeatButton.applyOverlayToggleStyle(image: icon, isActive: repeatMode != .doNotRepeat, cornerRadius: toggleButtonSize / 2)
        repeatButton.accessibilityLabel = accessibilityLabel
        repeatButton.accessibilityHint = accessibilityHint
    }

    func setControlsEnabled(_ enabled: Bool) {
        shuffleButton.isEnabled = enabled

        backwardButton.isEnabled = enabled
        backwardButton.alpha = enabled ? 1.0 : 0.5

        previousButton.isEnabled = enabled
        previousButton.alpha = enabled ? 1.0 : 0.5

        playButton.isEnabled = enabled

        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.5

        forwardButton.isEnabled = enabled
        forwardButton.alpha = enabled ? 1.0 : 0.5

        repeatButton.isEnabled = enabled
        
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
        progressionViewHeightConstraint.constant = isLandscape ? 30 : 70
        updateLayoutConstraints()

        setNeedsLayout()
        layoutIfNeeded()
    }

    func updateTabletopFold(_ fold: CGRect?) {
        if let fold, tabletopThumbnailBottomConstraint.constant != fold.minY {
            tabletopThumbnailBottomConstraint.constant = fold.minY
        }

        let isTabletop = fold != nil
        guard isTabletop != isTabletopLayout else {
            return
        }

        isTabletopLayout = isTabletop
        updateLayoutConstraints()
    }

    func updateBookFold(_ fold: CGRect?) {
        let centerXOffset = fold.map { $0.midX - bounds.midX } ?? 0
        let width = (fold?.width ?? 0) + 2 * landscapeColumnSpacing

        if landscapeDividerCenterXConstraint.constant != centerXOffset {
            landscapeDividerCenterXConstraint.constant = centerXOffset
        }

        if landscapeDividerWidthConstraint.constant != width {
            landscapeDividerWidthConstraint.constant = width
        }
    }

    private func updateLayoutConstraints() {
        let constraints: [NSLayoutConstraint]
        if isLandscapeLayout {
            constraints = landscapeConstraints
        } else if isTabletopLayout {
            constraints = portraitConstraints + tabletopConstraints
        } else {
            constraints = portraitConstraints + unfoldedPortraitConstraints
        }

        NSLayoutConstraint.deactivate(activeLayoutConstraints)
        activeLayoutConstraints = constraints
        NSLayoutConstraint.activate(constraints)
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

    func applyCornerRadius(_ cornerRadius: CGFloat) {
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
        topConstraint.priority = .defaultHigh - 2
        bottomConstraint.priority = .defaultHigh - 2
        yConstraint.priority = .defaultHigh - 2

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

    @objc private func updateToggleButtonStyles() {
        updateShuffleRepeatState(shuffleEnabled: isShuffleEnabled, repeatMode: currentRepeatMode)
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
        navigationBarView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(navigationBarView)
        navigationBarLayout.activate()
    }

    private func setupCenteredLayoutGuide() {
        addLayoutGuide(centeredLayoutGuide)

        let leading = centeredLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = centeredLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor)
        centeredLayoutGuideLeadingConstraint = leading
        centeredLayoutGuideTrailingConstraint = trailing

        NSLayoutConstraint.activate([
            leading,
            trailing,
            centeredLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            centeredLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupLandscapeLayoutGuide() {
        addLayoutGuide(landscapeDividerLayoutGuide)
        addLayoutGuide(landscapeRightLayoutGuide)
        addLayoutGuide(landscapeRightContentLayoutGuide)

        landscapeConstraints.append(contentsOf: [
            landscapeDividerCenterXConstraint,
            landscapeDividerWidthConstraint,
            landscapeRightLayoutGuide.leadingAnchor.constraint(equalTo: landscapeDividerLayoutGuide.trailingAnchor),
            landscapeRightLayoutGuide.trailingAnchor.constraint(equalTo: centeredLayoutGuide.trailingAnchor),
            landscapeRightLayoutGuide.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor),
            landscapeRightLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupThumbnailView() {
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(thumbnailView)

        sharedConstraints.append(thumbnailView.leadingAnchor.constraint(equalTo: centeredLayoutGuide.leadingAnchor))

        portraitConstraints.append(thumbnailView.trailingAnchor.constraint(equalTo: centeredLayoutGuide.trailingAnchor))

        unfoldedPortraitConstraints.append(thumbnailView.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor,
                                                                              constant: 16))

        tabletopConstraints.append(contentsOf: [
            thumbnailView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tabletopThumbnailBottomConstraint,
        ])

        landscapeConstraints.append(contentsOf: [
            thumbnailView.trailingAnchor.constraint(equalTo: landscapeDividerLayoutGuide.leadingAnchor),
            thumbnailView.topAnchor.constraint(greaterThanOrEqualTo: navigationBarView.bottomAnchor, constant: 10),
            thumbnailView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            thumbnailViewCenterYConstraint,
        ])

        setupThumbnailSubviews()
    }

    private func setupThumbnailSubviews() {
        let padding: CGFloat = 20.0
        let labelSpacing: CGFloat = 4.0

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        albumLabel.translatesAutoresizingMaskIntoConstraints = false

        thumbnailView.addSubview(thumbnailImageView)
        addSubview(titleLabel)
        addSubview(artistLabel)
        addSubview(albumLabel)

        // Landscape: the artwork is a centered square filling the left column,
        // capped by the height available there. A regular height has the room
        // for it, so the match is near-required; a compact height keeps it
        // high-priority so it yields on short panes. It cannot be required: a
        // wide, short pane has no square that satisfies both the column width
        // and the height bounds.
        let landscapeThumbnailWidth = thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor,
                                                                                constant: -2 * padding)
        landscapeThumbnailWidth.priority = .defaultHigh
        landscapeThumbnailWidthConstraint = landscapeThumbnailWidth

        // Portrait: the artwork is a square that fills the content width,
        // high-priority so it yields when the pane is too short.
        let portraitWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor)
        portraitWidthConstraint.priority = .defaultHigh - 1
        portraitThumbnailWidthConstraint = portraitWidthConstraint

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
        let landscapeContentCenterY = landscapeRightContentLayoutGuide.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor)
        landscapeContentCenterY.priority = .defaultHigh - 1

        sharedConstraints.append(contentsOf: [
            titleLabelHeightConstraint,
            artistLabelHeightConstraint,
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: labelSpacing),
            albumLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: labelSpacing),
            albumLabelHeightConstraint,
            minimumWidthConstraint,
        ])

        let thumbnailImageViewLeading = thumbnailImageView.leadingAnchor.constraint(greaterThanOrEqualTo: thumbnailView.leadingAnchor)
        let thumbnailImageViewTrailing = thumbnailImageView.trailingAnchor.constraint(lessThanOrEqualTo: thumbnailView.trailingAnchor)
        thumbnailImageViewLeadingConstraint = thumbnailImageViewLeading
        thumbnailImageViewTrailingConstraint = thumbnailImageViewTrailing

        let portraitThumbnailTop = thumbnailImageView.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: padding)
        let portraitAlbumBottom = albumLabel.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -padding)
        portraitThumbnailTopConstraint = portraitThumbnailTop
        portraitAlbumBottomConstraint = portraitAlbumBottom

        unfoldedPortraitConstraints.append(contentsOf: [
            portraitThumbnailTop,
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: padding),
            portraitAlbumBottom,
        ])

        tabletopConstraints.append(contentsOf: [
            thumbnailImageView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            thumbnailImageView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailView.topAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor, constant: padding),
        ])

        portraitConstraints.append(contentsOf: [
            thumbnailImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            thumbnailImageViewLeading,
            thumbnailImageViewTrailing,
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor),
            portraitWidthConstraint,

            titleLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),

            artistLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            artistLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),

            albumLabel.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            albumLabel.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            albumLabel.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),
        ])

        landscapeConstraints.append(contentsOf: [
            thumbnailImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            thumbnailImageView.leadingAnchor.constraint(greaterThanOrEqualTo: thumbnailView.leadingAnchor, constant: padding),
            thumbnailImageView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailView.topAnchor, constant: padding),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor),
            landscapeThumbnailWidth,

            landscapeRightContentLayoutGuide.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            landscapeRightContentLayoutGuide.bottomAnchor.constraint(equalTo: progressionView.bottomAnchor),
            landscapeRightContentLayoutGuide.topAnchor.constraint(greaterThanOrEqualTo: landscapeRightLayoutGuide.topAnchor, constant: 8),
            landscapeContentCenterY,
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

        sharedConstraints.append(contentsOf: [
            playqueueView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            playqueueView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor),
        ])

        portraitConstraints.append(contentsOf: [
            playqueueView.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            playqueueView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
        ])

        landscapeConstraints.append(contentsOf: [
            playqueueView.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor, constant: 10),
            playqueueView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
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
        controlsStackView.alignment = .center
        controlsStackView.semanticContentAttribute = .forceLeftToRight

        let controlsStackViewLeading = controlsStackView.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor)
        controlsStackViewLeading.priority = .defaultHigh
        let controlsStackViewTrailing = controlsStackView.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor)
        controlsStackViewTrailing.priority = .defaultHigh

        sharedConstraints.append(contentsOf: [
            controlsStackView.heightAnchor.constraint(equalTo: playButton.heightAnchor),
            controlsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: transportMaximumWidth),
            controlsStackView.centerXAnchor.constraint(equalTo: progressionView.centerXAnchor),
            controlsStackViewLeading,
            controlsStackViewTrailing,
            secondaryControlStackView.topAnchor.constraint(equalTo: controlsStackView.bottomAnchor, constant: topPadding/4),
            secondaryControlStackViewHeightConstraint
        ])

        let transportButtons = [shuffleButton, backwardButton, previousButton, playButton, nextButton, forwardButton, repeatButton]
        let toggleButtonWidthConstraints = [shuffleButton, repeatButton].map {
            $0.widthAnchor.constraint(equalToConstant: toggleButtonSize)
        }
        let transportWidthConstraints = toggleButtonWidthConstraints + sideButtonWidthConstraints + [playButtonWidthConstraint]
        transportWidthConstraints.forEach { $0.priority = .required - 1 }
        sharedConstraints.append(contentsOf: transportWidthConstraints)
        sharedConstraints.append(contentsOf: transportButtons.map { $0.heightAnchor.constraint(equalTo: $0.widthAnchor) })

        let portraitSecondaryControlBottom = secondaryControlStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        portraitSecondaryControlBottom.priority = .defaultHigh

        let portraitControlsTop = controlsStackView.topAnchor.constraint(equalTo: progressionView.bottomAnchor, constant: topPadding)
        portraitControlsTopConstraint = portraitControlsTop

        portraitConstraints.append(contentsOf: [
            portraitControlsTop,
            secondaryControlStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            portraitSecondaryControlBottom,
        ])

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

        secondaryControlStackView.isHidden = true
        secondaryControlStackViewHeightConstraint.constant = 0
    }

    private func setupProgressionView() {
        progressionView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressionView)

        sharedConstraints.append(progressionViewHeightConstraint)

        let portraitProgressionLeading = progressionView.leadingAnchor.constraint(equalTo: centeredLayoutGuide.leadingAnchor)
        let portraitProgressionTrailing = progressionView.trailingAnchor.constraint(equalTo: centeredLayoutGuide.trailingAnchor)
        portraitProgressionLeadingConstraint = portraitProgressionLeading
        portraitProgressionTrailingConstraint = portraitProgressionTrailing

        portraitConstraints.append(contentsOf: [
            progressionView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailView.bottomAnchor, constant: 16),
            portraitProgressionLeading,
            portraitProgressionTrailing,
        ])

        tabletopConstraints.append(progressionView.topAnchor.constraint(greaterThanOrEqualTo: albumLabel.bottomAnchor,
                                                                        constant: 16))

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
