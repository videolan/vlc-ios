/*****************************************************************************
 * MediaNavigationBar.swift
 *
 * Copyright (C) 2019-2026 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon # gmail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AVKit
import MediaPlayer

// MARK: - MediaNavigationBarDelegate

@objc(VLCMediaNavigationBarDelegate)
protocol MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDidTapPictureInPicture(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDidToggleQueueView(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDidToggleFavorite(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDisplayCloseAlert(_ mediaNavigationBar: MediaNavigationBar)
}

// MARK: - MediaNavigationBar

@objc(VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIStackView {
    // MARK: - Instance Variables

    weak var delegate: MediaNavigationBarDelegate?

    // Extend the close target beyond the bar's bounds.
    private static let closeButtonTouchOutset: CGFloat = 16

    static let closeImage = UIImage(systemName: "xmark",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold))

    lazy var closePlaybackButton: UIButton = {
        var closeButton = UIButton(type: .system)
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                        action: #selector(handleCloseTap))
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                                          action: #selector(handleLongPressPlayPause(_:)))
        longPressGesture.shouldRequireFailure(of: tapGesture)
        closeButton.setImage(Self.closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.addGestureRecognizer(longPressGesture)
        closeButton.addGestureRecognizer(tapGesture)
        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        closeButton.accessibilityIdentifier = VLCAccessibilityIdentifier.closePlayback
        return closeButton
    }()

    lazy var mediaTitleTextLabel: VLCMarqueeLabel = {
        var label = VLCMarqueeLabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.textColor = .white
        label.font = UIFont.preferredCustomFont(forTextStyle: .headline)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.accessibilityLabel = NSLocalizedString("TITLE", comment: "")
        return label
    }()

    lazy var favoriteButton: UIButton = {
        var favoriteButton = UIButton(type: .system)
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchDown)
        favoriteButton.tintColor = .white
        favoriteButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        favoriteButton.isHidden = true
        return favoriteButton
    }()

    lazy var queueButton: UIButton = {
        var queueButton = UIButton(type: .system)
        queueButton.addTarget(self, action: #selector(toggleQueueView), for: .touchDown)
        queueButton.setImage(UIImage(named: "play-queue"), for: .normal)
        queueButton.tintColor = .white
        queueButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return queueButton
    }()

#if os(iOS)
    lazy var deviceButton: UIButton = {
        let button = rendererDiscovererService.setupRendererButton()
        button.tintColor = .white
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }()

    lazy var pictureInPictureButton: UIButton = {
        var button = UIButton(type: .system)
        button.addTarget(self, action: #selector(togglePictureInPicture),
                               for: .touchDown)
        button.setImage(UIImage(named: "pip.enter"), for: .normal)
        button.tintColor = .white
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }()
#endif

    #if os(iOS)
    private var rendererDiscovererService: VLCRendererDiscovererManager

    lazy var airplayRoutePickerView: UIView = {
        var airPlayRoutePicker = AVRoutePickerView()
        airPlayRoutePicker.activeTintColor = .orange
        airPlayRoutePicker.tintColor = .white
        return airPlayRoutePicker
    }()
    #endif

    lazy var airplayVolumeView: MPVolumeView = {
        var airplayVolumeView = MPVolumeView()
        airplayVolumeView.tintColor = .white
        airplayVolumeView.showsVolumeSlider = false
        airplayVolumeView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return airplayVolumeView
    }()

    private let outputControls = PlayerControlGroupView(arrangedSubviews: [], followsLayoutDirection: true)

    private lazy var closeButtonBackground: VideoControlBackgroundView = {
        let background = VideoControlBackgroundView()
        background.isUserInteractionEnabled = false
        background.translatesAutoresizingMaskIntoConstraints = false
        return background
    }()

    // MARK: - Initializers

    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }

#if os(iOS)
    init(frame: CGRect, rendererDiscovererService: VLCRendererDiscovererManager) {
        self.rendererDiscovererService = rendererDiscovererService
        super.init(frame: frame)
        setupViews()
        setupContraints()
    }
#else
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupContraints()
    }
#endif

    // MARK: - Instance Methods

    func setMediaTitleLabelText(_ titleText: String?) {
        mediaTitleTextLabel.text = titleText
        mediaTitleTextLabel.accessibilityValue = titleText
    }

    func addMoreOptionsButton(_ button: UIButton) {
        outputControls.addArrangedSubview(button)
    }

#if os(iOS)
    func addPictureInPictureButton() {
        outputControls.addArrangedSubview(pictureInPictureButton)
    }
#endif

    /// Call inside an animation block; keep this view and its ancestors at alpha 1.
    func setControlsVisible(_ visible: Bool, isQueueShown: Bool = false) {
        isUserInteractionEnabled = visible
        accessibilityElementsHidden = !visible
        let itemAlpha: CGFloat = isQueueShown ? PlayerControlGroupView.dimmedAlpha : 1
        for view in arrangedSubviews where view !== outputControls {
            view.alpha = visible ? itemAlpha : 0
        }
        outputControls.setVisible(visible)
        closeButtonBackground.setVisible(visible)
        favoriteButton.alpha = itemAlpha
#if os(iOS)
        airplayRoutePickerView.alpha = itemAlpha
        deviceButton.alpha = itemAlpha
        pictureInPictureButton.alpha = itemAlpha
#endif
        queueButton.tintColor = isQueueShown ? PresentationTheme.current.colors.orangeUI : .white
    }

    func updateDeviceButton(with image: UIImage?, color: UIColor) {
#if os(iOS)
        deviceButton.setImage(image, for: .normal)
        deviceButton.tintColor = color
#endif
    }

    private func setupContraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            closePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor),
            closeButtonBackground.centerXAnchor.constraint(equalTo: closePlaybackButton.centerXAnchor),
            closeButtonBackground.centerYAnchor.constraint(equalTo: closePlaybackButton.centerYAnchor),
            closeButtonBackground.widthAnchor.constraint(equalToConstant: 44),
            closeButtonBackground.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func setupViews() {
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(closePlaybackButton)
        addArrangedSubview(mediaTitleTextLabel)

#if os(iOS)
        let outputButtons: [UIView] = [favoriteButton, queueButton, airplayRoutePickerView, deviceButton]
#else
        let outputButtons: [UIView] = [favoriteButton, queueButton, airplayVolumeView]
#endif
        insertSubview(closeButtonBackground, belowSubview: closePlaybackButton)
        setCustomSpacing(12, after: closePlaybackButton)
        outputButtons.forEach(outputControls.addArrangedSubview)
        outputControls.setContentHuggingPriority(.required, for: .horizontal)
        addArrangedSubview(outputControls)
    }

    // MARK: Gesture recognizer

    @objc private func handleLongPressPlayPause(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let accessibility: (String, String) = (NSLocalizedString("STOP_BUTTON", comment: ""), NSLocalizedString("CLOSE_HINT", comment: ""))
            updateCloseButton(with: Self.closeImage, accessibility: accessibility)
            delegate?.mediaNavigationBarDisplayCloseAlert?(self)
        } else if sender.state == .ended {
            delegate?.mediaNavigationBarDidCloseLongPress(self)
        }
    }

    // MARK: - Button Actions

    func togglePictureInPicture() {
        delegate?.mediaNavigationBarDidTapPictureInPicture?(self)
    }

    func handleCloseTap() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidTapClose(self)
    }

    func toggleQueueView() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleQueueView?(self)
    }

    func toggleFavorite() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleFavorite?(self)
    }

    func updateFavoriteButton(isFavoritable: Bool, isFavorite: Bool) {
        favoriteButton.isHidden = !isFavoritable

        guard isFavoritable else {
            return
        }

        favoriteButton.setImage(UIImage(systemName: isFavorite ? "heart.fill" : "heart"), for: .normal)

        favoriteButton.accessibilityLabel = isFavorite ? NSLocalizedString("REMOVE_FAVORITE", comment: "")
                                                       : NSLocalizedString("ADD_FAVORITE", comment: "")
    }

    func toggleOrientation() {
        vlc_toggleOrientation()
    }

    private var closeButtonTouchArea: CGRect {
        return closePlaybackButton.frame.insetBy(dx: -Self.closeButtonTouchOutset, dy: -Self.closeButtonTouchOutset)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return super.point(inside: point, with: event)
            || (closePlaybackButton.isEnabled && closeButtonTouchArea.contains(point))
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        guard view === self, closePlaybackButton.isEnabled, closeButtonTouchArea.contains(point) else {
            return view
        }
        return closePlaybackButton
    }

    func updateCloseButton(with icon: UIImage?, accessibility: (String, String)) {
        guard closePlaybackButton.imageView?.image != icon else {
            return
        }

        closePlaybackButton.setImage(icon, for: .normal)
        closePlaybackButton.accessibilityLabel = accessibility.0
        closePlaybackButton.accessibilityHint = accessibility.1
    }

#if os(iOS)
    func updatePictureInPictureButton(enabled: Bool) {
        let image = UIImage(named: enabled ? "pip.exit" : "pip.enter")
        pictureInPictureButton.setImage(image, for: .normal)
    }
#endif
}
