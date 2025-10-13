/*****************************************************************************
 * MediaNavigationBar.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon # gmail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AVKit
import MediaPlayer

@objc(VLCMediaNavigationBarDelegate)
protocol MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDidTapPictureInPicture(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDidToggleQueueView(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDidToggleChromeCast(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar)
    @objc optional func mediaNavigationBarDisplayCloseAlert(_ mediaNavigationBar: MediaNavigationBar)
}

private enum RendererActionSheetContent: Int, CaseIterable {
    case airplay, chromecast
}

@objc(VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIStackView {
    // MARK: Instance Variables
    weak var delegate: MediaNavigationBarDelegate?

    lazy var closePlaybackButton: UIButton = {
        var closeButton = UIButton(type: .system)
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                        action: #selector(handleCloseTap))
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                                          action: #selector(handleLongPressPlayPause(_:)))
        longPressGesture.shouldRequireFailure(of: tapGesture)
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addGestureRecognizer(longPressGesture)
        closeButton.addGestureRecognizer(tapGesture)
        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
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

    lazy var queueButton: UIButton = {
        var queueButton = UIButton(type: .system)
        queueButton.addTarget(self, action: #selector(toggleQueueView), for: .touchDown)
        queueButton.setImage(UIImage(named: "play-queue"), for: .normal)
        queueButton.tintColor = .white
        queueButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return queueButton
    }()

    lazy var rotateButton: UIButton = {
        var rotateButton = UIButton(type: .system)
        rotateButton.addTarget(self, action: #selector(toggleOrientation), for: .touchDown)
        rotateButton.setImage(UIImage(named: "rectangle.landscape.rotate"), for: .normal)
        rotateButton.tintColor = .white
        rotateButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rotateButton.accessibilityLabel = NSLocalizedString(
            "ROTATE_BUTTON",
            comment: "Accessibility label for rotate button on the player"
        )
        rotateButton.accessibilityHint = NSLocalizedString(
            "ROTATE_BUTTON_HINT",
            comment: "Accessibility hint for rotate button on the player"
        )
        rotateButton.isHidden = true
        return rotateButton
    }()

#if os(iOS)
    lazy var chromeCastButton: UIButton = {
        var chromeButton = UIButton(type: .system)
        chromeButton.addTarget(self, action: #selector(toggleChromeCast), for: .touchDown)
        chromeButton.setImage(UIImage(named: "renderer"), for: .normal)
        chromeButton.tintColor = .white
        chromeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return chromeButton
    }()


    lazy var deviceButton: UIButton = {
        var chromeButton = UIButton(type: .system)
        chromeButton.addTarget(self, action: #selector(toggleDeviceActionSheet),
                               for: .touchDown)
        chromeButton.setImage(UIImage(named: "renderer"), for: .normal)
        chromeButton.tintColor = .white
        chromeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return chromeButton
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

    private var closureQueue: (() -> Void)? = nil

    private lazy var deviceActionSheet: ActionSheet = {
        let actionSheet = ActionSheet()
        actionSheet.delegate = self
        actionSheet.dataSource = self
        actionSheet.modalPresentationStyle = .custom
        actionSheet.collectionWrapperView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        actionSheet.collectionView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        actionSheet.headerView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        actionSheet.headerView.title.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        actionSheet.headerView.title.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        return actionSheet
    }()
#endif

    var presentingViewController: UIViewController?

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

    // MARK: Initializers
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

    // MARK: Instance Methods
    func setMediaTitleLabelText(_ titleText: String?) {
        mediaTitleTextLabel.text = titleText
        mediaTitleTextLabel.accessibilityValue = titleText
    }

    func addMoreOptionsButton(_ button: UIButton) {
        addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    func updateDeviceButton(with image: UIImage?, color: UIColor) {
#if os(iOS)
        deviceButton.setImage(image, for: .normal)
        deviceButton.tintColor = color
#endif
    }

    private func setupContraints() {
#if os(iOS)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            closePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor),
            queueButton.widthAnchor.constraint(equalTo: heightAnchor),
            deviceButton.widthAnchor.constraint(equalTo: heightAnchor)
        ])
#else
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            closePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor),
            queueButton.widthAnchor.constraint(equalTo: heightAnchor),
        ])
#endif
    }

    private func setupViews() {
        distribution = .fill
        semanticContentAttribute = .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(closePlaybackButton)
        addArrangedSubview(mediaTitleTextLabel)
        setupRotateButtonIfNeeded()
        addArrangedSubview(queueButton)
#if os(iOS)
        addArrangedSubview(deviceButton)
        addArrangedSubview(pictureInPictureButton)
#else
        addArrangedSubview(airplayVolumeView)
#endif
    }

    private func setupRotateButtonIfNeeded() {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return
        }

        addArrangedSubview(rotateButton)

        NSLayoutConstraint.activate([
            rotateButton.widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    // MARK: Gesture recognizer

    @objc private func handleLongPressPlayPause(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let accessibility: (String, String) = (NSLocalizedString("STOP_BUTTON", comment: ""), NSLocalizedString("CLOSE_HINT", comment: ""))
            updateCloseButton(with: UIImage(named: "close"), accessibility: accessibility)
            delegate?.mediaNavigationBarDisplayCloseAlert?(self)
        } else if sender.state == .ended {
            delegate?.mediaNavigationBarDidCloseLongPress(self)
        }
    }

    // MARK: Button Actions

#if os(iOS)
    func toggleDeviceActionSheet() {
        deviceActionSheet.delegate = self
        deviceActionSheet.dataSource = self
        presentingViewController?.present(deviceActionSheet,
                                          animated: true)
    }
#endif

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

    func toggleOrientation() {
        vlc_toggleOrientation()
    }

    func toggleChromeCast() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleChromeCast?(self)
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

#if os(iOS)
extension MediaNavigationBar: ActionSheetDelegate, ActionSheetDataSource {
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        if indexPath.row == 0 {
            let selector = NSSelectorFromString("_displayAudioRoutePicker")
            if airplayVolumeView.responds(to: selector) {
                airplayVolumeView.perform(selector)
                addArrangedSubview(airplayVolumeView)
                for view: UIView in airplayVolumeView.subviews {
                    if let button = view as? UIButton {
                        button.sendActions(for: .touchUpInside)
                        break
                    }
                }
                airplayVolumeView.removeFromSuperview()
            }
        } else {
            // Save closure for chromecast until the end of the actionSheet animation
            closureQueue = { [weak self] in
                self?.chromeCastButton.sendActions(for: .touchUpInside)
            }
        }
        return nil
    }

    func headerViewTitle() -> String? {
        return NSLocalizedString("HEADER_TITLE_RENDERER", comment: "")
    }

    func numberOfRows() -> Int {
        RendererActionSheetContent.allCases.count
    }

    private func enableViews(_ enable: Bool, _ view: UIView) {
        view.subviews.forEach() {
            $0.alpha = enable ? 1 : 0.5
        }
        view.isUserInteractionEnabled = enable
    }

    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActionSheetCell.identifier,
            for: indexPath) as? ActionSheetCell else {
                assertionFailure("MediaNavigationBar: VLCActionSheetDataSource: Unable to dequeue reusable cell")
                return UICollectionViewCell()
            }

        switch indexPath.row {
        case RendererActionSheetContent.airplay.rawValue:
            cell.name.text = NSLocalizedString("BUTTON_AIRPLAY", comment: "")
            cell.name.accessibilityHint = NSLocalizedString("BUTTON_AIRPLAY_HINT", comment: "")
            cell.icon.image = UIImage(named: "airplay-audio")
        case RendererActionSheetContent.chromecast.rawValue:
            cell.name.text = NSLocalizedString("BUTTON_RENDERER", comment: "")
            cell.icon.image = UIImage(named: "renderer")
            enableViews(!rendererDiscovererService.getAllRenderers().isEmpty,
                        cell)
        default:
            break
        }

        let colors: ColorPalette = PresentationTheme.currentExcludingWhite.colors
        cell.backgroundColor = colors.background
        cell.name.textColor = colors.cellTextColor
        cell.name.backgroundColor = colors.background
        cell.stackView.backgroundColor = colors.background
        cell.icon.tintColor = .white
        return cell
    }

    func actionSheetDidFinishClosingAnimation(_ actionSheet: ActionSheet) {
        closureQueue?()
        closureQueue = nil
    }
}
#endif
