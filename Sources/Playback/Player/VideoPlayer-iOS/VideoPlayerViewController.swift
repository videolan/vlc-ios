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
    func videoPlayerViewControllerShouldSwitchPlayer(_ videoPlayerViewController: VideoPlayerViewController)
}

@objc(VLCVideoPlayerViewController)
class VideoPlayerViewController: PlayerViewController {
    @objc weak var delegate: VideoPlayerViewControllerDelegate?

    var playAsAudio: Bool = false

    // MARK: - Constants

    private let ZOOM_SENSITIVITY: CGFloat = 5

#if os(iOS)
    private let screenPixelSize = CGSize(width: UIScreen.main.bounds.width,
                                         height: UIScreen.main.bounds.height)
#else
    private let screenPixelSize: CGSize = {
        return UIApplication.shared.delegate?.window??.bounds.size
    }()!
#endif

    // MARK: - Private
    /// Stores previous playback speed for long press gesture
    /// to be able to restore playback speed to its previous state after long press ended.
    private var previousPlaybackSpeed: Float?

    // MARK: - 360

    private var fov: CGFloat = 0
    private lazy var deviceMotion: DeviceMotion = {
        let deviceMotion = DeviceMotion()
        deviceMotion.delegate = self
        return deviceMotion
    }()

    private var orientations = UIInterfaceOrientationMask.allButUpsideDown

    @objc override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return self.orientations }
        set { self.orientations = newValue }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - UI elements

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private var idleTimer: Timer?

#if os(iOS)
    override var prefersStatusBarHidden: Bool {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad && !playerController.isControlsHidden {
            return false
        }
        if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portrait && !playerController.isControlsHidden {
            return false
        }
        return true
    }
#endif

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

    private lazy var videoOutputViewLeadingConstraint: NSLayoutConstraint = {
        let videoOutputViewLeadingConstraint = videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        return videoOutputViewLeadingConstraint
    }()

    private lazy var videoOutputViewTrailingConstraint: NSLayoutConstraint = {
        let videoOutputViewTrailingConstraint = videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        return videoOutputViewTrailingConstraint
    }()

    private(set) lazy var videoPlayerControls: VideoPlayerControls = {
        let videoPlayerControls = Bundle.main.loadNibNamed("VideoPlayerControls",
                                                           owner: nil,
                                                           options: nil)?.first as! VideoPlayerControls
        videoPlayerControls.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerControls.setupAccessibility()
        videoPlayerControls.setupLongPressGestureRecognizer()
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

    private(set) lazy var aspectRatioActionSheet: MediaPlayerActionSheet = {
        var aspectRatioActionSheet = MediaPlayerActionSheet()
        aspectRatioActionSheet.dataSource = self
        aspectRatioActionSheet.delegate = self
        aspectRatioActionSheet.modalPresentationStyle = .custom
        aspectRatioActionSheet.numberOfColums = 2
        return aspectRatioActionSheet
    }()

    let notificationCenter = NotificationCenter.default

    private(set) lazy var titleSelectionView: TitleSelectionView = {
#if os(iOS)
        let isLandscape = UIDevice.current.orientation.isLandscape
        let titleSelectionView = TitleSelectionView(frame: .zero,
                                                    orientation: isLandscape ? .horizontal : .vertical)
#else
        let titleSelectionView = TitleSelectionView(frame: .zero, orientation: .horizontal)
#endif
        titleSelectionView.delegate = self
        titleSelectionView.isHidden = true
        return titleSelectionView
    }()

    private var projectionLocation: CGPoint = .zero

    private lazy var longPressPlaybackSpeedView: LongPressPlaybackSpeedView = {
        let view = LongPressPlaybackSpeedView()
        view.translatesAutoresizingMaskIntoConstraints = false

        view.layer.opacity = 0

        return view
    }()


    // MARK: - VideoOutput

    private lazy var topBottomBackgroundGradientLayer: CAGradientLayer = {
        let topBottomBackgroundGradientLayer = CAGradientLayer()

        topBottomBackgroundGradientLayer.frame = self.view.bounds
        topBottomBackgroundGradientLayer.colors = [UIColor.black.cgColor,
                                                   UIColor.clear.cgColor,
                                                   UIColor.clear.cgColor,
                                                   UIColor.black.cgColor]
        topBottomBackgroundGradientLayer.locations = [0, 0.3, 0.7, 1]
        return topBottomBackgroundGradientLayer
    }()

    private lazy var backgroundGradientView: UIView = {
        let backgroundGradientView = UIView()
        backgroundGradientView.frame = self.view.bounds
        backgroundGradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundGradientView.layer.addSublayer(topBottomBackgroundGradientLayer)
        return backgroundGradientView
    }()

    private var artWorkImageView: UIImageView = {
#if os(iOS)
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.width * 0.6)
#else
        let frame = UIApplication.shared.delegate!.window!!.bounds
#endif
        let artWorkImageView = UIImageView(frame: frame)
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

    /// An invisible button that resides in the middle of the screen which
    /// Switch Control will focus on when it is in Item mode. Tapping it will
    /// present the player controls.
    ///
    /// Without this, Switch Control uses Point mode, which is cumbersome.
    private var switchControlUtility: UIControl = {
        var switchControlUtility = UIControl()
        switchControlUtility.backgroundColor = .clear
        switchControlUtility.translatesAutoresizingMaskIntoConstraints = false
        switchControlUtility.isUserInteractionEnabled = true
        switchControlUtility.isAccessibilityElement = true
        switchControlUtility.addTarget(VideoPlayerViewController.self,
                                       action: #selector(handleTapOnVideo),
                                       for: .touchUpInside)

        return switchControlUtility
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
        tapOnVideoRecognizer.require(toFail: doubleTapGestureRecognizer)
        return tapOnVideoRecognizer
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

    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        return longPressRecognizer
    }()

    private var isGestureActive: Bool = false

    private var minimizationInitialCenter: CGPoint?

    // MARK: - Popup Views

    lazy var trackSelectorPopupView: PopupView = {
        let trackSelectorPopupView = PopupView()
        trackSelectorPopupView.delegate = self
        return trackSelectorPopupView
    }()

    // MARK: - Constraints

    private lazy var videoPlayerControlsHeightConstraint: NSLayoutConstraint = {
        videoPlayerControls.heightAnchor.constraint(equalToConstant: 44)
    }()

    private lazy var videoPlayerControlsBottomConstraint: NSLayoutConstraint = {
        videoPlayerControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                    constant: -5)
    }()

    private lazy var equalizerPopupTopConstraint: NSLayoutConstraint = {
        equalizerPopupView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
    }()

    private lazy var equalizerPopupBottomConstraint: NSLayoutConstraint = {
        equalizerPopupView.bottomAnchor.constraint(equalTo: mediaScrubProgressBar.topAnchor, constant: -10)
    }()

    private lazy var trackSelectorPopupTopConstraint: NSLayoutConstraint = {
        trackSelectorPopupView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
    }()

    private lazy var trackSelectorPopupBottomConstraint: NSLayoutConstraint = {
        trackSelectorPopupView.bottomAnchor.constraint(equalTo: mediaScrubProgressBar.topAnchor, constant: -10)
    }()

    // MARK: - Init methods

#if os(iOS)
    @objc override init(mediaLibraryService: MediaLibraryService, rendererDiscovererManager: VLCRendererDiscovererManager, playerController: PlayerController) {
        super.init(mediaLibraryService: mediaLibraryService, rendererDiscovererManager: rendererDiscovererManager, playerController: playerController)

        self.playerController.delegate = self
        self.mediaNavigationBar.addGestureRecognizer(minimizeGestureRecognizer)

        brightnessControlView.delegate = self
        volumeControlView.delegate = self
    }
#else
    @objc override init(mediaLibraryService: MediaLibraryService, playerController: PlayerController) {
        super.init(mediaLibraryService: mediaLibraryService, playerController: playerController)

        self.mediaLibraryService = mediaLibraryService
        self.playerController = playerController

        self.playerController.delegate = self
        systemBrightness = 1.0
        self.mediaNavigationBar.addGestureRecognizer(minimizeGestureRecognizer)
    }
#endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playbackService.delegate = self
        playbackService.recoverPlaybackState()
        playerController.lockedOrientation = .portrait
        navigationController?.navigationBar.isHidden = true
        mediaScrubProgressBar.updateInterfacePosition()

        setControlsHidden(false, animated: false)

        setupSeekDurations()

        // Make sure interface is enabled on
        setPlayerInterfaceEnabled(true)

        artWorkImageView.image = nil
        // FIXME: Test userdefault
#if os(iOS)
        let rendererDiscoverer = rendererDiscovererManager
        rendererDiscoverer.presentingViewController = self
        rendererDiscoverer.delegate = self
#endif

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

        if playbackService.adjustFilter.isEnabled {
            showIcon(button: optionsNavigationBar.videoFiltersButton)
        } else {
            hideIcon(button: optionsNavigationBar.videoFiltersButton)
        }

        view.transform = .identity

        self.longPressPlaybackSpeedView.layer.opacity = 0

        playbackService.restoreAudioAndSubtitleTrack()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

#if os(iOS)
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: kVLCPlayerShouldRememberBrightness) {
            if let brightness = defaults.value(forKey: KVLCPlayerBrightness) as? CGFloat {
                animateBrightness(to: brightness)
                self.brightnessControl.value = Float(brightness)
            }
        }
#endif

        playbackService.recoverDisplayedMetadata()

        // The video output view is not initialized when the play as audio option was chosen
        playbackService.videoOutputView = playbackService.playAsAudio ? nil : videoOutputView

        playModeUpdated()

        // Media is loaded in the media player, checking the projection type and configuring accordingly.
        setupForMediaProjection()

        moreOptionsActionSheet.resetOptionsIfNecessary()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Adjust the position of the AB Repeat marks if needed based on the device's orientation.
        mediaScrubProgressBar.adjustABRepeatMarks(aMark: aMark, bMark: bMark)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topBottomBackgroundGradientLayer.frame = self.view.bounds
#if os(iOS)
        brightnessBackgroundGradientLayer.frame = self.view.bounds
        volumeBackgroundGradientLayer.frame = self.view.bounds
#endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if playbackService.videoOutputView == videoOutputView && !playbackService.isPlayingOnExternalScreen() {
            playbackService.videoOutputView = nil
        }

        if idleTimer != nil {
            idleTimer?.invalidate()
            idleTimer = nil
        }

        // Reset lock interface on end of playback.
        playerController.isInterfaceLocked = false

#if os(iOS)
        volumeControlView.alpha = 0
        brightnessControlView.alpha = 0
#endif

        numberOfGestureSeek = 0
        totalSeekDuration = 0
        previousSeekState = .default
        titleSelectionView.isHidden = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deviceMotion.stopDeviceMotion()
#if os(iOS)
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: kVLCPlayerShouldRememberBrightness) {
            let currentBrightness = UIScreen.main.brightness
            self.brightnessControl.value = Float(currentBrightness) // helper in indicating change in the system brightness
            defaults.set(currentBrightness, forKey: KVLCPlayerBrightness)
        }

        //set the value of system brightness after closing the app x
        //even if the Player Should Remember Brightness option is disabled
        animateBrightness(to: systemBrightness!, duration: 0.35)

        // remove the observer when the view disappears to avoid breaking the brightness view value
        // when the video player is not shown to save the persisted values
        removePlayerBrightnessObservers()
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        setupObservers()
        setupViews()
        setupAccessibility()
        setupGestures()
        setupConstraints()
#if os(iOS)
        setupRendererDiscoverer()
#endif
    }

    // MARK: - Setup methods

    private func setupObservers() {
        try? AVAudioSession.sharedInstance().setActive(true)
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayerControls), name: .VLCDidAppendMediaToQueue, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayerControls), name: .VLCDidRemoveMediaFromQueue, object: nil)
    }

    private func setupViews() {
        view.backgroundColor = .black
        view.addSubview(mediaNavigationBar)
        hideSystemVolumeInfo()
        videoPlayerButtons()
        if playerController.isRememberStateEnabled {
            setupVideoControlsState()
        }

        view.addSubview(switchControlUtility)
        view.addSubview(optionsNavigationBar)
        view.addSubview(videoPlayerControls)
        view.addSubview(mediaScrubProgressBar)
        view.addSubview(videoOutputView)
#if os(iOS)
        view.addSubview(brightnessControlView)
        view.addSubview(volumeControlView)
#endif
        view.addSubview(externalVideoOutputView)
        view.addSubview(statusLabel)
        view.addSubview(titleSelectionView)
        view.addSubview(longPressPlaybackSpeedView)

        view.bringSubviewToFront(statusLabel)
        view.sendSubviewToBack(videoOutputView)
        view.insertSubview(backgroundGradientView, aboveSubview: videoOutputView)
#if os(iOS)
        view.insertSubview(sideBackgroundGradientView, aboveSubview: backgroundGradientView)
#endif
        videoOutputView.addSubview(artWorkImageView)
    }

    private func setupAccessibility() {

        if playerController.isControlsHidden {
            view.applyAccessibilityControls(
                switchControlUtility
            )

        } else {
#if os(iOS)
            view.applyAccessibilityControls(
                videoPlayerControls,
                mediaScrubProgressBar,
                volumeControlView,
                brightnessControlView,
                mediaNavigationBar
            )
#else
            view.applyAccessibilityControls(
                videoPlayerControls,
                mediaScrubProgressBar,
                mediaNavigationBar
            )
#endif

        }

        // - custom actions

        let playPause = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: ""),
                    image: .with(systemName: "playpause"),
                    target: self,
                    selector: #selector(handleAccessibilityPlayPause))

        let close = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("STOP_BUTTON", comment: ""),
                    image: .with(systemName: "xmark"),
                    target: self,
                    selector: #selector(handleAccessibilityClose))

        let forward = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("FWD_BUTTON", comment: ""),
                    image: .with(systemName: "plus.arrow.trianglehead.clockwise"),
                    target: self,
                    selector: #selector(handleAccessibilityForward))

        let backward = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("BWD_BUTTON", comment: ""),
                    image: .with(systemName: "minus.arrow.trianglehead.counterclockwise"),
                    target: self,
                    selector: #selector(handleAccessibilityBackward))

        let next = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("NEXT_HINT", comment: ""),
                    image: .with(systemName: "forward.end"),
                    target: self,
                    selector: #selector(handleAccessibilityNext))

        let prev = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("PREVIOUS_HINT", comment: ""),
                    image: .with(systemName: "backward.end"),
                    target: self,
                    selector: #selector(handleAccessibilityPrev))


        accessibilityCustomActions = [playPause, close, forward, backward, next, prev]
    }

    override func setupGestures() {
        super.setupGestures()
        view.addGestureRecognizer(tapOnVideoRecognizer)
        view.addGestureRecognizer(pinchRecognizer)
        view.addGestureRecognizer(doubleTapGestureRecognizer)
        view.addGestureRecognizer(playPauseRecognizer)
        view.addGestureRecognizer(panRecognizer)
        view.addGestureRecognizer(leftSwipeRecognizer)
        view.addGestureRecognizer(rightSwipeRecognizer)
        view.addGestureRecognizer(upSwipeRecognizer)
        view.addGestureRecognizer(downSwipeRecognizer)
        view.addGestureRecognizer(longPressGestureRecognizer)

        panRecognizer.require(toFail: leftSwipeRecognizer)
        panRecognizer.require(toFail: rightSwipeRecognizer)
    }

    private func setupConstraints() {
        setupVideoOutputConstraints()
        setupSwitchControlUtilityConstraints()
        setupExternalVideoOutputConstraints()
        setupVideoPlayerControlsConstraints()
        setupMediaNavigationBarConstraints()
        setupScrubProgressBarConstraints()
#if os(iOS)
        setupBrightnessControlConstraints()
        setupVolumeControlConstraints()
#endif
        setupStatusLabelConstraints()
        setupTitleSelectionConstraints()
        setupLongPressPlaybackSpeedConstraints()
    }

#if os(iOS)
    private func setupRendererDiscoverer() {
        rendererButton = rendererDiscovererManager.setupRendererButton()
        rendererButton.tintColor = .white
        if playbackService.renderer != nil {
            rendererButton.isSelected = true
        }

        mediaNavigationBar.chromeCastButton = rendererButton

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
#endif

    private func setupVideoControlsState() {
        let isShuffleEnabled = playerController.isShuffleEnabled
        let repeatMode = playerController.isRepeatEnabled
        playbackService.isShuffleMode = isShuffleEnabled
        playbackService.repeatMode = repeatMode
        playModeUpdated()
    }

    @objc func setupQueueViewController(qvc: QueueViewController) {
        queueViewController = qvc
        queueViewController?.delegate = self
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
        let bottomConstraint = slider.bottomAnchor.constraint(equalTo: mediaScrubProgressBar.topAnchor, constant: -10)
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let isLandscape: Bool = size.width >= view.frame.size.width

        titleSelectionView.mainStackView.axis = isLandscape ? .horizontal : .vertical
        titleSelectionView.mainStackView.distribution = isLandscape ? .fillEqually : .fill
    }

#if os(iOS)
    private func addPlayerBrightnessObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemBrightnessChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func removePlayerBrightnessObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
#endif

    // MARK: - Private helpers

#if os(iOS)
    private func setupBrightnessControlConstraints() {
        setupCommonSliderConstraints(for: brightnessControlView)
        NSLayoutConstraint.activate([
            brightnessControlView.leadingAnchor.constraint(equalTo: mediaScrubProgressBar.leadingAnchor),
            brightnessControlView.topAnchor.constraint(greaterThanOrEqualTo: optionsNavigationBar.bottomAnchor)
        ])
    }

    private func setupVolumeControlConstraints() {
        setupCommonSliderConstraints(for: volumeControlView)
        NSLayoutConstraint.activate([
            volumeControlView.trailingAnchor.constraint(equalTo: mediaScrubProgressBar.trailingAnchor),
            volumeControlView.topAnchor.constraint(greaterThanOrEqualTo: optionsNavigationBar.bottomAnchor)
        ])
    }
#endif

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

    private func setupSwitchControlUtilityConstraints() {
        NSLayoutConstraint.activate([
            switchControlUtility.heightAnchor.constraint(equalToConstant: 44),
            switchControlUtility.widthAnchor.constraint(equalToConstant: 44),
            switchControlUtility.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            switchControlUtility.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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
            mediaNavigationBar.leadingAnchor.constraint(equalTo: videoPlayerControls.leadingAnchor, constant: -8),
            mediaNavigationBar.trailingAnchor.constraint(equalTo: videoPlayerControls.trailingAnchor, constant: 8),
            mediaNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                    constant: padding),
            optionsNavigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            optionsNavigationBar.topAnchor.constraint(equalTo: mediaNavigationBar.bottomAnchor, constant: padding)
        ])
    }

    private func setupVideoPlayerControlsConstraints() {
        let padding: CGFloat = 8
        let minPadding: CGFloat = 5

        NSLayoutConstraint.activate([
            videoPlayerControlsHeightConstraint,
            videoPlayerControls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                         constant: padding),
            videoPlayerControls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                          constant: -padding),
            videoPlayerControls.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor,
                                                       constant: -2 * minPadding),
            videoPlayerControlsBottomConstraint
        ])
    }

    private func setupScrubProgressBarConstraints() {
        let margin: CGFloat = 12

        NSLayoutConstraint.activate([
            mediaScrubProgressBar.leadingAnchor.constraint(equalTo: videoPlayerControls.leadingAnchor),
            mediaScrubProgressBar.trailingAnchor.constraint(equalTo: videoPlayerControls.trailingAnchor),
            mediaScrubProgressBar.bottomAnchor.constraint(equalTo: videoPlayerControls.topAnchor, constant: -margin)
        ])
    }

    private func setupStatusLabelConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupLongPressPlaybackSpeedConstraints() {
        NSLayoutConstraint.activate([
            longPressPlaybackSpeedView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            longPressPlaybackSpeedView.centerYAnchor.constraint(equalTo: mediaNavigationBar.centerYAnchor)
        ])
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

    @objc private func handleAccessibilityPlayPause() -> Bool {
        togglePlayPause()
        return true
    }

    @objc private func handleAccessibilityClose() -> Bool {
        playbackService.stopPlayback()
        return true
    }

    @objc private func handleAccessibilityForward() -> Bool {
        jumpForwards()
        return true
    }

    @objc private func handleAccessibilityBackward() -> Bool {
        jumpBackwards()
        return true
    }

    @objc private func handleAccessibilityNext() -> Bool {
        playbackService.next()
        return true
    }

    @objc private func handleAccessibilityPrev() -> Bool {
        playbackService.previous()
        return true
    }

    // MARK: - Gesture handlers

    @objc override func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
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

    override func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        let screenWidth: CGFloat = view.frame.size.width
        let backwardBoundary: CGFloat = screenWidth / 3.0
        let forwardBoundary: CGFloat = 2 * screenWidth / 3.0

        let tapPosition = sender.location(in: view)

        // Reset number(set to -1/1) of seek when orientation has been changed.
        if tapPosition.x < backwardBoundary {
            numberOfGestureSeek = previousSeekState == .forward ? -1 : numberOfGestureSeek - 1
        } else if tapPosition.x > forwardBoundary {
            numberOfGestureSeek = previousSeekState == .backward ? 1 : numberOfGestureSeek + 1
        } else {
            playbackService.switchAspectRatio(true)
            return
        }

        super.handleDoubleTapGesture(sender)
    }

    override func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let currentPos = recognizer.location(in: view)

        // Limit the gesture to avoid conflicts with top and bottom player controls
        if currentPos.y > mediaScrubProgressBar.frame.origin.y
            || currentPos.y < mediaNavigationBar.frame.origin.y {
            recognizer.state = .ended
        }

        super.handlePanGesture(recognizer: recognizer)
    }

    override func handleSwipeGestures(recognizer: UISwipeGestureRecognizer) {
        // Limit y position in order to avoid conflicts with the scrub position controls
        guard recognizer.location(in: view).y < mediaScrubProgressBar.frame.origin.y else {
            return
        }

        super.handleSwipeGestures(recognizer: recognizer)
    }

    @objc func handleTapOnVideo() {
        if UserDefaults.standard.bool(forKey: kVLCSettingPauseWhenShowingControls) && playbackService.isPlaying {
            playbackService.pause()
        }

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
            mediaScrubProgressBar.spacing = scrubProgressBarSpacing
            view.layoutSubviews()
        }
    }

    func jumpBackwards(_ interval: Int = 10) {
        playbackService.jumpBackward(Int32(interval))
    }

    func jumpForwards(_ interval: Int = 10) {
        playbackService.jumpForward(Int32(interval))
    }

    @objc func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {
        let screenWidth: CGFloat = view.frame.size.width
        let backwardBoundary: CGFloat = screenWidth / 3.0
        let forwardBoundary: CGFloat = 2 * screenWidth / 3.0

        let tapPosition = recognizer.location(in: view)

        // Limit y position in order to avoid conflicts with the bottom controls
        if tapPosition.y > mediaScrubProgressBar.frame.origin.y {
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

    @objc private func handleLongPressGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard playerController.isSpeedUpGestureEnabled,
              playbackService.isPlaying else {
            return
        }

        switch gestureRecognizer.state {
        case .began:
            // Store previous playback speed
            previousPlaybackSpeed = playbackService.playbackRate
            // Hide controls
            setControlsHidden(true, animated: true)

            // Set playback speed
            if playbackService.playbackRate < 2 {
                playbackService.playbackRate = 2
            } else {
                let playbackSpeed = playbackService.playbackRate + 1
                playbackService.playbackRate = min(playbackSpeed, 8)
            }

            // Update view multiplier label
            longPressPlaybackSpeedView.speedMultiplier = playbackService.playbackRate

#if os(iOS)
            // Generate selection feedback
            UISelectionFeedbackGenerator().selectionChanged()
#endif

            // Show playback speed view
            UIView.transition(with: longPressPlaybackSpeedView, duration: 0.4, options: .transitionCrossDissolve) {
                self.longPressPlaybackSpeedView.layer.opacity = 1
            }
            break
        case .ended, .cancelled:
            // Set playback speed previous state
            playbackService.playbackRate = previousPlaybackSpeed ?? 1

            // Hide playback speed view
            UIView.transition(with: longPressPlaybackSpeedView, duration: 0.4, options: .transitionCrossDissolve) {
                self.longPressPlaybackSpeedView.layer.opacity = 0
            }
            break
        default:
            break
        }
    }

    // MARK: - Observers

#if os(iOS)
    @objc func systemVolumeDidChange(notification: NSNotification) {
        let volumelevel = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"]
        UIView.transition(with: volumeControlView, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations : {
            self.volumeControlView.updateIcon(level: volumelevel as! Float)

        })
    }
#endif

    // MARK: - Public helpers

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

    override func setControlsHidden(_ hidden: Bool, animated: Bool) {
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
#if os(iOS)
            self?.volumeControlView.alpha = playerController.isVolumeGestureEnabled ? uiComponentOpacity : 0
            self?.brightnessControlView.alpha = playerController.isBrightnessGestureEnabled ? uiComponentOpacity : 0
#endif
            if !hidden || qvcHidden {
                self?.videoPlayerControls.alpha = uiComponentOpacity
                self?.mediaScrubProgressBar.alpha = uiComponentOpacity
            }
            self?.backgroundGradientView.alpha = hidden && qvcHidden ? 0 : 1
#if os(iOS)
            if hidden {
                self?.sideBackgroundGradientView.alpha = 0
            }
#endif
        }

        let duration = animated ? 0.2 : 0
        UIView.animate(withDuration: duration, delay: 0,
                       options: .beginFromCurrentState, animations: animations,
                       completion: { _ in
            self.switchControlUtility.alpha = hidden ? 1 : 0
            self.setupAccessibility()
        })
#if os(iOS)
        self.setNeedsStatusBarAppearanceUpdate()
#endif
    }

    @objc override func updatePlayerControls() {
        videoPlayerControls.shouldEnableSeekButtons(playbackService.mediaList.count == 1)
    }

    override func minimizePlayer() {
        delegate?.videoPlayerViewControllerDidMinimize(self)
    }

    override func shouldDisableGestures(_ disable: Bool) {
        super.shouldDisableGestures(disable)

        tapOnVideoRecognizer.isEnabled = !disable
        upSwipeRecognizer.isEnabled = !disable
        downSwipeRecognizer.isEnabled = !disable
    }

    override func showPopup(_ popupView: PopupView, with contentView: UIView, accessoryViewsDelegate: PopupViewAccessoryViewsDelegate? = nil) {
        super.showPopup(popupView, with: contentView, accessoryViewsDelegate: accessoryViewsDelegate)

        videoPlayerControls.moreActionsButton.isEnabled = false

        let iPhone5width: CGFloat = 320
        let leadingConstraint = popupView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10)
        let trailingConstraint = popupView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
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

        NSLayoutConstraint.activate([
            popupViewTopConstraint,
            popupViewBottomConstraint,
            leadingConstraint,
            trailingConstraint,
            popupView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            popupView.widthAnchor.constraint(greaterThanOrEqualToConstant: iPhone5width)
        ])
    }

    // MARK: - Private helpers

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
        let constant: CGFloat = playbackService.currentAspectRatio != AspectRatio.fillToScreen.rawValue ? 30.0 : 0.0
#if os(iOS)
        let interfaceOrientation = UIApplication.shared.statusBarOrientation

        if interfaceOrientation == .landscapeLeft
            || interfaceOrientation == .landscapeRight {
            videoOutputViewLeadingConstraint.constant = constant
            videoOutputViewTrailingConstraint.constant = -constant
        } else {
            videoOutputViewLeadingConstraint.constant = 0
            videoOutputViewTrailingConstraint.constant = 0
        }
#else
        videoOutputViewLeadingConstraint.constant = 0
        videoOutputViewTrailingConstraint.constant = 0
#endif
        videoOutputView.layoutIfNeeded()
    }

    private func changeVideoOutput(to output: UIView?) {
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
        let intervalSetting = UserDefaults.standard
            .integer(forKey: kVLCSettingPlayerControlDuration)

        let interval = TimeInterval(max(intervalSetting, 4))

        guard let safeIdleTimer = idleTimer else {
            idleTimer = Timer.scheduledTimer(timeInterval: interval,
                                             target: self,
                                             selector: #selector(handleIdleTimerExceeded),
                                             userInfo: nil,
                                             repeats: false)
            return
        }

        if fabs(safeIdleTimer.fireDate.timeIntervalSinceNow) < interval {
            safeIdleTimer.fireDate = Date(timeIntervalSinceNow: interval)
        }
    }

    private func executeSeekFromGesture(_ type: PlayerSeekGestureType) {

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

        displayAndApplySeekDuration(currentSeek)
    }

    private func applyCustomEqualizerProfileIfNeeded() {
        let userDefaults = UserDefaults.standard
        guard userDefaults.bool(forKey: kVLCCustomProfileEnabled) else {
            return
        }

        let profileIndex = userDefaults.integer(forKey: kVLCSettingEqualizerProfile)
        let encodedData = userDefaults.data(forKey: kVLCCustomEqualizerProfiles)

        guard let encodedData = encodedData,
              let customProfiles = NSKeyedUnarchiver(forReadingWith: encodedData).decodeObject(forKey: "root") as? CustomEqualizerProfiles,
              profileIndex < customProfiles.profiles.count else {
            return
        }

        let selectedProfile = customProfiles.profiles[profileIndex]
        playbackService.preAmplification = CGFloat(selectedProfile.preAmpLevel)

        for (index, frequency) in selectedProfile.frequencies.enumerated() {
            playbackService.setAmplification(CGFloat(frequency), forBand: UInt32(index))
        }
    }

    private func hideSystemVolumeInfo() {
#if os(iOS)
        volumeView.alpha = 0.00001
        view.addSubview(volumeView)
#endif
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

    private func setPlayerInterfaceEnabled(_ enabled: Bool) {
        mediaNavigationBar.closePlaybackButton.isEnabled = enabled
        mediaNavigationBar.queueButton.isEnabled = enabled
#if os(iOS)
        mediaNavigationBar.airplayRoutePickerView.isUserInteractionEnabled = enabled
        mediaNavigationBar.airplayRoutePickerView.alpha = !enabled ? 0.5 : 1
#endif

        mediaScrubProgressBar.progressSlider.isEnabled = enabled
        mediaScrubProgressBar.remainingTimeButton.isEnabled = enabled

        optionsNavigationBar.videoFiltersButton.isEnabled = enabled
        optionsNavigationBar.playbackSpeedButton.isEnabled = enabled
        optionsNavigationBar.equalizerButton.isEnabled = enabled
        optionsNavigationBar.sleepTimerButton.isEnabled = enabled
        optionsNavigationBar.abRepeatButton.isEnabled = enabled
        optionsNavigationBar.abRepeatMarksButton.isEnabled = enabled

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
        doubleTapGestureRecognizer.isEnabled = enabled
        pinchRecognizer.isEnabled = enabled
        rightSwipeRecognizer.isEnabled = enabled
        leftSwipeRecognizer.isEnabled = enabled
        upSwipeRecognizer.isEnabled = enabled
        downSwipeRecognizer.isEnabled = enabled
        panRecognizer.isEnabled = enabled

#if os(iOS)
        brightnessControlView.isEnabled(enabled)
        volumeControlView.isEnabled(enabled)
#endif

        playerController.isInterfaceLocked = !enabled
    }
}

// MARK: - Delegation

// MARK: - VLCPlaybackServiceDelegate

extension VideoPlayerViewController {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        mediaNavigationBar.setMediaTitleLabelText("")
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.isPlaying)

        // FIXME: -
        resetIdleTimer()
    }

    override func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                          isPlaying: Bool,
                                          currentMediaHasTrackToChooseFrom: Bool, currentMediaHasChapters: Bool,
                                          for playbackService: PlaybackService) {
        super.mediaPlayerStateChanged(currentState,
                                      isPlaying: isPlaying,
                                      currentMediaHasTrackToChooseFrom: currentMediaHasTrackToChooseFrom,
                                      currentMediaHasChapters: currentMediaHasChapters,
                                      for: playbackService)

        videoPlayerControls.updatePlayPauseButton(toState: isPlaying)
        videoPlayerControls.shouldEnableSeekButtons(playbackService.mediaList.count == 1)

        if currentState == .error {
            statusLabel.showStatusMessage(NSLocalizedString("PLAYBACK_FAILED",
                                                            comment: ""))
        }

        if currentState == .opening || currentState == .stopped {
            resetABRepeat()
        }

        let media = VLCMLMedia(forPlaying: playbackService.currentlyPlayingMedia)
        if let media = media, currentState == .opening &&
            (media.type() == .audio && playbackService.numberOfVideoTracks == 0) {
            // This media is audio only and can be played with the Audio Player.
            delegate?.videoPlayerViewControllerShouldSwitchPlayer(self)
            return
        }

        if titleSelectionView.isHidden == false {
            titleSelectionView.updateHeightConstraints()
            titleSelectionView.reload()
        }

        if let queueCollectionView = queueViewController?.queueCollectionView {
            queueCollectionView.reloadData()
        }

        moreOptionsActionSheet.currentMediaHasChapters = currentMediaHasChapters

        if currentState == .opening {
            updateAudioInterface(with: playbackService.metadata)
            if UserDefaults.standard.bool(forKey: kVLCSettingRotationLock) {
                videoPlayerControls.handleRotationLockButton(videoPlayerControls)
            }
        }

        if currentState == .stopped {
            supportedInterfaceOrientations = .allButUpsideDown
            videoPlayerControls.rotationLockButton.tintColor = .white
        }
    }

    func playbackServiceDidSwitchAspectRatio(_ aspectRatio: Int) {
        adaptVideoOutputToNotch()
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
#if os(iOS)
            if let renderer = playbackService.renderer {
                externalVideoOutputView.updateUI(rendererName: playbackService.renderer?.name, title: metadata.title)
            }
#else
            externalVideoOutputView.updateUI(rendererName: nil, title: metadata.title)
#endif
        } else {
            self.externalVideoOutputView.isHidden = true
        }

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
#if os(iOS)
            artWorkImageView.isHidden = playbackService.renderer != nil ? true : false
#else
            artWorkImageView.isHidden = false
#endif
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

    override func reloadPlayQueue() {
        guard let queueViewController = queueViewController else {
            return
        }

        queueViewController.reload()
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
}

// MARK: - MediaNavigationBarDelegate

extension VideoPlayerViewController {
    override func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar) {
        super.mediaNavigationBarDidTapClose(mediaNavigationBar)
        playbackService.playAsAudio = false
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
            view.bringSubviewToFront(mediaScrubProgressBar)
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

    override func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar) {
        delegate?.videoPlayerViewControllerDidMinimize(self)
    }

    func mediaNavigationBarDisplayCloseAlert(_ mediaNavigationBar: MediaNavigationBar) {
        statusLabel.showStatusMessage(NSLocalizedString("MINIMIZE_HINT", comment: ""))
    }

    func mediaNavigationBarDidTapPictureInPicture(_ mediaNavigationBar: MediaNavigationBar) {
        playbackService.togglePictureInPicture()
    }
}

// MARK: - MediaScrubProgressBarDelegate

extension VideoPlayerViewController {
    func mediaScrubProgressBarShouldResetIdleTimer() {
        resetIdleTimer()
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension VideoPlayerViewController {
    override func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
#if os(iOS)
        let mask = getInterfaceOrientationMask(orientation: UIApplication.shared.statusBarOrientation)

        supportedInterfaceOrientations = supportedInterfaceOrientations == .allButUpsideDown ? mask : .allButUpsideDown
#endif

        setPlayerInterfaceEnabled(!state)
    }

    func mediaMoreOptionsActionSheetDidAppeared() {
        handleTapOnVideo()
    }

    override func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .videoFilters:
            showIcon(button: optionsNavigationBar.videoFiltersButton)
            break
        default:
            super.mediaMoreOptionsActionSheetShowIcon(for: option)
        }
    }

    override func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .videoFilters:
            hideIcon(button: optionsNavigationBar.videoFiltersButton)
            break
        default:
            super.mediaMoreOptionsActionSheetHideIcon(for: option)
        }
    }

    override func mediaMoreOptionsActionSheetDisplayAddBookmarksView(_ bookmarksView: AddBookmarksView) {
        super.mediaMoreOptionsActionSheetDisplayAddBookmarksView(bookmarksView)

        if let bookmarksView = addBookmarksView {
            view.addSubview(bookmarksView)
            NSLayoutConstraint.activate([
                bookmarksView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                bookmarksView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                bookmarksView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                bookmarksView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                bookmarksView.bottomAnchor.constraint(lessThanOrEqualTo: mediaScrubProgressBar.topAnchor),
            ])
        }

        if let safeIdleTimer = idleTimer {
            safeIdleTimer.invalidate()
        }

        videoPlayerControls.shouldDisableControls(true)
        setControlsHidden(true, animated: true)
    }

    override func mediaMoreOptionsActionSheetRemoveAddBookmarksView() {
        super.mediaMoreOptionsActionSheetRemoveAddBookmarksView()

        idleTimer = nil
        resetIdleTimer()
        videoPlayerControls.shouldDisableControls(false)
    }

    override func mediaMoreOptionsActionSheetDidToggleShuffle(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        videoPlayerControlsDelegateShuffle(videoPlayerControls)
        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    override func mediaMoreOptionsActionSheetDidTapRepeat(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        videoPlayerControlsDelegateRepeat(videoPlayerControls)
        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    override func mediaMoreOptionsActionSheetPresentABRepeatView(with abView: ABRepeatView) {
        super.mediaMoreOptionsActionSheetPresentABRepeatView(with: abView)

        guard let abRepeatView = abRepeatView else {
            return
        }

        view.addSubview(abRepeatView)
        view.bringSubviewToFront(abRepeatView)
        abRepeatView.isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            abRepeatView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            abRepeatView.bottomAnchor.constraint(equalTo: mediaScrubProgressBar.topAnchor, constant: -20.0),
        ])
    }
}

// MARK: - OptionsNavigationBarDelegate

extension VideoPlayerViewController {
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

    private func resetABRepeatMarks(_ shouldDisplayView: Bool = false) {
        hideIcon(button: optionsNavigationBar.abRepeatMarksButton)
        aMark.removeFromSuperview()
        aMark.isEnabled = false

        bMark.removeFromSuperview()
        bMark.isEnabled = false

        guard let abRepeatView = abRepeatView,
              shouldDisplayView else {
            return
        }

        mediaMoreOptionsActionSheetPresentABRepeatView(with: abRepeatView)
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
        case optionsNavigationBar.abRepeatButton:
            resetABRepeat()
            return
        case optionsNavigationBar.abRepeatMarksButton:
            resetABRepeatMarks(true)
            return
        default:
            assertionFailure("VideoPlayerViewController: Invalid button.")
        }
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

// MARK: - PopupViewDelegate

extension VideoPlayerViewController {
    override func popupViewDidClose(_ popupView: PopupView) {
        super.popupViewDidClose(popupView)
        videoPlayerControls.moreActionsButton.isEnabled = true
        videoPlayerControlsHeightConstraint.constant = 44
        mediaScrubProgressBar.spacing = 5
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
        guard let mediaURL = playbackService.currentlyPlayingMedia?.url,
              let fileURL = urls.first else {
            return
        }

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

// MARK: - ActionSheetDelegate

extension VideoPlayerViewController: ActionSheetDelegate {
    func headerViewTitle() -> String? {
        return NSLocalizedString("ASPECT_RATIO_TITLE", comment: "")
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        return AspectRatio(rawValue: indexPath.row)
    }

    func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath) {
        guard let aspectRatio = item as? AspectRatio else {
            return
        }

        playbackService.setCurrentAspectRatio(aspectRatio.rawValue)
        showStatusMessage(String(format: NSLocalizedString("AR_CHANGED", comment: ""), aspectRatio.stringToDisplay))
    }
}

// MARK: - ActionSheetDataSource

extension VideoPlayerViewController: ActionSheetDataSource {
    func numberOfRows() -> Int {
        return AspectRatio.allCases.count
    }

    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActionSheetCell.identifier,
            for: indexPath) as? ActionSheetCell else {
            assertionFailure("VideoPlayerViewController: AspectRatioActionSheet: Unable to dequeue reusable cell")
            return UICollectionViewCell()
        }

        let aspectRatio = AspectRatio(rawValue: indexPath.row)

        guard let aspectRatio = aspectRatio else {
            assertionFailure("VideoPlayerViewController: AspectRatioActionSheet: Unable to retrieve the selected aspect ratio")
            return UICollectionViewCell()
        }

        let colors: ColorPalette = PresentationTheme.currentExcludingWhite.colors
        let isSelected = indexPath.row == playbackService.currentAspectRatio
        cell.configure(with: aspectRatio.stringToDisplay, colors: colors, isSelected: isSelected)
        cell.delegate = self

        return cell
    }
}

// MARK: - ActionSheetCellDelegate

extension VideoPlayerViewController: ActionSheetCellDelegate {
    func actionSheetCellShouldUpdateColors() -> Bool {
        return true
    }
}

// MARK: - SliderInfoViewDelegate

extension VideoPlayerViewController: SliderInfoViewDelegate {
    func sliderInfoViewDidReceiveTouch(_ sliderInfoView: SliderInfoView) {
        resetIdleTimer()
    }
}
