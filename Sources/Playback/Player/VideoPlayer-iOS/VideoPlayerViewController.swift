/*****************************************************************************
 * VideoPlayerViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2020-2022 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import AVFoundation
import MediaPlayer

@objc(VLCVideoPlayerViewControllerDelegate)
protocol VideoPlayerViewControllerDelegate: AnyObject {
    func videoPlayerViewControllerDidMinimize(_ videoPlayerViewController: VideoPlayerViewController)
    func videoPlayerViewControllerShouldBeDisplayed(_ videoPlayerViewController: VideoPlayerViewController) -> Bool
}

enum VideoPlayerSeekState {
    case `default`
    case forward
    case backward
}

enum VideoPlayerPanType {
    case none
    case brightness
    case volume
    case projection
}

@objc(VLCVideoPlayerViewController)
class VideoPlayerViewController: UIViewController {
    @objc weak var delegate: VideoPlayerViewControllerDelegate?

    var playAsAudio: Bool = false

    /* This struct is a small data container used for brightness and volume
     * gesture value persistance
     * It helps to keep their values around when they can't be get from/set to APIs
     * unavailable on simulator
     * This is a quick workaround and this should be refactored at some point
     */
    struct SliderGestureControl {
        private var deviceSetter: (Float) -> Void
        private let deviceGetter: () -> Float
        var value: Float = 0.5
        let speed: Float = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? 1.0 / 70000 : 1.0 / 20000
        init(deviceSetter: @escaping (Float) -> Void, deviceGetter: @escaping () -> Float) {
            self.deviceGetter = deviceGetter
            self.deviceSetter = deviceSetter
            self.fetchDeviceValue()
        }

        mutating func fetchDeviceValue() -> Void {
#if !targetEnvironment(simulator)
            self.value = deviceGetter()
#endif
        }

        mutating func fetchAndGetDeviceValue() -> Float {
            self.fetchDeviceValue()
            return self.value
        }

        mutating func applyValueToDevice() -> Void {
#if !targetEnvironment(simulator)
            deviceSetter(self.value)
#endif
        }
    }

    private lazy var brightnessControl: SliderGestureControl = {
        return SliderGestureControl { value in
            UIScreen.main.brightness = CGFloat(value)
        } deviceGetter: {
            return Float(UIScreen.main.brightness)
        }
    }()
    private lazy var volumeControl: SliderGestureControl = {
        return SliderGestureControl { [weak self] value in
            self?.volumeView.setVolume(value)
        } deviceGetter: {
            return AVAudioSession.sharedInstance().outputVolume
        }
    }()

    let volumeView = MPVolumeView(frame: .zero)

    private var mediaLibraryService: MediaLibraryService
    private var rendererDiscovererManager: VLCRendererDiscovererManager

    private(set) var playerController: PlayerController

    private(set) var playbackService: PlaybackService = PlaybackService.sharedInstance()

    // MARK: - Constants

    private let ZOOM_SENSITIVITY: CGFloat = 5

    private let screenPixelSize = CGSize(width: UIScreen.main.bounds.width,
                                         height: UIScreen.main.bounds.height)

    // MARK: - Private
    private var systemBrightness: Double?
    // MARK: - 360

    private var fov: CGFloat = 0
    private lazy var deviceMotion: DeviceMotion = {
        let deviceMotion = DeviceMotion()
        deviceMotion.delegate = self
        return deviceMotion
    }()

    private var orientations = UIInterfaceOrientationMask.allButUpsideDown

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return self.orientations }
        set { self.orientations = newValue }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Seek
   
    private var numberOfGestureSeek: Int = 0
    private var totalSeekDuration: Int = 0
    private var previousSeekState: VideoPlayerSeekState = .default
    var tapSwipeEqual: Bool = true
    var forwardBackwardEqual: Bool = true
    var seekForwardBy: Int = 0
    var seekBackwardBy: Int = 0
    var seekForwardBySwipe: Int = 0
    var seekBackwardBySwipe: Int = 0

    // MARK: - UI elements

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private var idleTimer: Timer?

    override var prefersStatusBarHidden: Bool {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad && !playerController.isControlsHidden {
            return false
        }
        if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portrait && !playerController.isControlsHidden {
            return false
        }
        return true
    }

    override var next: UIResponder? {
        get {
            resetIdleTimer()
            return super.next
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private lazy var layoutGuide: UILayoutGuide = {
        var layoutGuide = view.layoutMarginsGuide

        if #available(iOS 11.0, *) {
            layoutGuide = view.safeAreaLayoutGuide
        }
        return layoutGuide
    }()

    private lazy var videoOutputViewLeadingConstraint: NSLayoutConstraint = {
        let videoOutputViewLeadingConstraint = videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        return videoOutputViewLeadingConstraint
    }()

    private lazy var videoOutputViewTrailingConstraint: NSLayoutConstraint = {
        let videoOutputViewTrailingConstraint = videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        return videoOutputViewTrailingConstraint
    }()

    private lazy var mediaNavigationBar: MediaNavigationBar = {
        var mediaNavigationBar = MediaNavigationBar(frame: .zero,
                                                    rendererDiscovererService: rendererDiscovererManager)
        mediaNavigationBar.delegate = self
        mediaNavigationBar.presentingViewController = self
        mediaNavigationBar.chromeCastButton.isHidden =
            self.playbackService.renderer == nil
        return mediaNavigationBar
    }()

    private lazy var optionsNavigationBar: OptionsNavigationBar = {
        var optionsNavigationBar = OptionsNavigationBar()
        optionsNavigationBar.delegate = self
        return optionsNavigationBar
    }()

    private(set) lazy var videoPlayerControls: VideoPlayerControls = {
        let videoPlayerControls = Bundle.main.loadNibNamed("VideoPlayerControls",
                                                           owner: nil,
                                                           options: nil)?.first as! VideoPlayerControls
        videoPlayerControls.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerControls.setupAccessibility()
        videoPlayerControls.delegate = self
        let isIPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if isIPad {
            videoPlayerControls.rotationLockButton.isHidden = true
        } else {
            var image: UIImage?
            if #available(iOS 13.0, *) {
                let largeConfig = UIImage.SymbolConfiguration(scale: .large)
                image = UIImage(systemName: "lock.rotation")?.withConfiguration(largeConfig)
            } else {
                image = UIImage(named: "lock.rotation")?.withRenderingMode(.alwaysTemplate)
            }
            videoPlayerControls.rotationLockButton.setImage(image, for: .normal)
            videoPlayerControls.rotationLockButton.tintColor = .white
        }
        return videoPlayerControls
    }()

    private(set) lazy var scrubProgressBar: MediaScrubProgressBar = {
        var scrubProgressBar = MediaScrubProgressBar()
        scrubProgressBar.delegate = self
        return scrubProgressBar
    }()

    private(set) lazy var moreOptionsActionSheet: MediaMoreOptionsActionSheet = {
        var moreOptionsActionSheet = MediaMoreOptionsActionSheet()
        moreOptionsActionSheet.moreOptionsDelegate = self
        return moreOptionsActionSheet
    }()

    private var queueViewController: QueueViewController?
    private var alertController: UIAlertController?
    private var rendererButton: UIButton?
    let notificationCenter = NotificationCenter.default

    private(set) lazy var titleSelectionView: TitleSelectionView = {
        let isLandscape = UIDevice.current.orientation.isLandscape
        let titleSelectionView = TitleSelectionView(frame: .zero,
                                                    orientation: isLandscape ? .horizontal : .vertical)
        titleSelectionView.delegate = self
        titleSelectionView.isHidden = true
        return titleSelectionView
    }()

    private var currentPanType: VideoPlayerPanType = .none

    private var projectionLocation: CGPoint = .zero

    // MARK: - VideoOutput

    private lazy var statusLabel: VLCStatusLabel = {
        var statusLabel = VLCStatusLabel()
        statusLabel.isHidden = true
        statusLabel.textColor = .white
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }()

    private lazy var volumeBackgroundGradientLayer: CAGradientLayer = {
        let volumeBackGroundGradientLayer = CAGradientLayer()

        volumeBackGroundGradientLayer.frame = UIScreen.main.bounds
        volumeBackGroundGradientLayer.colors = [UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.black.cgColor]
        volumeBackGroundGradientLayer.locations = [0, 0.2, 0.8, 1]
        volumeBackGroundGradientLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        volumeBackGroundGradientLayer.isHidden = true
        return volumeBackGroundGradientLayer
    }()

    private lazy var brightnessBackgroundGradientLayer: CAGradientLayer = {
        let brightnessGroundGradientLayer = CAGradientLayer()

        brightnessGroundGradientLayer.frame = UIScreen.main.bounds
        brightnessGroundGradientLayer.colors = [UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.black.cgColor]
        brightnessGroundGradientLayer.locations = [0, 0.2, 0.8, 1]
        brightnessGroundGradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        brightnessGroundGradientLayer.isHidden = true
        return brightnessGroundGradientLayer
    }()

    private lazy var brightnessControlView: BrightnessControlView = {
        let vc = BrightnessControlView()
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: kVLCPlayerShouldRememberBrightness) {
            if let brightness = defaults.value(forKey: KVLCPlayerBrightness) as? Float {
                vc.updateIcon(level:brightness)
            } else {
                vc.updateIcon(level:brightnessControl.fetchAndGetDeviceValue())
            }
        } else {
            vc.updateIcon(level:brightnessControl.fetchAndGetDeviceValue())
        }
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.alpha = 0
        return vc
    }()

    private lazy var volumeControlView: VolumeControlView = {
        let vc = VolumeControlView(volumeView: self.volumeView)
        vc.updateIcon(level: volumeControl.fetchAndGetDeviceValue())
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.alpha = 0
        return vc
    }()

    private lazy var sideBackgroundGradientView: UIView = {
        let backgroundGradientView = UIView()
        backgroundGradientView.frame = UIScreen.main.bounds
        backgroundGradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        backgroundGradientView.layer.addSublayer(brightnessBackgroundGradientLayer)
        backgroundGradientView.layer.addSublayer(volumeBackgroundGradientLayer)
        return backgroundGradientView
    }()

    private lazy var topBottomBackgroundGradientLayer: CAGradientLayer = {
        let topBottomBackgroundGradientLayer = CAGradientLayer()

        topBottomBackgroundGradientLayer.frame = UIScreen.main.bounds
        topBottomBackgroundGradientLayer.colors = [UIColor.black.cgColor,
                                                   UIColor.clear.cgColor,
                                                   UIColor.clear.cgColor,
                                                   UIColor.black.cgColor]
        topBottomBackgroundGradientLayer.locations = [0, 0.3, 0.7, 1]
        return topBottomBackgroundGradientLayer
    }()

    private lazy var backgroundGradientView: UIView = {
        let backgroundGradientView = UIView()
        backgroundGradientView.frame = UIScreen.main.bounds
        backgroundGradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundGradientView.layer.addSublayer(topBottomBackgroundGradientLayer)
        return backgroundGradientView
    }()

    private var artWorkImageView: UIImageView = {
        let artWorkImageView = UIImageView()
        artWorkImageView.frame.size.width = UIScreen.main.bounds.width * 0.6
        artWorkImageView.frame.size.height = UIScreen.main.bounds.width * 0.6
        artWorkImageView.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        return artWorkImageView
    }()

    private var videoOutputView: UIView = {
        var videoOutputView = UIView()
        videoOutputView.backgroundColor = .black
        videoOutputView.isUserInteractionEnabled = false
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            videoOutputView.accessibilityIgnoresInvertColors = true
        }
        videoOutputView.accessibilityIdentifier = "Video Player Title"
        videoOutputView.accessibilityLabel = NSLocalizedString("VO_VIDEOPLAYER_TITLE",
                                                               comment: "")
        videoOutputView.accessibilityHint = NSLocalizedString("VO_VIDEOPLAYER_DOUBLETAP",
                                                              comment: "")
        return videoOutputView
    }()

    private lazy var externalVideoOutputView: PlayerInfoView = {
        let externalVideoOutputView = PlayerInfoView()
        externalVideoOutputView.isHidden = true
        externalVideoOutputView.translatesAutoresizingMaskIntoConstraints = false
        return externalVideoOutputView
    }()

    // MARK: - Gestures

    private lazy var tapOnVideoRecognizer: UITapGestureRecognizer = {
        let tapOnVideoRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTapOnVideo))
        return tapOnVideoRecognizer
    }()

    private lazy var playPauseRecognizer: UITapGestureRecognizer = {
        let playPauseRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(handlePlayPauseGesture))
        playPauseRecognizer.numberOfTouchesRequired = 2
        return playPauseRecognizer
    }()

    private lazy var pinchRecognizer: UIPinchGestureRecognizer = {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self,
                                                       action: #selector(handlePinchGesture(recognizer:)))
        return pinchRecognizer
    }()

    private lazy var doubleTapRecognizer: UITapGestureRecognizer = {
        let doubleTapRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(handleDoubleTapGesture(recognizer:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        tapOnVideoRecognizer.require(toFail: doubleTapRecognizer)
        return doubleTapRecognizer
    }()

    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let panRecognizer = UIPanGestureRecognizer(target: self,
                                                   action: #selector(handlePanGesture(recognizer:)))
        panRecognizer.maximumNumberOfTouches = 1
        return panRecognizer
    }()

    private lazy var leftSwipeRecognizer: UISwipeGestureRecognizer = {
        var leftSwipeRecognizer = UISwipeGestureRecognizer(target: self,
                                                           action: #selector(handleSwipeGestures(recognizer:)))
        leftSwipeRecognizer.direction = .left
        return leftSwipeRecognizer
    }()

    private lazy var rightSwipeRecognizer: UISwipeGestureRecognizer = {
        var rightSwipeRecognizer = UISwipeGestureRecognizer(target: self,
                                                            action: #selector(handleSwipeGestures(recognizer:)))
        rightSwipeRecognizer.direction = .right
        return rightSwipeRecognizer
    }()

    private lazy var upSwipeRecognizer: UISwipeGestureRecognizer = {
        var upSwipeRecognizer = UISwipeGestureRecognizer(target: self,
                                                         action: #selector(handleSwipeGestures(recognizer:)))
        upSwipeRecognizer.direction = .up
        upSwipeRecognizer.numberOfTouchesRequired = 2
        return upSwipeRecognizer
    }()

    private lazy var downSwipeRecognizer: UISwipeGestureRecognizer = {
        var downSwipeRecognizer = UISwipeGestureRecognizer(target: self,
                                                           action: #selector(handleSwipeGestures(recognizer:)))
        downSwipeRecognizer.direction = .down
        downSwipeRecognizer.numberOfTouchesRequired = 2
        return downSwipeRecognizer
    }()

    private lazy var minimizeGestureRecognizer: UIPanGestureRecognizer = {
        let dismissGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleMinimizeGesture(_:)))
        return dismissGestureRecognizer
    }()

    private var isGestureActive: Bool = false

    private var viewTranslation: CGPoint = CGPoint(x: 0, y: 0)

    // MARK: - Popup Views

    private lazy var equalizerPopupView: PopupView = {
        let equalizerPopupView = PopupView()
        equalizerPopupView.delegate = self
        return equalizerPopupView
    }()

    lazy var trackSelectorPopupView: PopupView = {
        let trackSelectorPopupView = PopupView()
        trackSelectorPopupView.delegate = self
        return trackSelectorPopupView
    }()

    private var addBookmarksView: AddBookmarksView? = nil

    // MARK: - Constraints

    private lazy var mainLayoutGuide: UILayoutGuide = {
        let guide: UILayoutGuide
        if #available(iOS 11.0, *) {
            return view.safeAreaLayoutGuide
        } else {
            return view.layoutMarginsGuide
        }
    }()

    private lazy var videoPlayerControlsHeightConstraint: NSLayoutConstraint = {
        videoPlayerControls.heightAnchor.constraint(equalToConstant: 44)
    }()

    private lazy var videoPlayerControlsBottomConstraint: NSLayoutConstraint = {
        videoPlayerControls.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor,
                                            constant: -5)
    }()

    private lazy var equalizerPopupTopConstraint: NSLayoutConstraint = {
        equalizerPopupView.topAnchor.constraint(equalTo: mainLayoutGuide.topAnchor, constant: 10)
    }()

    private lazy var equalizerPopupBottomConstraint: NSLayoutConstraint = {
        equalizerPopupView.bottomAnchor.constraint(equalTo: scrubProgressBar.topAnchor, constant: -10)
    }()

    private lazy var trackSelectorPopupTopConstraint: NSLayoutConstraint = {
        trackSelectorPopupView.topAnchor.constraint(equalTo: mainLayoutGuide.topAnchor, constant: 10)
    }()

    private lazy var trackSelectorPopupBottomConstraint: NSLayoutConstraint = {
        trackSelectorPopupView.bottomAnchor.constraint(equalTo: scrubProgressBar.topAnchor, constant: -10)
    }()

    // MARK: -

    @objc init(mediaLibraryService: MediaLibraryService, rendererDiscovererManager: VLCRendererDiscovererManager, playerController: PlayerController) {
        self.mediaLibraryService = mediaLibraryService
        self.rendererDiscovererManager = rendererDiscovererManager
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
        self.playerController.delegate = self
        systemBrightness = UIScreen.main.brightness
        NotificationCenter.default.addObserver(self, selector: #selector(systemBrightnessChanged), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.mediaNavigationBar.addGestureRecognizer(minimizeGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        if UIDevice.current.userInterfaceIdiom != .phone {
            return
        }

        // safeAreaInsets can take some time to get set.
        // Once updated, check if we need to update the constraints for notches
        adaptVideoOutputToNotch()
    }

    private func setupRendererDiscoverer() {
        rendererButton = rendererDiscovererManager.setupRendererButton()
        rendererButton?.tintColor = .white
        if playbackService.renderer != nil {
            rendererButton?.isSelected = true
        }
        if let rendererButton = rendererButton {
            mediaNavigationBar.chromeCastButton = rendererButton
        }
        rendererDiscovererManager.addSelectionHandler {
            rendererItem in
            if rendererItem != nil {
                self.changeVideoOutput(to: self.externalVideoOutputView.displayView)
                let color: UIColor = PresentationTheme.current.colors.orangeUI
                self.mediaNavigationBar.updateDeviceButton(with: UIImage(named: "rendererFull"), color: color)
            } else if let currentRenderer = self.playbackService.renderer {
                self.removedCurrentRendererItem(currentRenderer)
            } else {
                // There is no renderer item
                self.mediaNavigationBar.updateDeviceButton(with: UIImage(named: "renderer"), color: .white)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playbackService.delegate = self
        playbackService.recoverPlaybackState()
        playerController.lockedOrientation = .portrait
        navigationController?.navigationBar.isHidden = true

        setControlsHidden(false, animated: false)

        setupSeekDurations()

        // Make sure interface is enabled on
        setPlayerInterfaceEnabled(true)

        artWorkImageView.image = nil
        // FIXME: Test userdefault
        let rendererDiscoverer = rendererDiscovererManager
        rendererDiscoverer.presentingViewController = self
        rendererDiscoverer.delegate = self

        var color: UIColor = .white
        var image: UIImage? = UIImage(named: "renderer")

        if playbackService.isPlayingOnExternalScreen() {
            // FIXME: Handle error case
            changeVideoOutput(to: externalVideoOutputView.displayView)
            color = PresentationTheme.current.colors.orangeUI
            image = UIImage(named: "rendererFull")
        }

        mediaNavigationBar.updateDeviceButton(with: image, color: color)

        if #available(iOS 11.0, *) {
            adaptVideoOutputToNotch()
        }

        let setIconVisibility = playbackService.adjustFilter.isEnabled ? showIcon : hideIcon
        setIconVisibility(optionsNavigationBar.videoFiltersButton)

        view.transform = .identity
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // _viewAppeared = YES;
        
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: kVLCPlayerShouldRememberBrightness) {
            if let brightness = defaults.value(forKey: KVLCPlayerBrightness) as? CGFloat {
                UIScreen.main.brightness = brightness
            }
        }
        
        playbackService.recoverDisplayedMetadata()
        // [self resetVideoFiltersSliders];

        // The video output view is not initialized when the play as audio option was chosen
        playbackService.videoOutputView = playbackService.playAsAudio ? nil : videoOutputView

        playModeUpdated()

        // Media is loaded in the media player, checking the projection type and configuring accordingly.
        setupForMediaProjection()

        moreOptionsActionSheet.resetOptionsIfNecessary()
    }

//    override func viewDidLayoutSubviews() {
//        FIXME: - equalizer
//        self.scrubViewTopConstraint.constant = CGRectGetMaxY(self.navigationController.navigationBar.frame);
//    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topBottomBackgroundGradientLayer.frame = UIScreen.main.bounds
        brightnessBackgroundGradientLayer.frame = UIScreen.main.bounds
        volumeBackgroundGradientLayer.frame = UIScreen.main.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if playbackService.videoOutputView == videoOutputView && !playbackService.isPlayingOnExternalScreen() {
            playbackService.videoOutputView = nil
        }
        // FIXME: -
        // _viewAppeared = NO;

        // FIXME: - interface
        if idleTimer != nil {
            idleTimer?.invalidate()
            idleTimer = nil
        }

        // Reset lock interface on end of playback.
        playerController.isInterfaceLocked = false

        volumeControlView.alpha = 0
        brightnessControlView.alpha = 0

        numberOfGestureSeek = 0
        totalSeekDuration = 0
        previousSeekState = .default
        titleSelectionView.isHidden = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deviceMotion.stopDeviceMotion()
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: kVLCPlayerShouldRememberBrightness) {
            let currentBrightness = UIScreen.main.brightness
            defaults.set(currentBrightness, forKey: KVLCPlayerBrightness)
            UIScreen.main.brightness = systemBrightness!
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        setupObservers()
        setupViews()
        setupGestures()
        setupConstraints()
        setupRendererDiscoverer()
    }

    @objc func systemBrightnessChanged() {
        systemBrightness = UIScreen.main.brightness
    }

    @objc func setupQueueViewController(qvc: QueueViewController) {
        queueViewController = qvc
        queueViewController?.delegate = self
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let isLandscape: Bool = size.width >= view.frame.size.width

        titleSelectionView.mainStackView.axis = isLandscape ? .horizontal : .vertical
        titleSelectionView.mainStackView.distribution = isLandscape ? .fillEqually : .fill
    }
}

// MARK: -

private extension VideoPlayerViewController {
    @available(iOS 11.0, *)
    private func adaptVideoOutputToNotch() {
        // Ignore the constraint updates for iPads and notchless devices.
        let interfaceIdiom = UIDevice.current.userInterfaceIdiom
        if interfaceIdiom != .phone
            || (interfaceIdiom == .phone && view.safeAreaInsets.bottom == 0) {
            return
        }

        // Ignore if playing on a external screen since there is no notches.
        if playbackService.isPlayingOnExternalScreen() {
            return
        }

        // 30.0 represents the exact size of the notch
        let constant: CGFloat = playbackService.currentAspectRatio != .fillToScreen ? 30.0 : 0.0
        let interfaceOrientation = UIApplication.shared.statusBarOrientation

        if interfaceOrientation == .landscapeLeft
            || interfaceOrientation == .landscapeRight {
            videoOutputViewLeadingConstraint.constant = constant
            videoOutputViewTrailingConstraint.constant = -constant
        } else {
            videoOutputViewLeadingConstraint.constant = 0
            videoOutputViewTrailingConstraint.constant = 0
        }
        videoOutputView.layoutIfNeeded()
    }

    func changeVideoOutput(to output: UIView?) {
        // If we don't have a renderer we're mirroring and don't want to show the dialog
        let displayExternally = output == nil ? true : output != videoOutputView

        externalVideoOutputView.shouldDisplay(displayExternally,
                                              movieView: videoOutputView)

        let displayView = externalVideoOutputView.displayView

        if let displayView = displayView,
           displayExternally &&  videoOutputView.superview == displayView {
            // Adjust constraints for external display
            NSLayoutConstraint.activate([
                videoOutputView.leadingAnchor.constraint(equalTo: displayView.leadingAnchor),
                videoOutputView.trailingAnchor.constraint(equalTo: displayView.trailingAnchor),
                videoOutputView.topAnchor.constraint(equalTo: displayView.topAnchor),
                videoOutputView.bottomAnchor.constraint(equalTo: displayView.bottomAnchor)
            ])
        }

        if !displayExternally && videoOutputView.superview != view {
            view.addSubview(videoOutputView)
            view.sendSubviewToBack(videoOutputView)
            videoOutputView.frame = view.frame
            // Adjust constraint for local display
            setupVideoOutputConstraints()
            if #available(iOS 11.0, *) {
                adaptVideoOutputToNotch()
            }
        }
    }

    @objc private func handleIdleTimerExceeded() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleIdleTimerExceeded()
            }
            return
        }

        idleTimer = nil
        numberOfGestureSeek = 0
        totalSeekDuration = 0
        if !playerController.isControlsHidden && !isGestureActive {
            setControlsHidden(!playerController.isControlsHidden, animated: true)
        }
        // FIXME:- other states to reset
    }

    private func resetIdleTimer() {
        guard let safeIdleTimer = idleTimer else {
            idleTimer = Timer.scheduledTimer(timeInterval: 4,
                                             target: self,
                                             selector: #selector(handleIdleTimerExceeded),
                                             userInfo: nil,
                                             repeats: false)
            return
        }

        if fabs(safeIdleTimer.fireDate.timeIntervalSinceNow) < 4 {
            safeIdleTimer.fireDate = Date(timeIntervalSinceNow: 4)
        }
    }

    private func executeSeekFromGesture(_ type: PlayerSeekGestureType) {
        // FIXME: Need to add interface (ripple effect) for seek indicator
        var hudString = ""

        let currentSeek: Int
        if numberOfGestureSeek > 0 {
            currentSeek = type == .tap ? seekForwardBy : seekForwardBySwipe
            totalSeekDuration = previousSeekState == .backward ? currentSeek : totalSeekDuration + currentSeek
            previousSeekState = .forward
        } else {
            currentSeek = type == .tap ? seekBackwardBy : seekBackwardBySwipe
            totalSeekDuration = previousSeekState == .forward ? -currentSeek : totalSeekDuration - currentSeek
            previousSeekState = .backward
        }

        if totalSeekDuration > 0 {
            hudString = "⇒ "
            playbackService.jumpForward(Int32(currentSeek))
        } else {
            hudString = "⇐ "
            playbackService.jumpBackward(Int32(currentSeek))
        }

        // Convert the time in seconds into milliseconds in order to the get the right VLCTime value.
        let duration: VLCTime = VLCTime(number: NSNumber(value: abs(totalSeekDuration) * 1000))
        hudString.append(duration.stringValue)
        statusLabel.showStatusMessage(hudString)
    }

    private func setupSeekDurations() {
        let defaults = UserDefaults.standard

        tapSwipeEqual = defaults.bool(forKey: kVLCSettingPlaybackTapSwipeEqual)
        forwardBackwardEqual = defaults.bool(forKey: kVLCSettingPlaybackForwardBackwardEqual)
        seekForwardBy = defaults.integer(forKey: kVLCSettingPlaybackForwardSkipLength)
        seekBackwardBy = forwardBackwardEqual ? seekForwardBy : defaults.integer(forKey: kVLCSettingPlaybackBackwardSkipLength)
        seekForwardBySwipe = tapSwipeEqual ? seekForwardBy : defaults.integer(forKey: kVLCSettingPlaybackForwardSkipLengthSwipe)

        if tapSwipeEqual, forwardBackwardEqual {
            // if tap = swipe, and backward = forward, then backward swipe = forward tap
            seekBackwardBySwipe = seekForwardBy
        } else if tapSwipeEqual, !forwardBackwardEqual {
            // if tap = swipe, and backward != forward, then backward swipe = backward tap
            seekBackwardBySwipe = seekBackwardBy
        } else if !tapSwipeEqual, forwardBackwardEqual {
            // if tap != swipe, and backward = forward, then backward swipe = forward swipe
            seekBackwardBySwipe = seekForwardBySwipe
        } else {
            // otherwise backward swipe = backward swipe
            seekBackwardBySwipe = defaults.integer(forKey: kVLCSettingPlaybackBackwardSkipLengthSwipe)
        }
    }
}

// MARK: - Gesture handlers

extension VideoPlayerViewController {

    @objc func handleTapOnVideo() {
        numberOfGestureSeek = 0
        totalSeekDuration = 0
        setControlsHidden(!playerController.isControlsHidden, animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if playbackService.isPlaying && playerController.isControlsHidden {
            setControlsHidden(false, animated: true)
        }

        videoPlayerButtons()

        let popupMargin: CGFloat
        let videoPlayerControlsHeight: CGFloat
        let scrubProgressBarSpacing: CGFloat

        if traitCollection.verticalSizeClass == .compact {
            popupMargin = 0
            videoPlayerControlsHeight = 22
            scrubProgressBarSpacing = 0
        } else {
            popupMargin = 10
            videoPlayerControlsHeight = 44
            scrubProgressBarSpacing = 5
        }
        equalizerPopupTopConstraint.constant = popupMargin
        trackSelectorPopupTopConstraint.constant = popupMargin
        equalizerPopupBottomConstraint.constant = -popupMargin
        trackSelectorPopupBottomConstraint.constant = -popupMargin
        if equalizerPopupView.isShown || trackSelectorPopupView.isShown {
            videoPlayerControlsHeightConstraint.constant = videoPlayerControlsHeight
            scrubProgressBar.spacing = scrubProgressBarSpacing
            view.layoutSubviews()
        }
    }

    private func setControlsHidden(_ hidden: Bool, animated: Bool) {
        guard !UIAccessibility.isVoiceOverRunning || !hidden else { return }

        if (equalizerPopupView.isShown || trackSelectorPopupView.isShown) && hidden {
            return
        }
        playerController.isControlsHidden = hidden
        if let alert = alertController, hidden {
            alert.dismiss(animated: true, completion: nil)
            alertController = nil
        }
        let uiComponentOpacity: CGFloat = hidden ? 0 : 1

        var qvcHidden = true
        if let qvc = queueViewController {
            qvcHidden = qvc.view.alpha == 0.0
        }

        let animations = { [weak self, playerController] in
            self?.mediaNavigationBar.alpha = uiComponentOpacity
            self?.optionsNavigationBar.alpha = uiComponentOpacity
            self?.volumeControlView.alpha = playerController.isVolumeGestureEnabled ? uiComponentOpacity : 0
            self?.brightnessControlView.alpha = playerController.isBrightnessGestureEnabled ? uiComponentOpacity : 0
            if !hidden || qvcHidden {
                self?.videoPlayerControls.alpha = uiComponentOpacity
                self?.scrubProgressBar.alpha = uiComponentOpacity
            }
            self?.backgroundGradientView.alpha = hidden && qvcHidden ? 0 : 1
            if hidden {
                self?.sideBackgroundGradientView.alpha = 0
            }
        }

        let duration = animated ? 0.2 : 0
        UIView.animate(withDuration: duration, delay: 0,
                       options: .beginFromCurrentState, animations: animations,
                       completion: nil)
        self.setNeedsStatusBarAppearanceUpdate()
    }

    @objc func handlePlayPauseGesture() {
        guard playerController.isPlayPauseGestureEnabled else {
            return
        }

        if playbackService.isPlaying {
            playbackService.pause()
            setControlsHidden(false, animated: playerController.isControlsHidden)
        } else {
            playbackService.play()
        }
    }

    func jumpBackwards(_ interval: Int = 10) {
        playbackService.jumpBackward(Int32(interval))
    }

    func jumpForwards(_ interval: Int = 10) {
        playbackService.jumpForward(Int32(interval))
    }

    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        if playbackService.currentMediaIs360Video {
            let zoom: CGFloat = MediaProjection.FOV.default * -(ZOOM_SENSITIVITY * recognizer.velocity / screenPixelSize.width)
            if playbackService.updateViewpoint(0, pitch: 0,
                                               roll: 0, fov: zoom, absolute: false) {
                // Clam FOV between min and max
                fov = max(min(fov + zoom, MediaProjection.FOV.max), MediaProjection.FOV.min)
            }
        } else if recognizer.velocity < 0
                    && playerController.isCloseGestureEnabled {
            delegate?.videoPlayerViewControllerDidMinimize(self)
        }
    }

    @objc func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {
        let screenWidth: CGFloat = view.frame.size.width
        let backwardBoundary: CGFloat = screenWidth / 3.0
        let forwardBoundary: CGFloat = 2 * screenWidth / 3.0

        let tapPosition = recognizer.location(in: view)

        // Limit y position in order to avoid conflicts with the bottom controls
        if tapPosition.y > scrubProgressBar.frame.origin.y {
            return
        }

        // Reset number(set to -1/1) of seek when orientation has been changed.
        if tapPosition.x < backwardBoundary {
            numberOfGestureSeek = previousSeekState == .forward ? -1 : numberOfGestureSeek - 1
        } else if tapPosition.x > forwardBoundary {
            numberOfGestureSeek = previousSeekState == .backward ? 1 : numberOfGestureSeek + 1
        } else {
            playbackService.switchAspectRatio(true)
            return
        }
        //_isTapSeeking = YES;
        executeSeekFromGesture(.tap)
    }

    private func detectPanType(_ recognizer: UIPanGestureRecognizer) -> VideoPlayerPanType {
        let window: UIWindow = UIApplication.shared.keyWindow!
        let windowWidth: CGFloat = window.bounds.width
        let location: CGPoint = recognizer.location(in: window)

        var panType: VideoPlayerPanType = .none
        if location.x < 3 * windowWidth / 3 && playerController.isVolumeGestureEnabled {
            panType = .volume
        }
        if location.x < 2 * windowWidth / 3 {
            panType = .none
        }
        if location.x < 1 * windowWidth / 3 && playerController.isBrightnessGestureEnabled {
             panType = .brightness
        }

        if playbackService.currentMediaIs360Video {
            panType = .projection
        }
        return panType
    }

    private func applyYaw(yaw: CGFloat, pitch: CGFloat) {
        //Add and limit new pitch and yaw
        deviceMotion.yaw += yaw
        deviceMotion.pitch += pitch

        playbackService.updateViewpoint(deviceMotion.yaw,
                                        pitch: deviceMotion.pitch,
                                        roll: 0,
                                        fov: fov, absolute: true)
    }

    private func updateProjection(with recognizer: UIPanGestureRecognizer) {
        let newLocationInView: CGPoint = recognizer.location(in: view)

        let diffX = newLocationInView.x - projectionLocation.x
        let diffY = newLocationInView.y - projectionLocation.y
        projectionLocation = newLocationInView

        // ScreenSizePixel width is used twice to get a constant speed on the movement.
        let diffYaw = fov * -diffX / screenPixelSize.width
        let diffPitch = fov * -diffY / screenPixelSize.width

        applyYaw(yaw: diffYaw, pitch: diffPitch)
    }

    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let verticalPanVelocity: Float = Float(recognizer.velocity(in: view).y)

        let currentPos = recognizer.location(in: view)

        // Limit the gesture to avoid conflicts with top and bottom player controls
        if currentPos.y > scrubProgressBar.frame.origin.y
            || currentPos.y < mediaNavigationBar.frame.origin.y {
            return
        }
        let panType = detectPanType(recognizer)
        if panType == .none {
            return handleMinimizeGesture(recognizer)
        }

        guard panType == .projection
                || (panType == .volume && playerController.isVolumeGestureEnabled)
                || (panType == .brightness && playerController.isBrightnessGestureEnabled)
        else {
            return
        }

        if recognizer.state == .began {
            isGestureActive = true
            var animations : (() -> Void)?
            currentPanType = panType
            switch currentPanType {
            case .brightness:
                brightnessBackgroundGradientLayer.isHidden = false
                brightnessControl.fetchDeviceValue()
                animations = { [brightnessControlView, sideBackgroundGradientView] in
                    brightnessControlView.alpha = 1
                    sideBackgroundGradientView.alpha = 1
                }
            case .volume:
                volumeBackgroundGradientLayer.isHidden = false
                volumeControl.fetchDeviceValue()
                animations = { [volumeControlView, sideBackgroundGradientView] in
                    volumeControlView.alpha = 1
                    sideBackgroundGradientView.alpha = 1
                }
            default:
                break
            }
            if let animations = animations {
                UIView.animate(withDuration: 0.2, delay: 0,
                               options: .beginFromCurrentState, animations: animations,
                               completion: nil)
            }
            if playbackService.currentMediaIs360Video {
                projectionLocation = currentPos
                deviceMotion.stopDeviceMotion()
            }
        }

        switch currentPanType {
        case .volume:

            if recognizer.state == .changed || recognizer.state == .ended {
                let newValue = volumeControl.value - (verticalPanVelocity * volumeControl.speed)
                volumeControl.value = min(max(newValue, 0), 1)
                volumeControl.applyValueToDevice()
                volumeControlView.updateIcon(level: volumeControl.value)
            }
            break
        case .brightness:
            if recognizer.state == .changed || recognizer.state == .ended {
                let newValue = brightnessControl.value - (verticalPanVelocity * brightnessControl.speed)
                brightnessControl.value = min(max(newValue, 0), 1)
                brightnessControl.applyValueToDevice()
                brightnessControlView.updateIcon(level: brightnessControl.value)
            }
        case .projection:
            updateProjection(with: recognizer)
        case .none:
            break
        }

        if recognizer.state == .ended {
            var animations : (() -> Void)?

            // Check if both of the sliders are visible to hide them at the same time
            if currentPanType == .brightness && volumeControlView.alpha == 1 ||
                currentPanType == .volume && brightnessControlView.alpha == 1 {
                animations = { [brightnessControlView,
                                volumeControlView,
                                sideBackgroundGradientView] in
                    brightnessControlView.alpha = 0
                    volumeControlView.alpha = 0
                    sideBackgroundGradientView.alpha = 0
                }
            } else if currentPanType == .brightness {
                animations = { [brightnessControlView,
                                sideBackgroundGradientView] in
                    brightnessControlView.alpha = 0
                    sideBackgroundGradientView.alpha = 0
                }
            } else if currentPanType == .volume {
                animations = { [volumeControlView,
                                sideBackgroundGradientView] in
                    volumeControlView.alpha = 0
                    sideBackgroundGradientView.alpha = 0
                }
            }

            if let animations = animations {
                UIView.animate(withDuration: 0.2, delay: 0.5,
                               options: .beginFromCurrentState, animations: animations, completion: {
                    [brightnessBackgroundGradientLayer,
                     volumeBackgroundGradientLayer] _ in
                    brightnessBackgroundGradientLayer.isHidden = true
                    volumeBackgroundGradientLayer.isHidden = true
                    self.isGestureActive = false
                    self.setControlsHidden(true, animated: true)
                })
            }

            currentPanType = .none
            if playbackService.currentMediaIs360Video {
                deviceMotion.startDeviceMotion()
            }
        }
    }

    @objc private func handleSwipeGestures(recognizer: UISwipeGestureRecognizer) {
        guard playerController.isSwipeSeekGestureEnabled else {
            return
        }

        // Make sure that we are currently not scrubbing in order to avoid conflicts.
        guard scrubProgressBar.isScrubbing == false else {
            return
        }

        // Limit y position in order to avoid conflicts with the scrub position controls
        guard recognizer.location(in: view).y < scrubProgressBar.frame.origin.y else {
            return
        }

        var hudString = ""

        switch recognizer.direction {
        case .right:
            numberOfGestureSeek = previousSeekState == .backward ? 1 : numberOfGestureSeek + 1
            executeSeekFromGesture(.swipe)
            return
        case .left:
            numberOfGestureSeek = previousSeekState == .forward ? -1 : numberOfGestureSeek - 1
            executeSeekFromGesture(.swipe)
            return
        case .up:
            playbackService.previous()
            hudString = NSLocalizedString("BWD_BUTTON", comment: "")
        case .down:
            playbackService.next()
            hudString = NSLocalizedString("FWD_BUTTON", comment: "")
        default:
            break
        }

        if recognizer.state == .ended {
            statusLabel.showStatusMessage(hudString)
        }
    }

    @objc private func handleMinimizeGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            viewTranslation = sender.translation(in: view)
            if viewTranslation.y < 0 {
                return
            }

            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut,
                           animations: {
                self.view.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })

            break
        case .ended:
            let height = view.frame.height * 0.1
            if viewTranslation.y < height {
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 1,
                               options: .curveEaseOut,
                               animations: {
                    self.view.transform = .identity
                })
            } else {
                delegate?.videoPlayerViewControllerDidMinimize(self)
            }

            break
        default:
            break
        }
    }
}

// MARK: - Private setups

private extension VideoPlayerViewController {

    private func setupObservers() {
        try? AVAudioSession.sharedInstance().setActive(true)
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
    }

    private func setupVideoControlsState() {
        let isShuffleEnabled = playerController.isShuffleEnabled
        let repeatMode = playerController.isRepeatEnabled
        playbackService.isShuffleMode = isShuffleEnabled
        playbackService.repeatMode = repeatMode
        playModeUpdated()
    }

    private func setupViews() {
        view.backgroundColor = .black
        view.addSubview(mediaNavigationBar)
        hideSystemVolumeInfo()
        videoPlayerButtons()
        if playerController.isRememberStateEnabled {
            setupVideoControlsState()
        }

        view.addSubview(optionsNavigationBar)
        view.addSubview(videoPlayerControls)
        view.addSubview(scrubProgressBar)
        view.addSubview(videoOutputView)
        view.addSubview(brightnessControlView)
        view.addSubview(volumeControlView)
        view.addSubview(externalVideoOutputView)
        view.addSubview(statusLabel)
        view.addSubview(titleSelectionView)

        view.bringSubviewToFront(statusLabel)
        view.sendSubviewToBack(videoOutputView)
        view.insertSubview(backgroundGradientView, aboveSubview: videoOutputView)
        view.insertSubview(sideBackgroundGradientView, aboveSubview: backgroundGradientView)
        videoOutputView.addSubview(artWorkImageView)
    }

    private func hideSystemVolumeInfo() {
        volumeView.alpha = 0.00001
        view.addSubview(volumeView)
    }

    private func setupGestures() {
        view.addGestureRecognizer(tapOnVideoRecognizer)
        view.addGestureRecognizer(pinchRecognizer)
        view.addGestureRecognizer(doubleTapRecognizer)
        view.addGestureRecognizer(playPauseRecognizer)
        view.addGestureRecognizer(panRecognizer)
        view.addGestureRecognizer(leftSwipeRecognizer)
        view.addGestureRecognizer(rightSwipeRecognizer)
        view.addGestureRecognizer(upSwipeRecognizer)
        view.addGestureRecognizer(downSwipeRecognizer)

        panRecognizer.require(toFail: leftSwipeRecognizer)
        panRecognizer.require(toFail: rightSwipeRecognizer)
    }

    private func shouldDisableGestures(_ disable: Bool) {
        tapOnVideoRecognizer.isEnabled = !disable
        pinchRecognizer.isEnabled = !disable
        doubleTapRecognizer.isEnabled = !disable
        playPauseRecognizer.isEnabled = !disable
        panRecognizer.isEnabled = !disable
        leftSwipeRecognizer.isEnabled = !disable
        rightSwipeRecognizer.isEnabled = !disable
        upSwipeRecognizer.isEnabled = !disable
        downSwipeRecognizer.isEnabled = !disable
    }

    private func videoPlayerButtons() {
        let audioMedia: Bool = playbackService.metadata.isAudioOnly
        if audioMedia || playbackService.playAsAudio {
            videoPlayerControls.repeatButton.isHidden = false
            videoPlayerControls.shuffleButton.isHidden = false

            videoPlayerControls.subtitleButton.isHidden = true
            videoPlayerControls.aspectRatioButton.isHidden = true
        } else {
            videoPlayerControls.repeatButton.isHidden = true
            videoPlayerControls.shuffleButton.isHidden = true

            videoPlayerControls.subtitleButton.isHidden = false
            videoPlayerControls.aspectRatioButton.isHidden = false
        }
    }
    // MARK: - Constraints

    private func setupConstraints() {
        setupBrightnessControlConstraints()
        setupVolumeControlConstraints()
        setupVideoOutputConstraints()
        setupExternalVideoOutputConstraints()
        setupVideoPlayerControlsConstraints()
        setupMediaNavigationBarConstraints()
        setupScrubProgressBarConstraints()
        setupStatusLabelConstraints()
        setupTitleSelectionConstraints()
    }

    private func setupTitleSelectionConstraints() {
        NSLayoutConstraint.activate([
            titleSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleSelectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleSelectionView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    private func setupCommonSliderConstraints(for slider: UIView) {
        let heightConstraint = slider.heightAnchor.constraint(lessThanOrEqualToConstant: 170)
        let topConstraint = slider.topAnchor.constraint(equalTo: mediaNavigationBar.bottomAnchor)
        let bottomConstraint = slider.bottomAnchor.constraint(equalTo: scrubProgressBar.topAnchor, constant: -10)
        let yConstraint = slider.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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

    private func setupBrightnessControlConstraints() {
        setupCommonSliderConstraints(for: brightnessControlView)
        NSLayoutConstraint.activate([
            brightnessControlView.leadingAnchor.constraint(equalTo: mainLayoutGuide.leadingAnchor)
        ])
    }

    private func setupVolumeControlConstraints() {
        setupCommonSliderConstraints(for: volumeControlView)
        NSLayoutConstraint.activate([
            volumeControlView.trailingAnchor.constraint(equalTo: mainLayoutGuide.trailingAnchor)
        ])
    }

    private func setupVideoOutputConstraints() {
        videoOutputViewLeadingConstraint = videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        videoOutputViewTrailingConstraint = videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([
            videoOutputViewLeadingConstraint,
            videoOutputViewTrailingConstraint,
            videoOutputView.topAnchor.constraint(equalTo: view.topAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupExternalVideoOutputConstraints() {
        NSLayoutConstraint.activate([
            externalVideoOutputView.heightAnchor.constraint(equalToConstant: 320),
            externalVideoOutputView.widthAnchor.constraint(equalToConstant: 320),
            externalVideoOutputView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            externalVideoOutputView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupMediaNavigationBarConstraints() {
        let padding: CGFloat = 16

        NSLayoutConstraint.activate([
            mediaNavigationBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mediaNavigationBar.leadingAnchor.constraint(equalTo: videoPlayerControls.leadingAnchor),
            mediaNavigationBar.trailingAnchor.constraint(equalTo: videoPlayerControls.trailingAnchor),
            mediaNavigationBar.topAnchor.constraint(equalTo: layoutGuide.topAnchor,
                                                    constant: padding),
            optionsNavigationBar.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -padding),
            optionsNavigationBar.topAnchor.constraint(equalTo: mediaNavigationBar.bottomAnchor, constant: padding)
        ])
    }

    private func setupVideoPlayerControlsConstraints() {
        let padding: CGFloat = 20
        let minPadding: CGFloat = 5

        NSLayoutConstraint.activate([
            videoPlayerControlsHeightConstraint,
            videoPlayerControls.leadingAnchor.constraint(lessThanOrEqualTo: layoutGuide.leadingAnchor,
                                                         constant: padding),
            videoPlayerControls.trailingAnchor.constraint(greaterThanOrEqualTo: layoutGuide.trailingAnchor,
                                                          constant: -padding),
            videoPlayerControls.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor,
                                                       constant: -2 * minPadding),
            videoPlayerControlsBottomConstraint
        ])
    }

    private func setupScrubProgressBarConstraints() {
        let margin: CGFloat = 12

        NSLayoutConstraint.activate([
            scrubProgressBar.leadingAnchor.constraint(equalTo: videoPlayerControls.leadingAnchor),
            scrubProgressBar.trailingAnchor.constraint(equalTo: videoPlayerControls.trailingAnchor),
            scrubProgressBar.bottomAnchor.constraint(equalTo: videoPlayerControls.topAnchor, constant: -margin)
        ])
    }

    private func setupStatusLabelConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Observers
    @objc func systemVolumeDidChange(notification: NSNotification) {
        let volumelevel = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"]
        UIView.transition(with: volumeControlView, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations : {
                            self.volumeControlView.updateIcon(level: volumelevel as! Float)

                          })
    }

    // MARK: - Others

    private func setupForMediaProjection() {
        let mediaHasProjection = playbackService.currentMediaIs360Video

        fov = mediaHasProjection ? MediaProjection.FOV.default : 0

        // Disable swipe gestures for 360
        leftSwipeRecognizer.isEnabled = !mediaHasProjection
        rightSwipeRecognizer.isEnabled = !mediaHasProjection
        upSwipeRecognizer.isEnabled = !mediaHasProjection
        downSwipeRecognizer.isEnabled = !mediaHasProjection

        if mediaHasProjection {
            deviceMotion.startDeviceMotion()
        }
    }
}

internal extension VideoPlayerViewController {

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // We're observing outputVolume to handle volume changes from physical volume buttons
        // To processd properly we have to check we're not interacting with UI controls or gesture
        if keyPath == "outputVolume" &&
            !volumeControlView.isBeingTouched && // Check we're not interacting with volume slider
            !isGestureActive && // Check if the slider did not just changed value
            currentPanType != .volume { // Check we're not doing pan gestures for volume
            let appearAnimations = { [volumeControlView] in
                volumeControlView.alpha = 1
                }
            let disappearAnimations = { [volumeControlView] in
                volumeControlView.alpha = 0
                }
            UIView.animate(withDuration:0.2, delay: 0,
                           options: .beginFromCurrentState,
                           animations:appearAnimations, completion:nil)
            UIView.animate(withDuration: 0.2, delay: 1,
                           options: [],
                           animations:disappearAnimations, completion:nil)
            self.volumeControlView.updateIcon(level: AVAudioSession.sharedInstance().outputVolume)
        }
    }
}

// MARK: - Private helpers

private extension VideoPlayerViewController {
    private func setPlayerInterfaceEnabled(_ enabled: Bool) {
        mediaNavigationBar.closePlaybackButton.isEnabled = enabled
        mediaNavigationBar.deviceButton.isEnabled = enabled
        mediaNavigationBar.queueButton.isEnabled = enabled
        if #available(iOS 11.0, *) {
            mediaNavigationBar.airplayRoutePickerView.isUserInteractionEnabled = enabled
            mediaNavigationBar.airplayRoutePickerView.alpha = !enabled ? 0.5 : 1
        } else {
            mediaNavigationBar.airplayVolumeView.isUserInteractionEnabled = enabled
            mediaNavigationBar.airplayVolumeView.alpha = !enabled ? 0.5 : 1
        }

        scrubProgressBar.progressSlider.isEnabled = enabled
        scrubProgressBar.remainingTimeButton.isEnabled = enabled

        optionsNavigationBar.videoFiltersButton.isEnabled = enabled
        optionsNavigationBar.playbackSpeedButton.isEnabled = enabled
        optionsNavigationBar.equalizerButton.isEnabled = enabled
        optionsNavigationBar.sleepTimerButton.isEnabled = enabled

        videoPlayerControls.subtitleButton.isEnabled = enabled
        videoPlayerControls.shuffleButton.isEnabled = enabled
        videoPlayerControls.repeatButton.isEnabled = enabled
        videoPlayerControls.dvdButton.isEnabled = enabled
        videoPlayerControls.rotationLockButton.isEnabled = enabled
        videoPlayerControls.backwardButton.isEnabled = enabled
        videoPlayerControls.previousMediaButton.isEnabled = enabled
        videoPlayerControls.playPauseButton.isEnabled = enabled
        videoPlayerControls.nextMediaButton.isEnabled = enabled
        videoPlayerControls.forwardButton.isEnabled = enabled
        videoPlayerControls.aspectRatioButton.isEnabled = enabled

        playPauseRecognizer.isEnabled = enabled
        doubleTapRecognizer.isEnabled = enabled
        pinchRecognizer.isEnabled = enabled
        rightSwipeRecognizer.isEnabled = enabled
        leftSwipeRecognizer.isEnabled = enabled
        upSwipeRecognizer.isEnabled = enabled
        downSwipeRecognizer.isEnabled = enabled
        panRecognizer.isEnabled = enabled

        brightnessControlView.isEnabled(enabled)
        volumeControlView.isEnabled(enabled)

        playerController.isInterfaceLocked = !enabled
    }
}

// MARK: - Delegation

// MARK: - VLCRendererDiscovererManagerDelegate

extension VideoPlayerViewController: VLCRendererDiscovererManagerDelegate {
    func removedCurrentRendererItem(_ item: VLCRendererItem) {
        changeVideoOutput(to: videoOutputView)
        mediaNavigationBar.updateDeviceButton(with: UIImage(named: "renderer"), color: .white)
    }
}

// MARK: - DeviceMotionDelegate

extension VideoPlayerViewController: DeviceMotionDelegate {
    func deviceMotionHasAttitude(deviceMotion: DeviceMotion, pitch: Double, yaw: Double) {
        if panRecognizer.state != .changed
            || panRecognizer.state != .began {
            applyYaw(yaw: CGFloat(yaw), pitch: CGFloat(pitch))
        }
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension VideoPlayerViewController: VLCPlaybackServiceDelegate {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        mediaNavigationBar.setMediaTitleLabelText("")
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.isPlaying)

        DispatchQueue.main.async {
            self.updateAudioInterface(with: playbackService.metadata)
        }
        // FIXME: -
        resetIdleTimer()
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        scrubProgressBar.updateInterfacePosition()
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                 isPlaying: Bool,
                                 currentMediaHasTrackToChooseFrom: Bool, currentMediaHasChapters: Bool,
                                 for playbackService: PlaybackService) {
        videoPlayerControls.updatePlayPauseButton(toState: isPlaying)

        if currentState == .error {
            statusLabel.showStatusMessage(NSLocalizedString("PLAYBACK_FAILED",
                                                            comment: ""))
        }

        if titleSelectionView.isHidden == false {
            titleSelectionView.updateHeightConstraints()
            titleSelectionView.reload()
        }

        if let queueCollectionView = queueViewController?.queueCollectionView {
            queueCollectionView.reloadData()
        }
        moreOptionsActionSheet.currentMediaHasChapters = currentMediaHasChapters
    }

    func showStatusMessage(_ statusMessage: String) {
        statusLabel.showStatusMessage(statusMessage)
    }

    func playbackServiceDidSwitch(_ aspectRatio: VLCAspectRatio) {
        // subControls.isInFullScreen = aspectRatio == .fillToScreen

        if #available(iOS 11.0, *) {
            adaptVideoOutputToNotch()
        }
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        // FIXME: -
        // if (!_viewAppeared)
        //     return;
        if !isViewLoaded {
            return
        }

        mediaNavigationBar.setMediaTitleLabelText(metadata.title)

        if playbackService.isPlayingOnExternalScreen() {
            externalVideoOutputView.updateUI(rendererItem: playbackService.renderer, title: metadata.title)
        } else {
            self.externalVideoOutputView.isHidden = true
        }

        updateAudioInterface(with: metadata)

        videoPlayerButtons()
    }

    private func updateAudioInterface(with metadata: VLCMetaData) {
        if metadata.isAudioOnly || playbackService.playAsAudio {
            // Only update the artwork image when the media is being played
            if playbackService.isPlaying {
                let artworkImage = metadata.artworkImage
                artWorkImageView.image = artworkImage
                queueViewController?.reloadBackground(with: artworkImage)
            }

            // Only show the artwork when not casting to a device.
            artWorkImageView.isHidden = playbackService.renderer != nil ? true : false
            artWorkImageView.clipsToBounds = true
            artWorkImageView.contentMode = .scaleAspectFit
            playbackService.videoOutputView = nil
        } else {
            playbackService.videoOutputView = videoOutputView
            artWorkImageView.isHidden = true
            queueViewController?.reloadBackground(with: nil)
        }
    }

    func playModeUpdated() {
        let orangeColor = PresentationTheme.current.colors.orangeUI

        switch playbackService.repeatMode {
        case .doNotRepeat:
            videoPlayerControls.repeatButton.setImage(UIImage(named: "iconRepeat"), for: .normal)
            videoPlayerControls.repeatButton.tintColor = .white
        case .repeatCurrentItem:
            videoPlayerControls.repeatButton.setImage(UIImage(named: "iconRepeatOne"), for: .normal)
            videoPlayerControls.repeatButton.tintColor = orangeColor
        case .repeatAllItems:
            videoPlayerControls.repeatButton.setImage(UIImage(named: "iconRepeat"), for: .normal)
            videoPlayerControls.repeatButton.tintColor = orangeColor
        @unknown default:
            assertionFailure("videoPlayerControlsDelegateRepeat: unhandled case.")
        }

        videoPlayerControls.shuffleButton.tintColor = playbackService.isShuffleMode ? orangeColor : .white
    }
}

// MARK: - PlayerControllerDelegate

extension VideoPlayerViewController: PlayerControllerDelegate {
    func playerControllerExternalScreenDidConnect(_ playerController: PlayerController) {
        changeVideoOutput(to: externalVideoOutputView.displayView)
    }

    func playerControllerExternalScreenDidDisconnect(_ playerController: PlayerController) {
        changeVideoOutput(to: videoOutputView)
    }

    func playerControllerApplicationBecameActive(_ playerController: PlayerController) {
        if (delegate?.videoPlayerViewControllerShouldBeDisplayed(self)) != nil {
            playbackService.recoverDisplayedMetadata()
            if playbackService.videoOutputView != videoOutputView {
                playbackService.videoOutputView = videoOutputView
            }
        }
    }

    func playerControllerPlaybackDidStop(_ playerController: PlayerController) {
        delegate?.videoPlayerViewControllerDidMinimize(self)
        // Reset interface to default icon when dismissed
//        subControls.isInFullScreen = false
    }
}

// MARK: -

// MARK: - MediaNavigationBarDelegate

extension VideoPlayerViewController: MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar) {
        playbackService.stopPlayback()
        playbackService.setPlayAsAudio(false)
    }

    func mediaNavigationBarDidToggleQueueView(_ mediaNavigationBar: MediaNavigationBar) {
        if let qvc = queueViewController {
            shouldDisableGestures(true)
            qvc.removeFromParent()
            qvc.view.removeFromSuperview()
            qvc.show()
            qvc.topView.isHidden = false
            addChild(qvc)
            qvc.didMove(toParent: self)
            view.layoutIfNeeded()
            videoPlayerControlsBottomConstraint.isActive = false
            videoPlayerControls.bottomAnchor.constraint(equalTo: qvc.view.topAnchor,
                                                        constant: -5).isActive = true
            videoPlayerControls.subtitleButton.isEnabled = false
            videoPlayerControls.rotationLockButton.isEnabled = false
            videoPlayerControls.aspectRatioButton.isEnabled = false
            videoPlayerControls.moreActionsButton.isEnabled = false
            view.bringSubviewToFront(scrubProgressBar)
            view.bringSubviewToFront(videoPlayerControls)
            setControlsHidden(true, animated: true)
            qvc.bottomConstraint?.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
            qvc.delegate = self
        }
    }

    func mediaNavigationBarDidToggleChromeCast(_ mediaNavigationBar: MediaNavigationBar) {
        // TODO: Add current renderer functionality to chromeCast Button
        // NSAssert(0, @"didToggleChromeCast not implemented");
    }

    func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar) {
        delegate?.videoPlayerViewControllerDidMinimize(self)
    }

    func mediaNavigationBarDisplayCloseAlert(_ mediaNavigationBar: MediaNavigationBar) {
        statusLabel.showStatusMessage(NSLocalizedString("MINIMIZE_HINT", comment: ""))
    }
}

// MARK: - MediaScrubProgressBarDelegate

extension VideoPlayerViewController: MediaScrubProgressBarDelegate {
    func mediaScrubProgressBarShouldResetIdleTimer() {
        resetIdleTimer()
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension VideoPlayerViewController: MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        let mask = getInterfaceOrientationMask(orientation: UIApplication.shared.statusBarOrientation)

        supportedInterfaceOrientations = supportedInterfaceOrientations == .allButUpsideDown ? mask : .allButUpsideDown

        setPlayerInterfaceEnabled(!state)
    }

    func mediaMoreOptionsActionSheetDidAppeared() {
        handleTapOnVideo()
    }

    func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .videoFilters:
            showIcon(button: optionsNavigationBar.videoFiltersButton)
            return
        case .playbackSpeed:
            showIcon(button: optionsNavigationBar.playbackSpeedButton)
            return
        case .equalizer:
            showIcon(button: optionsNavigationBar.equalizerButton)
            return
        case .sleepTimer:
            showIcon(button: optionsNavigationBar.sleepTimerButton)
            return
        default:
            assertionFailure("VideoPlayerViewController: Option not valid.")
        }
    }

    func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .videoFilters:
            hideIcon(button: optionsNavigationBar.videoFiltersButton)
            return
        case .playbackSpeed:
            hideIcon(button: optionsNavigationBar.playbackSpeedButton)
            return
        case .equalizer:
            hideIcon(button: optionsNavigationBar.equalizerButton)
            return
        case .sleepTimer:
            hideIcon(button: optionsNavigationBar.sleepTimerButton)
            return
        default:
            assertionFailure("VideoPlayerViewController: Option not valid.")
        }
    }

    func mediaMoreOptionsActionSheetHideAlertIfNecessary() {
        if let alert = alertController {
            alert.dismiss(animated: true, completion: nil)
            alertController = nil
        }
    }

    func mediaMoreOptionsActionSheetPresentPopupView(withChild child: UIView) {
        if let equalizerView = child as? EqualizerView {
            guard !equalizerPopupView.isShown else {
                return
            }

            showPopup(equalizerPopupView, with: equalizerView, accessoryViewsDelegate: equalizerView)
        }
    }

    func mediaMoreOptionsActionSheetUpdateProgressBar() {
        if !playbackService.isPlaying {
            playbackService.playPause()
        }
    }

    func mediaMoreOptionsActionSheetGetCurrentMedia() -> VLCMLMedia? {
        guard let media = playbackService.currentlyPlayingMedia else {
            return nil
        }

        let currentMedia = mediaLibraryService.fetchMedia(with: media.url)
        return currentMedia
    }

    func mediaMoreOptionsActionSheetDidSelectBookmark(value: Float) {
        scrubProgressBar.updateSliderWithValue(value: value)
        if !playbackService.isPlaying {
            playbackService.playPause()
        }
    }

    private func openOptionView(view: ActionSheetCellIdentifier) {
        present(moreOptionsActionSheet, animated: true, completion: {
            self.moreOptionsActionSheet.addView(view)
        })
    }

    func mediaMoreOptionsActionSheetDisplayAlert(title: String, message: String, action: BookmarkActionIdentifier, index: Int, isEditing: Bool) {
        let completion = {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            var actionTitle = NSLocalizedString("BUTTON_CANCEL", comment: "")
            let cancelAction = UIAlertAction(title: actionTitle, style: .cancel) { _ in
                if !isEditing {
                    self.openOptionView(view: .bookmarks)
                }
            }

            alertController.addAction(cancelAction)

            if action == .delete {
                actionTitle = NSLocalizedString("BUTTON_DELETE", comment: "")
                let mainAction = UIAlertAction(title: actionTitle, style: .destructive, handler: { _ in
                    self.moreOptionsActionSheet.deleteBookmarkAt(row: index)
                    if !isEditing {
                        self.openOptionView(view: .bookmarks)
                    }
                })

                alertController.addAction(mainAction)
            } else if action == .rename {
                alertController.addTextField(configurationHandler: { field in
                    field.text = message
                    field.returnKeyType = .done
                })

                actionTitle = NSLocalizedString("BUTTON_RENAME", comment: "")
                let mainAction = UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                    guard let field = alertController.textFields else {
                        return
                    }

                    guard let newName = field[0].text else {
                        return
                    }

                    self.moreOptionsActionSheet.renameBookmarkAt(name: newName, row: index)

                    if !isEditing {
                        self.openOptionView(view: .bookmarks)
                    }
                })

                alertController.addAction(mainAction)
            }

            self.setControlsHidden(true, animated: true)
            self.present(alertController, animated: true, completion: nil)
            self.alertController = alertController
        }

        // iOS 12.0 and below versions do not execute the completion if the dismiss call is not performed,
        // here the check is necessary in order to enable the edit actions for these iOS versions.
        if addBookmarksView == nil {
            moreOptionsActionSheet.dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
    }

    func mediaMoreOptionsActionSheetDisplayAddBookmarksView(_ bookmarksView: AddBookmarksView) {
        shouldDisableGestures(true)

        mediaNavigationBar.isHidden = true

        bookmarksView.translatesAutoresizingMaskIntoConstraints = false

        addBookmarksView = bookmarksView

        if let bookmarksView = addBookmarksView {
            view.addSubview(bookmarksView)
            NSLayoutConstraint.activate([
                bookmarksView.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
                bookmarksView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
                bookmarksView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
                bookmarksView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 16),
                bookmarksView.bottomAnchor.constraint(lessThanOrEqualTo: scrubProgressBar.topAnchor),
            ])
        }

        if let safeIdleTimer = idleTimer {
            safeIdleTimer.invalidate()
        }
        videoPlayerControls.shouldDisableControls(true)
        setControlsHidden(true, animated: true)
    }

    func mediaMoreOptionsActionSheetRemoveAddBookmarksView() {
        shouldDisableGestures(false)

        mediaNavigationBar.isHidden = false

        if let bookmarksView = addBookmarksView {
            bookmarksView.removeFromSuperview()
        }

        addBookmarksView = nil
        idleTimer = nil
        resetIdleTimer()
        videoPlayerControls.shouldDisableControls(false)
    }

    func mediaMoreOptionsActionSheetDidToggleShuffle(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        videoPlayerControlsDelegateShuffle(videoPlayerControls)
        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    func mediaMoreOptionsActionSheetDidTapRepeat(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        videoPlayerControlsDelegateRepeat(videoPlayerControls)
        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }
}

// MARK: - OptionsNavigationBarDelegate

extension VideoPlayerViewController: OptionsNavigationBarDelegate {
    private func resetVideoFilters() {
        hideIcon(button: optionsNavigationBar.videoFiltersButton)
        moreOptionsActionSheet.resetVideoFilters()
    }

    private func resetPlaybackSpeed() {
        hideIcon(button: optionsNavigationBar.playbackSpeedButton)
        moreOptionsActionSheet.resetPlaybackSpeed()
    }

    private func resetEqualizer() {
        moreOptionsActionSheet.resetEqualizer()
        hideIcon(button: optionsNavigationBar.equalizerButton)
    }

    private func resetSleepTimer() {
        hideIcon(button: optionsNavigationBar.sleepTimerButton)
        moreOptionsActionSheet.resetSleepTimer()
    }

    private func showIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = false
        }, completion: nil)
    }

    private func hideIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = true
        }, completion: nil)
    }

    private func handleReset(button: UIButton) {
        switch button {
        case optionsNavigationBar.videoFiltersButton:
            resetVideoFilters()
            return
        case optionsNavigationBar.playbackSpeedButton:
            resetPlaybackSpeed()
            return
        case optionsNavigationBar.equalizerButton:
            resetEqualizer()
            return
        case optionsNavigationBar.sleepTimerButton:
            resetSleepTimer()
            return
        default:
            assertionFailure("VideoPlayerViewController: Unvalid button.")
        }
    }

    func optionsNavigationBarDisplayAlert(title: String, message: String, button: UIButton) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)

        let resetButton = UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.handleReset(button: button)
        }

        alertController.addAction(cancelButton)
        alertController.addAction(resetButton)

        self.present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    func optionsNavigationBarGetRemainingTime() -> String {
        let remainingTime = moreOptionsActionSheet.getRemainingTime()
        return remainingTime
    }
}

// MARK: - Download More SPU

extension VideoPlayerViewController {
    @objc func downloadMoreSPU() {
        let targetViewController: VLCPlaybackInfoSubtitlesFetcherViewController =
            VLCPlaybackInfoSubtitlesFetcherViewController(nibName: nil,
                                                          bundle: nil)
        targetViewController.title = NSLocalizedString("DOWNLOAD_SUBS_FROM_OSO",
                                                       comment: "")

        let modalNavigationController = UINavigationController(rootViewController: targetViewController)
        present(modalNavigationController, animated: true, completion: nil)
    }
}

// MARK: - Popup methods

extension VideoPlayerViewController {
    func showPopup(_ popupView: PopupView, with contentView: UIView, accessoryViewsDelegate: PopupViewAccessoryViewsDelegate? = nil) {
        shouldDisableGestures(true)
        videoPlayerControls.moreActionsButton.isEnabled = false
        popupView.isShown = true

        popupView.addContentView(contentView, constraintWidth: true)
        if let accessoryViewsDelegate = accessoryViewsDelegate {
            popupView.accessoryViewsDelegate = accessoryViewsDelegate
        }

        view.addSubview(popupView)

        let iPhone5width: CGFloat = 320
        let leadingConstraint = popupView.leadingAnchor.constraint(equalTo: mainLayoutGuide.leadingAnchor, constant: 10)
        let trailingConstraint = popupView.trailingAnchor.constraint(equalTo: mainLayoutGuide.trailingAnchor, constant: -10)
        leadingConstraint.priority = .required
        trailingConstraint.priority = .required

        let popupViewTopConstraint: NSLayoutConstraint
        let popupViewBottomConstraint: NSLayoutConstraint
        if popupView == equalizerPopupView {
            popupViewTopConstraint = equalizerPopupTopConstraint
            popupViewBottomConstraint = equalizerPopupBottomConstraint
        } else {
            popupViewTopConstraint = trackSelectorPopupTopConstraint
            popupViewBottomConstraint = trackSelectorPopupBottomConstraint
        }
        let newConstraints = [
            popupViewTopConstraint,
            popupViewBottomConstraint,
            leadingConstraint,
            trailingConstraint,
            popupView.centerXAnchor.constraint(equalTo: mainLayoutGuide.centerXAnchor),
            popupView.widthAnchor.constraint(greaterThanOrEqualToConstant: iPhone5width)
        ]
        NSLayoutConstraint.activate(newConstraints)
    }
}

// MARK: - PopupViewDelegate

extension VideoPlayerViewController: PopupViewDelegate {
    func popupViewDidClose(_ popupView: PopupView) {
        popupView.isShown = false
        videoPlayerControls.moreActionsButton.isEnabled = true
        videoPlayerControlsHeightConstraint.constant = 44
        scrubProgressBar.spacing = 5

        shouldDisableGestures(false)
        resetIdleTimer()
    }
}

// MARK: - QueueViewControllerDelegate

extension VideoPlayerViewController: QueueViewControllerDelegate {
    func queueViewControllerDidDisappear(_ queueViewController: QueueViewController?) {
        setControlsHidden(false, animated: true)
        queueViewController?.hide()
        shouldDisableGestures(false)
        videoPlayerControlsBottomConstraint.isActive = true
        videoPlayerControls.subtitleButton.isEnabled = true
        videoPlayerControls.rotationLockButton.isEnabled = true
        videoPlayerControls.aspectRatioButton.isEnabled = true
        videoPlayerControls.moreActionsButton.isEnabled = true
    }
}

// MARK: - Keyboard Controls

extension VideoPlayerViewController {
    @objc func keyLeftArrow() {
        jumpBackwards(seekBackwardBy)
    }

    @objc func keyRightArrow() {
        jumpForwards(seekForwardBy)
    }

    @objc func keyRightBracket() {
        playbackService.playbackRate *= 1.5
    }

    @objc func keyLeftBracket() {
        playbackService.playbackRate *= 0.75
    }

    @objc func keyEqual() {
        playbackService.playbackRate = 1.0
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = [
            UIKeyCommand(input: " ",
                         modifierFlags: [],
                         action: #selector(handlePlayPauseGesture),
                         discoverabilityTitle: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")),
            UIKeyCommand(input: "\r",
                         modifierFlags: [],
                         action: #selector(handlePlayPauseGesture),
                         discoverabilityTitle: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow,
                         modifierFlags: [],
                         action: #selector(keyLeftArrow),
                         discoverabilityTitle: NSLocalizedString("KEY_JUMP_BACKWARDS", comment: "")),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow,
                         modifierFlags: [],
                         action: #selector(keyRightArrow),
                         discoverabilityTitle: NSLocalizedString("KEY_JUMP_FORWARDS", comment: "")),
            UIKeyCommand(input: "[",
                         modifierFlags: [],
                         action: #selector(keyRightBracket),
                         discoverabilityTitle: NSLocalizedString("KEY_INCREASE_PLAYBACK_SPEED", comment: "")),
            UIKeyCommand(input: "]",
                         modifierFlags: [],
                         action: #selector(keyLeftBracket),
                         discoverabilityTitle: NSLocalizedString("KEY_DECREASE_PLAYBACK_SPEED", comment: ""))
        ]

        if abs(playbackService.playbackRate - 1.0) > .ulpOfOne {
            commands.append(UIKeyCommand(input: "=",
                                         modifierFlags: [],
                                         action: #selector(keyEqual),
                                         discoverabilityTitle: NSLocalizedString("KEY_RESET_PLAYBACK_SPEED",
                                                                                 comment: "")))
        }

        if #available(iOS 15, *) {
            commands.forEach {
                if $0.input == UIKeyCommand.inputRightArrow
                    || $0.input == UIKeyCommand.inputLeftArrow {
                    ///UIKeyCommand.wantsPriorityOverSystemBehavior is introduced in iOS 15 SDK
                    ///but we actually still use Xcode 12.4 on CI. This old version only provides
                    ///SDK for iOS 14.4 max. Hence we use ObjC apis to call the method and still
                    ///have the ability to build with older Xcode versions.
                    let selector = NSSelectorFromString("setWantsPriorityOverSystemBehavior:")
                    if $0.responds(to: selector) {
                        $0.perform(selector, with: true)
                    }
                }
            }
        }

        return commands
    }
}

// MARK: - TitleSelectionViewDelegate

extension VideoPlayerViewController: TitleSelectionViewDelegate {
    func titleSelectionViewDelegateDidSelectFromFiles(_ titleSelectionView: TitleSelectionView) {
        let vc = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func titleSelectionViewDelegateDidSelectTrack(_ titleSelectionView: TitleSelectionView) {
        titleSelectionView.isHidden = true
    }

    func titleSelectionViewDelegateDidSelectDownloadSPU(_ titleSelectionView: TitleSelectionView) {
        downloadMoreSPU()
    }

    func shouldHideTitleSelectionView(_ titleSelectionView: TitleSelectionView) {
        self.titleSelectionView.isHidden = true
    }
}

// MARK: - UIDocumentPickerViewDelegate

extension VideoPlayerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let mediaURL = playbackService.currentlyPlayingMedia?.url else { return }
        guard let fileURL = urls.first else { return }
                
        let mediaURLPath = mediaURL.path
        let filename = mediaURL.lastPathComponent as NSString
        let fileManager = FileManager.default

        var searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        var documentFolderPath = searchPaths[0]
        let potentialInboxFolderPath = (documentFolderPath as NSString).appendingPathComponent("Inbox")

        var pathComponent = "\(filename.deletingPathExtension)"
        // if the media is not in the Documents folder, cache the subtitle file
        if (mediaURLPath.contains(potentialInboxFolderPath) && !mediaURLPath.contains(documentFolderPath)) || !mediaURL.isFileURL {
            searchPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            documentFolderPath = searchPaths[0]
            let cacheFolderPath = (documentFolderPath as NSString).appendingPathComponent(kVLCSubtitlesCacheFolderName)
            do {
                try fileManager.createDirectory(atPath: cacheFolderPath, withIntermediateDirectories: true)
            } catch {
                return
            }
            pathComponent = "\(kVLCSubtitlesCacheFolderName)/\(filename.deletingPathExtension)"
        }
        var destinationPath = (documentFolderPath as NSString).appendingPathComponent("\(pathComponent).\(fileURL.pathExtension)")
        var index = 0

        while fileManager.fileExists(atPath: destinationPath) {
            index += 1
            destinationPath = (documentFolderPath as NSString).appendingPathComponent("\(pathComponent)\(index).\(fileURL.pathExtension)")
        }

        if fileURL.startAccessingSecurityScopedResource() {
            do {
                try fileManager.copyItem(at: fileURL, to: URL(fileURLWithPath: destinationPath))
            } catch {
                return
            }
            fileURL.stopAccessingSecurityScopedResource()
            
            if fileURL.pathExtension.contains("srt") {
                playbackService.addSubtitlesToCurrentPlayback(from: URL(fileURLWithPath: destinationPath))
            } else {
                playbackService.addAudioToCurrentPlayback(from: URL(fileURLWithPath: destinationPath))
            }
            
        } else {
            return
        }
    }
}
