/*****************************************************************************
 * VideoPlayerViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (C) 2020-2026 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Pratik Ray <raypratik365@gmail.com>
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

    // MARK: - Constants

    private let ZOOM_SENSITIVITY: CGFloat = 5

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

#if os(iOS) && canImport(MediaIntents) // iOS 27 SDK
    @available(iOS 27.1, *)
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        return .disabled
    }
#elseif os(iOS)
    @objc var preferredVerticalBarBehavior: Int {
        return 1
    }
#endif

    // MARK: - UI elements

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private var idleTimer: Timer?

    private var isQueueCardShown = false

    private static let queueCardSpacing: CGFloat = 12

    private var queueCardConstraints: [NSLayoutConstraint] = []

    private let queueCardTransportAreaGuide = UILayoutGuide()

    var isCompactPortraitLayout: Bool {
        return isBookLayout
            || (traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular)
    }

#if os(iOS)
    override var prefersStatusBarHidden: Bool {
        if isViewLoaded && mediaNavigationBarLayout.placement == .besideCamera {
            return true
        }
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad && !playerController.isControlsHidden {
            return false
        }
        if view.bounds.height > view.bounds.width && !playerController.isControlsHidden {
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
        let videoPlayerControls = VideoPlayerControls()
        videoPlayerControls.setupAccessibility()
        videoPlayerControls.setupLongPressGestureRecognizer()
        videoPlayerControls.delegate = self
        let isIPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if isIPad {
            videoPlayerControls.rotationLockButton.isHidden = true
        } else {
            let largeConfig = UIImage.SymbolConfiguration(scale: .large)
            let image = UIImage(systemName: "lock.rotation")?.withConfiguration(largeConfig)
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

    // Intent for the next external-file pick: true = audio, false = subtitle, nil = decide by extension.
    private var externalTrackRequestIsAudio: Bool?

    private var delayViewHideTimer: Timer?

    private var delayView: PlaybackDelayView? {
        return overlayCardView as? PlaybackDelayView
    }

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
        topBottomBackgroundGradientLayer.colors = [UIColor.black.withAlphaComponent(0.5).cgColor,
                                                   UIColor.clear.cgColor,
                                                   UIColor.clear.cgColor,
                                                   UIColor.black.withAlphaComponent(0.55).cgColor]
        return topBottomBackgroundGradientLayer
    }()

    private static let topScrimHeight: CGFloat = 120
    private static let bottomScrimHeight: CGFloat = 150

    private lazy var backgroundGradientView: UIView = {
        let backgroundGradientView = UIView()
        backgroundGradientView.frame = self.view.bounds
        backgroundGradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundGradientView.layer.addSublayer(topBottomBackgroundGradientLayer)
        return backgroundGradientView
    }()

    private var artworkImageView: VLCArtworkImageView = {
        let artworkImageView = VLCArtworkImageView(frame: .zero)
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        return artworkImageView
    }()

    private var videoOutputView: UIView = {
        var videoOutputView = UIView()
        videoOutputView.backgroundColor = .black
        videoOutputView.isUserInteractionEnabled = false
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false

        videoOutputView.accessibilityIgnoresInvertColors = true
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
    private lazy var switchControlUtility: UIControl = {
        var switchControlUtility = UIControl()
        switchControlUtility.backgroundColor = .clear
        switchControlUtility.translatesAutoresizingMaskIntoConstraints = false
        switchControlUtility.isUserInteractionEnabled = true
        switchControlUtility.isAccessibilityElement = true
        switchControlUtility.addTarget(self,
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

    private lazy var snapshotTapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleSnapshotGesture(_:)))
        recognizer.numberOfTouchesRequired = 3
        return recognizer
    }()

    // MARK: - Constraints

    private lazy var videoPlayerControlsHeightConstraint: NSLayoutConstraint = {
        videoPlayerControls.heightAnchor.constraint(equalToConstant: 44)
    }()

    private let videoAreaLayoutGuide = UILayoutGuide()

    private lazy var videoAreaBottomConstraint: NSLayoutConstraint = {
        videoAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    }()

    private let interfaceAreaLayoutGuide = UILayoutGuide()

    private lazy var interfaceAreaLeadingConstraint: NSLayoutConstraint = {
        interfaceAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    }()

    private let safeInterfaceAreaLayoutGuide = UILayoutGuide()

    private var isBookLayout = false

    private let controlsAreaLayoutGuide = UILayoutGuide()

    private lazy var controlsAreaTopConstraint: NSLayoutConstraint = {
        controlsAreaLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor)
    }()

    private static let mediaNavigationBarTopPadding: CGFloat = 16

    private lazy var mediaNavigationBarLayout = MediaNavigationBarLayout(
        navigationBar: mediaNavigationBar,
        container: view,
        leftAnchor: controlsAreaLayoutGuide.leftAnchor,
        rightAnchor: controlsAreaLayoutGuide.rightAnchor,
        horizontalInset: 0,
        topPadding: VideoPlayerViewController.mediaNavigationBarTopPadding)

    let queueCardBottomLayoutGuide = UILayoutGuide()

    private lazy var bottomRowRegularConstraints: [NSLayoutConstraint] = [
        videoPlayerControls.rightAnchor.constraint(equalTo: controlsAreaLayoutGuide.rightAnchor),
        videoPlayerControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        queueCardBottomLayoutGuide.bottomAnchor.constraint(equalTo: videoPlayerControls.bottomAnchor),
    ]

    private lazy var videoPlayerControlsBesideCameraCenterYConstraint: NSLayoutConstraint = {
        let constraint = videoPlayerControls.centerYAnchor.constraint(equalTo: view.topAnchor)
        constraint.priority = .required - 1
        return constraint
    }()

    private lazy var videoPlayerControlsBesideCameraRightConstraint: NSLayoutConstraint = {
        videoPlayerControls.rightAnchor.constraint(equalTo: view.leftAnchor)
    }()

    private lazy var queueCardAboveCameraBottomConstraint: NSLayoutConstraint = {
        queueCardBottomLayoutGuide.bottomAnchor.constraint(equalTo: view.topAnchor)
    }()

    private lazy var bottomRowBesideCameraConstraints: [NSLayoutConstraint] = [
        videoPlayerControlsBesideCameraRightConstraint,
        videoPlayerControlsBesideCameraCenterYConstraint,
        videoPlayerControls.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
        queueCardAboveCameraBottomConstraint,
    ]

    private var isBottomRowBesideCamera = false

    private lazy var transportControlsCenterXConstraint: NSLayoutConstraint = {
        videoPlayerControls.transportControls.centerXAnchor.constraint(equalTo: interfaceAreaLayoutGuide.centerXAnchor)
    }()

    private lazy var transportControlsCenterYConstraint: NSLayoutConstraint = {
        videoPlayerControls.transportControls.centerYAnchor.constraint(equalTo: controlsAreaLayoutGuide.centerYAnchor)
    }()

    private lazy var transportControlsAboveScrubBarConstraint: NSLayoutConstraint = {
        // Limit height relative to the fixed bar; the scrub bar expands during scrubbing.
        let constraint = videoPlayerControls.transportControls.bottomAnchor.constraint(
            lessThanOrEqualTo: videoPlayerControls.topAnchor, constant: -68)
        constraint.priority = .required - 1
        return constraint
    }()

    private static let controlsMinimumMargin: CGFloat = 16

    private static let scrubProgressBarSpacing: CGFloat = 12

    private lazy var scrubProgressBarRightInRowConstraint: NSLayoutConstraint = {
        mediaScrubProgressBar.rightAnchor.constraint(equalTo: videoPlayerControls.rightControls.leftAnchor,
                                                     constant: -Self.scrubProgressBarSpacing)
    }()

    private lazy var scrubProgressBarLeftInRowConstraint: NSLayoutConstraint = {
        mediaScrubProgressBar.leftAnchor.constraint(equalTo: videoPlayerControls.leftControls.rightAnchor,
                                                    constant: Self.scrubProgressBarSpacing)
    }()

    private lazy var scrubProgressBarInRowConstraints: [NSLayoutConstraint] = [
        scrubProgressBarLeftInRowConstraint,
        scrubProgressBarRightInRowConstraint,
        mediaScrubProgressBar.bottomAnchor.constraint(equalTo: videoPlayerControls.bottomAnchor),
    ]

    private lazy var scrubProgressBarAboveRowConstraints: [NSLayoutConstraint] = [
        mediaScrubProgressBar.leftAnchor.constraint(equalTo: videoPlayerControls.leftAnchor),
        mediaScrubProgressBar.rightAnchor.constraint(equalTo: videoPlayerControls.rightAnchor),
        mediaScrubProgressBar.bottomAnchor.constraint(equalTo: videoPlayerControls.topAnchor,
                                                      constant: -Self.scrubProgressBarSpacing),
    ]

    private var isScrubProgressBarAboveRow = false

    // MARK: - Init methods

#if os(iOS)
    @objc init(mediaLibraryService: MediaLibraryService,
               rendererDiscovererManager: VLCRendererDiscovererManager,
               playerController: PlayerController) {
        super.init(mediaLibraryService: mediaLibraryService,
                   rendererDiscovererManager: rendererDiscovererManager,
                   playerController: playerController,
                   isBrightnessControlAvailable: true)

        self.playerController.delegate = self
        self.gameControllerManager.delegate = self
        self.mediaNavigationBar.addGestureRecognizer(minimizeGestureRecognizer)

        brightnessControlView.delegate = self
        volumeControlView.delegate = self
    }
#else
    @objc override init(mediaLibraryService: MediaLibraryService, playerController: PlayerController) {
        super.init(mediaLibraryService: mediaLibraryService, playerController: playerController)

        self.playerController.delegate = self
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
        navigationController?.navigationBar.isHidden = true
        mediaScrubProgressBar.updateInterfacePosition()

        setControlsHidden(false, animated: false)
        videoPlayerControls.updateSkipButtonImages(backwardBy: seekBackwardBy, forwardBy: seekForwardBy)

        // Make sure interface is enabled on
        setPlayerInterfaceEnabled(true)

        artworkImageView.setImage(nil, placeholderName: nil)
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

        adaptVideoOutputToNotch()

        updateVideoFiltersIcon()

        view.transform = .identity

        self.longPressPlaybackSpeedView.layer.opacity = 0

        playbackService.restoreAudioAndSubtitleTrack()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playbackService.recoverDisplayedMetadata()

        // The video output view is not initialized when the play as audio option was chosen
        playbackService.videoOutputView = playbackService.playAsAudio ? nil : videoOutputView

        playModeUpdated()

        // Media is loaded in the media player, checking the projection type and configuring accordingly.
        setupForMediaProjection()

        moreOptionsActionSheet.updateThemes()
        gameControllerManager.startMonitoring()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Adjust the position of the AB Repeat marks if needed based on the device's orientation.
        mediaScrubProgressBar.adjustABRepeatMarks(aMark: aMark, bMark: bMark)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let interfaceAreaFrame = interfaceAreaLayoutGuide.layoutFrame
        topBottomBackgroundGradientLayer.frame = interfaceAreaFrame
        let height = view.bounds.height
        if height > 0 {
            let topScrimEnd = min(VideoPlayerViewController.topScrimHeight / height, 0.5)
            let bottomScrimStart = max(1 - VideoPlayerViewController.bottomScrimHeight / height, 0.5)
            topBottomBackgroundGradientLayer.locations = [0, topScrimEnd as NSNumber, bottomScrimStart as NSNumber, 1]
        }
#if os(iOS)
        brightnessBackgroundGradientLayer.frame = interfaceAreaFrame
        volumeBackgroundGradientLayer.frame = interfaceAreaFrame

        // The fold has no change notification, so it is checked on each layout pass.
        updateReservedRegionLayout()
#endif
    }

#if os(iOS)
    private var tabletopFoldFrame: CGRect? {
        let bounds = view.bounds
        return activeReservedRegions(ofKind: "divisionRegionKind")
            .map(\.frame)
            .first { $0.width > $0.height && $0.minY > bounds.minY && $0.maxY < bounds.maxY }
    }

    private var bookFoldFrame: CGRect? {
        let bounds = view.bounds
        return activeReservedRegions(ofKind: "divisionRegionKind")
            .map(\.frame)
            .first { $0.height > $0.width && $0.minX > bounds.minX && $0.maxX < bounds.maxX }
    }

    private var bottomRightCameraRegion: (frame: CGRect, margins: UIEdgeInsets)? {
        let bounds = view.bounds
        return activeReservedRegions(ofKind: "occlusionRegionKind")
            .first {
                $0.frame.maxY >= bounds.maxY && $0.frame.inset(by: $0.margins).minY > bounds.midY
                    && $0.frame.minX > bounds.midX
            }
    }

    private func updateReservedRegionLayout() {
        let foldFrame = tabletopFoldFrame
        let bookFold = bookFoldFrame
        let isRightToLeft = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let usesLeftHalf = bookFold == nil || isRightToLeft
        let usesRightHalf = bookFold == nil || !isRightToLeft
        let bottomCameraRegion = foldFrame == nil && usesRightHalf ? bottomRightCameraRegion : nil
        let videoAreaBottomConstant = foldFrame.map { $0.minY - view.bounds.maxY } ?? 0
        let controlsAreaTopConstant = foldFrame?.maxY ?? 0
        let interfaceAreaLeadingConstant = bookFold.map {
            isRightToLeft ? view.bounds.maxX - $0.minX : $0.maxX
        } ?? 0

        if videoAreaBottomConstraint.constant != videoAreaBottomConstant {
            videoAreaBottomConstraint.constant = videoAreaBottomConstant
        }

        if interfaceAreaLeadingConstraint.constant != interfaceAreaLeadingConstant {
            interfaceAreaLeadingConstraint.constant = interfaceAreaLeadingConstant
        }

        if controlsAreaTopConstraint.constant != controlsAreaTopConstant {
            controlsAreaTopConstraint.constant = controlsAreaTopConstant
        }

        if let bottomCameraRegion {
            let cameraCenterY = bottomCameraRegion.frame.inset(by: bottomCameraRegion.margins).midY
            if videoPlayerControlsBesideCameraCenterYConstraint.constant != cameraCenterY {
                videoPlayerControlsBesideCameraCenterYConstraint.constant = cameraCenterY
            }

            if videoPlayerControlsBesideCameraRightConstraint.constant != bottomCameraRegion.frame.minX {
                videoPlayerControlsBesideCameraRightConstraint.constant = bottomCameraRegion.frame.minX
            }

            if queueCardAboveCameraBottomConstraint.constant != bottomCameraRegion.frame.minY {
                queueCardAboveCameraBottomConstraint.constant = bottomCameraRegion.frame.minY
            }
        }

        let isBesideCamera = bottomCameraRegion != nil
        if isBesideCamera != isBottomRowBesideCamera {
            isBottomRowBesideCamera = isBesideCamera
            if isBesideCamera {
                NSLayoutConstraint.deactivate(bottomRowRegularConstraints)
                NSLayoutConstraint.activate(bottomRowBesideCameraConstraints)
            } else {
                NSLayoutConstraint.deactivate(bottomRowBesideCameraConstraints)
                NSLayoutConstraint.activate(bottomRowRegularConstraints)
            }
        }

        let isBookFold = bookFold != nil
        if isBookFold != isBookLayout {
            isBookLayout = isBookFold
            if isQueueCardShown && isCompactPortraitLayout != isScrubProgressBarAboveRow {
                queueViewController?.dismissPlayqueue()
            }
            updateScrubProgressBarPlacement()
        }

        if mediaNavigationBarLayout.update(tabletopFold: foldFrame,
                                           camera: usesLeftHalf ? topLeftCameraRegion : nil,
                                           statusBar: usesRightHalf ? topRightCameraRegion : nil,
                                           statusBarCenterY: topBarLayoutGuide?.layoutFrame.midY) {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
#endif

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
        if playerController.isInterfaceLocked {
            setPlayerInterfaceEnabled(true)
        }

#if os(iOS)
        volumeControlView.setVisible(false)
        brightnessControlView.setVisible(false)
#endif
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deviceMotion.stopDeviceMotion()
        gameControllerManager.stopMonitoring()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        setupViews()
        setupAccessibility()
        setupConstraints()
#if os(iOS)
        setupRendererDiscoverer()
#endif
    }

    // MARK: - Setup methods

    private func setupViews() {
        view.backgroundColor = .black
        view.addSubview(mediaNavigationBar)
#if os(iOS)
        mediaNavigationBar.addPictureInPictureButton()
#endif
        videoPlayerButtons()
        if playerController.isRememberStateEnabled {
            setupVideoControlsState()
        }
        mediaScrubProgressBar.delegate = self

        view.addSubview(switchControlUtility)
        view.addSubview(optionsNavigationBar)
        view.addSubview(videoPlayerControls)
        setupMoreOptionsMenu()
        view.addSubview(mediaScrubProgressBar)
        view.addSubview(videoOutputView)
#if os(iOS)
        view.addSubview(brightnessControlView)
        view.addSubview(volumeControlView)
#endif
        view.addSubview(externalVideoOutputView)
        view.addSubview(coneLoadingView)
        // Keep the external-display panel and loading cone from intercepting transport taps.
        view.addSubview(videoPlayerControls.transportControls)
        view.addSubview(statusLabel)
        view.addSubview(longPressPlaybackSpeedView)

        view.bringSubviewToFront(statusLabel)
        view.sendSubviewToBack(videoOutputView)
        view.insertSubview(backgroundGradientView, aboveSubview: videoOutputView)
#if os(iOS)
        view.insertSubview(sideBackgroundGradientView, aboveSubview: backgroundGradientView)
#endif
        videoOutputView.addSubview(artworkImageView)
    }

    private func setupAccessibility() {

        if playerController.isControlsHidden {
            view.applyAccessibilityControls(
                switchControlUtility
            )

        } else {
            let queueCardView = isQueueCardShown ? queueViewController?.view : nil
            let scrubProgressBarAboveRow = isScrubProgressBarAboveRow ? mediaScrubProgressBar : nil
            let scrubProgressBarInRow = isScrubProgressBarAboveRow ? nil : mediaScrubProgressBar
#if os(iOS)
            view.applyAccessibilityControls(
                mediaNavigationBar,
                queueCardView,
                videoPlayerControls.transportControls,
                scrubProgressBarAboveRow,
                videoPlayerControls.leftControls,
                scrubProgressBarInRow,
                videoPlayerControls.rightControls,
                volumeControlView,
                brightnessControlView
            )
#else
            view.applyAccessibilityControls(
                mediaNavigationBar,
                queueCardView,
                videoPlayerControls.transportControls,
                scrubProgressBarAboveRow,
                videoPlayerControls.leftControls,
                scrubProgressBarInRow,
                videoPlayerControls.rightControls
            )
#endif

        }

        // - custom actions

        let playPause = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("PLAY_PAUSE_BUTTON", comment: ""),
                    image: UIImage(systemName: "playpause"),
                    target: self,
                    selector: #selector(handleAccessibilityPlayPause))

        let close = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("STOP_BUTTON", comment: ""),
                    image: UIImage(systemName: "xmark"),
                    target: self,
                    selector: #selector(handleAccessibilityClose))

        let forward = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("FWD_BUTTON", comment: ""),
                    image: UIImage(systemName: "plus.arrow.trianglehead.clockwise"),
                    target: self,
                    selector: #selector(handleAccessibilityForward))

        let backward = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("BWD_BUTTON", comment: ""),
                    image: UIImage(systemName: "minus.arrow.trianglehead.counterclockwise"),
                    target: self,
                    selector: #selector(handleAccessibilityBackward))

        let next = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("NEXT_HINT", comment: ""),
                    image: UIImage(systemName: "forward.end"),
                    target: self,
                    selector: #selector(handleAccessibilityNext))

        let prev = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("PREVIOUS_HINT", comment: ""),
                    image: UIImage(systemName: "backward.end"),
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
        view.addGestureRecognizer(upSwipeRecognizer)
        view.addGestureRecognizer(downSwipeRecognizer)
        view.addGestureRecognizer(longPressGestureRecognizer)
        view.addGestureRecognizer(snapshotTapRecognizer)

        for recognizer in [tapOnVideoRecognizer, doubleTapGestureRecognizer, longPressGestureRecognizer, panRecognizer] {
            recognizer.delegate = self
        }
    }

    private func setupConstraints() {
        setupVideoAreaLayoutGuide()
        setupInterfaceAreaLayoutGuides()
        setupControlsAreaLayoutGuide()
        setupVideoOutputConstraints()
        setupArtworkConstraints()
        setupSwitchControlUtilityConstraints()
        setupExternalVideoOutputConstraints()
        setupVideoPlayerControlsConstraints()
        setupTransportControlsConstraints()
        setupMediaNavigationBarConstraints()
        setupScrubProgressBarConstraints()
#if os(iOS)
        setupBrightnessControlConstraints()
        setupVolumeControlConstraints()
#endif
        setupStatusLabelConstraints()
        setupConeLoadingViewConstraints()
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

    private func setupCommonSliderConstraints(for slider: UIView) {
        let heightConstraint = slider.heightAnchor.constraint(lessThanOrEqualToConstant: 170)
        let topConstraint = slider.topAnchor.constraint(greaterThanOrEqualTo: mediaNavigationBar.bottomAnchor, constant: 10)
        let bottomConstraint = slider.bottomAnchor.constraint(lessThanOrEqualTo: videoPlayerControls.topAnchor, constant: -16)
        let yConstraint = slider.centerYAnchor.constraint(equalTo: controlsAreaLayoutGuide.centerYAnchor)
        heightConstraint.priority = .required
        topConstraint.priority = .required
        bottomConstraint.priority = .required
        yConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            heightConstraint,
            topConstraint,
            bottomConstraint,
            slider.widthAnchor.constraint(equalToConstant: SliderInfoView.width),
            yConstraint,
        ])
    }

    // MARK: - Private helpers

#if os(iOS)
    private func setupBrightnessControlConstraints() {
        setupCommonSliderConstraints(for: brightnessControlView)
        NSLayoutConstraint.activate([
            brightnessControlView.leadingAnchor.constraint(equalTo: controlsAreaLayoutGuide.leadingAnchor),
            brightnessControlView.topAnchor.constraint(greaterThanOrEqualTo: optionsNavigationBar.bottomAnchor)
        ])
    }

    private func setupVolumeControlConstraints() {
        setupCommonSliderConstraints(for: volumeControlView)
        NSLayoutConstraint.activate([
            volumeControlView.trailingAnchor.constraint(equalTo: controlsAreaLayoutGuide.trailingAnchor),
            volumeControlView.topAnchor.constraint(greaterThanOrEqualTo: optionsNavigationBar.bottomAnchor)
        ])
    }
#endif

    private func setupVideoAreaLayoutGuide() {
        view.addLayoutGuide(videoAreaLayoutGuide)
        NSLayoutConstraint.activate([
            videoAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoAreaLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            videoAreaBottomConstraint,
        ])
    }

    private func setupInterfaceAreaLayoutGuides() {
        view.addLayoutGuide(interfaceAreaLayoutGuide)
        view.addLayoutGuide(safeInterfaceAreaLayoutGuide)
        let safeArea = view.safeAreaLayoutGuide
        let safeLeadingConstraint = safeInterfaceAreaLayoutGuide.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor)
        safeLeadingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            interfaceAreaLeadingConstraint,
            interfaceAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interfaceAreaLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            interfaceAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            safeLeadingConstraint,
            safeInterfaceAreaLayoutGuide.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor),
            safeInterfaceAreaLayoutGuide.leadingAnchor.constraint(greaterThanOrEqualTo: interfaceAreaLayoutGuide.leadingAnchor),
            safeInterfaceAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            safeInterfaceAreaLayoutGuide.topAnchor.constraint(equalTo: safeArea.topAnchor),
            safeInterfaceAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
        ])
    }

    private func setupControlsAreaLayoutGuide() {
        view.addLayoutGuide(controlsAreaLayoutGuide)
        let minimumMargin = Self.controlsMinimumMargin
        let safeArea = view.safeAreaLayoutGuide
        let leadingConstraint = controlsAreaLayoutGuide.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor)
        let trailingConstraint = controlsAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        leadingConstraint.priority = .defaultHigh
        trailingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            controlsAreaLayoutGuide.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor),
            controlsAreaLayoutGuide.leadingAnchor.constraint(greaterThanOrEqualTo: interfaceAreaLayoutGuide.leadingAnchor,
                                                             constant: minimumMargin),
            controlsAreaLayoutGuide.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor),
            controlsAreaLayoutGuide.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                              constant: -minimumMargin),
            controlsAreaTopConstraint,
            controlsAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupVideoOutputConstraints() {
        videoOutputViewLeadingConstraint = videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        videoOutputViewTrailingConstraint = videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([
            videoOutputViewLeadingConstraint,
            videoOutputViewTrailingConstraint,
            videoOutputView.topAnchor.constraint(equalTo: videoAreaLayoutGuide.topAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: videoAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupArtworkConstraints() {
        NSLayoutConstraint.activate([
            artworkImageView.centerXAnchor.constraint(equalTo: videoOutputView.centerXAnchor),
            artworkImageView.centerYAnchor.constraint(equalTo: videoOutputView.centerYAnchor),
            artworkImageView.widthAnchor.constraint(equalTo: videoOutputView.widthAnchor, multiplier: 0.6),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),
        ])
    }

    private func setupSwitchControlUtilityConstraints() {
        NSLayoutConstraint.activate([
            switchControlUtility.heightAnchor.constraint(equalToConstant: 44),
            switchControlUtility.widthAnchor.constraint(equalToConstant: 44),
            switchControlUtility.centerYAnchor.constraint(equalTo: videoAreaLayoutGuide.centerYAnchor),
            switchControlUtility.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupExternalVideoOutputConstraints() {
        NSLayoutConstraint.activate([
            externalVideoOutputView.heightAnchor.constraint(equalToConstant: 320),
            externalVideoOutputView.widthAnchor.constraint(equalToConstant: 320),
            externalVideoOutputView.centerYAnchor.constraint(equalTo: videoAreaLayoutGuide.centerYAnchor),
            externalVideoOutputView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupMediaNavigationBarConstraints() {
        let padding: CGFloat = VideoPlayerViewController.mediaNavigationBarTopPadding
        mediaNavigationBarLayout.activate()
        NSLayoutConstraint.activate([
            optionsNavigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            optionsNavigationBar.topAnchor.constraint(equalTo: mediaNavigationBar.bottomAnchor, constant: padding)
        ])
    }

    private func setupVideoPlayerControlsConstraints() {
        view.addLayoutGuide(queueCardBottomLayoutGuide)
        NSLayoutConstraint.activate([
            videoPlayerControlsHeightConstraint,
            videoPlayerControls.leftAnchor.constraint(equalTo: controlsAreaLayoutGuide.leftAnchor),
        ] + bottomRowRegularConstraints)
    }

    private func setupTransportControlsConstraints() {
        // Keep transport buttons 8pt clear of the sliders.
        let sliderSpace: CGFloat = Self.controlsMinimumMargin + SliderInfoView.width + 8
        let maximumWidth = videoPlayerControls.transportControls.widthAnchor.constraint(
            lessThanOrEqualTo: safeInterfaceAreaLayoutGuide.widthAnchor, constant: -2 * sliderSpace)
        maximumWidth.priority = .required - 1

        NSLayoutConstraint.activate([
            transportControlsCenterXConstraint,
            transportControlsCenterYConstraint,
            transportControlsAboveScrubBarConstraint,
            maximumWidth
        ])
    }

    private func setupScrubProgressBarConstraints() {
        NSLayoutConstraint.activate(scrubProgressBarInRowConstraints)
        updateScrubProgressBarPlacement()
    }

    private func updateScrubProgressBarPlacement() {
        let aboveRow = isCompactPortraitLayout
        guard aboveRow != isScrubProgressBarAboveRow, !isQueueCardShown else {
            return
        }

        isScrubProgressBarAboveRow = aboveRow
        if aboveRow {
            NSLayoutConstraint.deactivate(scrubProgressBarInRowConstraints)
            NSLayoutConstraint.activate(scrubProgressBarAboveRowConstraints)
        } else {
            NSLayoutConstraint.deactivate(scrubProgressBarAboveRowConstraints)
            NSLayoutConstraint.activate(scrubProgressBarInRowConstraints)
        }
        setupAccessibility()
    }

    private func setupStatusLabelConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: interfaceAreaLayoutGuide.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: videoAreaLayoutGuide.centerYAnchor,
                                                constant: -(VideoPlayerControls.playPauseCircleSize / 2 + 16))
        ])
    }

    private func setupConeLoadingViewConstraints() {
        NSLayoutConstraint.activate([
            coneLoadingView.leadingAnchor.constraint(equalTo: interfaceAreaLayoutGuide.leadingAnchor),
            coneLoadingView.trailingAnchor.constraint(equalTo: interfaceAreaLayoutGuide.trailingAnchor),
            coneLoadingView.topAnchor.constraint(equalTo: view.topAnchor),
            coneLoadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLongPressPlaybackSpeedConstraints() {
        NSLayoutConstraint.activate([
            longPressPlaybackSpeedView.centerXAnchor.constraint(equalTo: interfaceAreaLayoutGuide.centerXAnchor),
            longPressPlaybackSpeedView.centerYAnchor.constraint(equalTo: mediaNavigationBar.centerYAnchor)
        ])
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

    // MARK: - Accessibility

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
            let zoom: CGFloat = MediaProjection.FOV.default * -(ZOOM_SENSITIVITY * recognizer.velocity / view.bounds.width)
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

        // Limit y position in order to avoid conflicts with the bottom controls
        guard tapPosition.y <= mediaScrubProgressBar.frame.origin.y else {
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

        super.handleDoubleTapGesture(sender)
    }

    override func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let currentPos = recognizer.location(in: view)

        // Limit the gesture to avoid conflicts with top and bottom player controls
        if !playerController.isControlsHidden
            && (currentPos.y > mediaScrubProgressBar.frame.origin.y
                || currentPos.y < mediaNavigationBar.frame.origin.y) {
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
        dismissOverlayCard()

        if UserDefaults.standard.bool(forKey: kVLCSettingPauseWhenShowingControls) && playbackService.isPlaying {
            playbackService.pause()
        }

        setControlsHidden(!playerController.isControlsHidden, animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if isQueueCardShown && isCompactPortraitLayout != isScrubProgressBarAboveRow {
            queueViewController?.dismissPlayqueue()
        }

        updateScrubProgressBarPlacement()

        if playbackService.isPlaying && playerController.isControlsHidden && overlayCardView == nil {
            setControlsHidden(false, animated: true)
            resetIdleTimer()
        }

        videoPlayerButtons()
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

            var playbackRate: Float = 2.0
            if playbackService.playbackRate >= 2.0 {
                playbackRate = min(playbackService.playbackRate + 1, 8)
            }

            playbackService.playbackRate = playbackRate
            longPressPlaybackSpeedView.speedMultiplier = playbackRate

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

    // MARK: - Snapshot Gesture

    @objc private func handleSnapshotGesture(_ sender: UITapGestureRecognizer) {
        guard UserDefaults.standard.bool(forKey: kVLCSettingSnapshotGesture) else { return }

        playbackService.saveSnapshot { [weak self] success, error in
            guard let self = self else { return }

            if success {
                self.showSnapshotSuccessAlert()
            } else {
                self.showSnapshotFailureAlert(error: error)
            }
        }
    }

    private func showSnapshotSuccessAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("SNAPSHOT_SAVED", comment: ""),
            message: NSLocalizedString("SNAPSHOT_SAVED_TO_CAMERA_ROLL", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func showSnapshotFailureAlert(error: Error?) {
        let alert = UIAlertController(
            title: NSLocalizedString("SNAPSHOT_FAILED", comment: ""),
            message: NSLocalizedString("SNAPSHOT_FAILED_MESSAGE", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .default))
        present(alert, animated: true)
    }

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

        playerController.isControlsHidden = hidden
        if let alert = alertController, hidden {
            alert.dismiss(animated: true, completion: nil)
            alertController = nil
        }
        if hidden {
            videoPlayerControls.moreActionsButton.contextMenuInteraction?.dismissMenu()
        }
        let uiComponentOpacity: CGFloat = hidden ? 0 : 1
        let isQueueCardShown = self.isQueueCardShown
        let scrubProgressBarOpacity: CGFloat = hidden ? 0 : (isQueueCardShown ? PlayerControlGroupView.dimmedAlpha : 1)

        let animations = { [weak self, playerController] in
            self?.mediaNavigationBar.setControlsVisible(!hidden, isQueueShown: isQueueCardShown)
            self?.optionsNavigationBar.alpha = isQueueCardShown ? 0 : uiComponentOpacity
#if os(iOS)
            self?.volumeControlView.setVisible(!hidden && !isQueueCardShown && playerController.isVolumeGestureEnabled)
            self?.brightnessControlView.setVisible(!hidden && !isQueueCardShown && playerController.isBrightnessGestureEnabled)
#endif
            self?.videoPlayerControls.setControlsVisible(!hidden, isQueueShown: isQueueCardShown)
            self?.mediaScrubProgressBar.alpha = scrubProgressBarOpacity
            self?.backgroundGradientView.alpha = uiComponentOpacity
#if os(iOS)
            if hidden {
                self?.sideBackgroundGradientView.alpha = 0
            }
#endif
        }

        let duration = animated ? (hidden ? 0.3 : 0.2) : 0
        UIView.animate(withDuration: duration, delay: 0,
                       options: [.beginFromCurrentState, .curveEaseOut], animations: animations,
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

    override var areGesturesEnabled: Bool {
        return tapOnVideoRecognizer.isEnabled
    }

    override var usesInlineScrubProgressBar: Bool {
        return true
    }

    override var overlayCardLayoutGuide: UILayoutGuide {
        return safeInterfaceAreaLayoutGuide
    }

    override func dismissOverlayCard() {
        delayViewHideTimer?.invalidate()
        delayViewHideTimer = nil
        super.dismissOverlayCard()
    }

    // MARK: - Private helpers

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

        let inset = max(view.safeAreaInsets.left, view.safeAreaInsets.right)
        let constant: CGFloat = playbackService.currentAspectRatio != AspectRatio.fillToScreen.rawValue ? inset : 0.0
#if os(iOS)
        if view.bounds.width > view.bounds.height {
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
            adaptVideoOutputToNotch()
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
        if !playerController.isControlsHidden && !isGestureActive {
            setControlsHidden(!playerController.isControlsHidden, animated: true)
        }
        // FIXME:- other states to reset
    }

    private func resetIdleTimer() {
        guard !isQueueCardShown else {
            return
        }

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
        mediaNavigationBar.favoriteButton.isEnabled = enabled
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
        minimizeGestureRecognizer.isEnabled = enabled

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
        updateFavoriteButton()
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.mediaPlayerState == .playing)
        mediaScrubProgressBar.updateLiveStreamState()

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

        let media = playbackService.currentlyPlayingLibraryMedia
        if let media = media, currentState == .opening &&
            (media.type() == .audio && playbackService.numberOfVideoTracks == 0),
           presentingViewController != nil {
            // This media is audio only and can be played with the Audio Player.
            delegate?.videoPlayerViewControllerShouldSwitchPlayer(self)
            return
        }

        if media == nil || media?.isExternalMedia() == true,
           currentState == .playing,
           playbackService.numberOfVideoTracks == 0,
           !playbackService.playAsAudio,
           presentingViewController != nil {
            // This stream turned out to be audio only and can be played with the Audio Player.
            delegate?.videoPlayerViewControllerShouldSwitchPlayer(self)
            return
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
        updateFavoriteButton()
        mediaScrubProgressBar.updateLiveStreamState()

        if playbackService.isPlayingOnExternalScreen() {
#if os(iOS)
            if let renderer = playbackService.renderer {
                externalVideoOutputView.updateUI(rendererName: renderer.name, title: metadata.title)
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
                artworkImageView.setImage(metadata.artworkImage, placeholderName: metadata.placeholderName)
            }

            // Only show the artwork when not casting to a device.
#if os(iOS)
            artworkImageView.isHidden = playbackService.renderer != nil ? true : false
#else
            artworkImageView.isHidden = false
#endif
            artworkImageView.clipsToBounds = true
            artworkImageView.contentMode = .scaleAspectFit
            playbackService.videoOutputView = nil
        } else {
            playbackService.videoOutputView = videoOutputView
            artworkImageView.isHidden = true
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
}

// MARK: - MediaNavigationBarDelegate

extension VideoPlayerViewController {
    override func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar) {
        super.mediaNavigationBarDidTapClose(mediaNavigationBar)
        playbackService.playAsAudio = false
    }

    func mediaNavigationBarDidToggleQueueView(_ mediaNavigationBar: MediaNavigationBar) {
        guard let qvc = queueViewController else {
            return
        }

        guard !isQueueCardShown else {
            qvc.dismissPlayqueue()
            return
        }

        qvc.removeFromParent()
        qvc.view.removeFromSuperview()
        qvc.delegate = self
        shouldDisableGestures(true)
        idleTimer?.invalidate()
        idleTimer = nil

        isQueueCardShown = true
        addChild(qvc)
        qvc.didMove(toParent: self)
        view.layoutIfNeeded()

        if isCompactPortraitLayout {
            transportControlsCenterYConstraint.isActive = false
            queueCardConstraints = [
                videoPlayerControls.transportControls.bottomAnchor.constraint(
                    equalTo: videoPlayerControls.topAnchor, constant: transportControlsAboveScrubBarConstraint.constant),
            ]
        } else if view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
            let cardRightAnchor = qvc.view.rightAnchor
            let transportClearOfCard = videoPlayerControls.transportControls.leftAnchor.constraint(
                greaterThanOrEqualTo: cardRightAnchor, constant: Self.queueCardSpacing)
            transportClearOfCard.priority = .required - 1
            view.addLayoutGuide(queueCardTransportAreaGuide)
            queueCardConstraints = [
                queueCardTransportAreaGuide.leftAnchor.constraint(equalTo: cardRightAnchor),
                queueCardTransportAreaGuide.rightAnchor.constraint(equalTo: videoPlayerControls.rightAnchor),
                videoPlayerControls.transportControls.centerXAnchor.constraint(equalTo: queueCardTransportAreaGuide.centerXAnchor),
                transportClearOfCard,
                mediaScrubProgressBar.leftAnchor.constraint(equalTo: cardRightAnchor, constant: Self.queueCardSpacing),
            ]
            NSLayoutConstraint.deactivate([transportControlsCenterXConstraint, scrubProgressBarLeftInRowConstraint])
        } else {
            let cardLeftAnchor = qvc.view.leftAnchor
            let transportClearOfCard = videoPlayerControls.transportControls.rightAnchor.constraint(
                lessThanOrEqualTo: cardLeftAnchor, constant: -Self.queueCardSpacing)
            transportClearOfCard.priority = .required - 1
            view.addLayoutGuide(queueCardTransportAreaGuide)
            queueCardConstraints = [
                queueCardTransportAreaGuide.leftAnchor.constraint(equalTo: videoPlayerControls.leftAnchor),
                queueCardTransportAreaGuide.rightAnchor.constraint(equalTo: cardLeftAnchor),
                videoPlayerControls.transportControls.centerXAnchor.constraint(equalTo: queueCardTransportAreaGuide.centerXAnchor),
                transportClearOfCard,
                mediaScrubProgressBar.rightAnchor.constraint(equalTo: cardLeftAnchor, constant: -Self.queueCardSpacing),
            ]
            NSLayoutConstraint.deactivate([transportControlsCenterXConstraint, scrubProgressBarRightInRowConstraint])
        }
        NSLayoutConstraint.activate(queueCardConstraints)
        view.bringSubviewToFront(videoPlayerControls.transportControls)

        qvc.show()
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        setControlsHidden(false, animated: true)
        setupAccessibility()
        UIAccessibility.post(notification: .screenChanged, argument: qvc.queueCollectionView)
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

extension VideoPlayerViewController: MediaScrubProgressBarDelegate {
    func mediaScrubProgressBarShouldResetIdleTimer() {
        resetIdleTimer()
    }
}

// MARK: - MenuButtonDelegate

extension VideoPlayerViewController: MenuButtonDelegate {
    func menuButtonWillShowMenu(_ menuButton: MenuButton) {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    func menuButtonDidHideMenu(_ menuButton: MenuButton) {
        resetIdleTimer()
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension VideoPlayerViewController {
    override func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        super.mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: state)

#if os(iOS)
        let mask = getInterfaceOrientationMask(orientation: currentInterfaceOrientation)

        supportedInterfaceOrientations = supportedInterfaceOrientations == .allButUpsideDown ? mask : .allButUpsideDown
#endif

        setPlayerInterfaceEnabled(!state)
    }

    func mediaMoreOptionsActionSheetDidAppeared() {
        guard overlayCardView == nil else {
            return
        }
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
                bookmarksView.centerXAnchor.constraint(equalTo: safeInterfaceAreaLayoutGuide.centerXAnchor),
                bookmarksView.leadingAnchor.constraint(equalTo: safeInterfaceAreaLayoutGuide.leadingAnchor),
                bookmarksView.trailingAnchor.constraint(equalTo: safeInterfaceAreaLayoutGuide.trailingAnchor),
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
            abRepeatView.centerXAnchor.constraint(equalTo: safeInterfaceAreaLayoutGuide.centerXAnchor),
            abRepeatView.bottomAnchor.constraint(equalTo: mediaScrubProgressBar.topAnchor, constant: -20.0),
        ])
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

// MARK: - QueueViewControllerDelegate

extension VideoPlayerViewController: QueueViewControllerDelegate {
    func queueViewControllerDidDisappear(_ queueViewController: QueueViewController?) {
        guard isQueueCardShown else {
            return
        }

        isQueueCardShown = false
        NSLayoutConstraint.deactivate(queueCardConstraints)
        queueCardConstraints = []
        queueCardTransportAreaGuide.owningView?.removeLayoutGuide(queueCardTransportAreaGuide)
        NSLayoutConstraint.activate([transportControlsCenterXConstraint, transportControlsCenterYConstraint])
        scrubProgressBarLeftInRowConstraint.isActive = !isScrubProgressBarAboveRow
        scrubProgressBarRightInRowConstraint.isActive = !isScrubProgressBarAboveRow
        updateScrubProgressBarPlacement()
        queueViewController?.hide()
        shouldDisableGestures(false)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        setControlsHidden(false, animated: true)
        resetIdleTimer()
        setupAccessibility()
        UIAccessibility.post(notification: .screenChanged, argument: mediaNavigationBar.queueButton)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension VideoPlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let queueView = queueViewController?.view, touch.view?.isDescendant(of: queueView) == true {
            return false
        }
        guard let control = touch.view as? UIControl else { return true }
#if os(iOS)
        // Keep player swipes from competing with slider drags.
        if control.isDescendant(of: brightnessControlView) || control.isDescendant(of: volumeControlView) {
            return gestureRecognizer == tapOnVideoRecognizer
        }
#endif
        // Prevent video taps and long presses on transport buttons.
        return gestureRecognizer == panRecognizer || !control.isDescendant(of: videoPlayerControls.transportControls)
    }
}

// MARK: - TrackSelectorViewDelegate

extension VideoPlayerViewController: TrackSelectorViewDelegate {
    func showTrackSelectorCard() {
        guard !(overlayCardView is TrackSelectorView) else {
            return
        }

        let trackSelectorCard = TrackSelectorView()
        trackSelectorCard.delegate = self
        showOverlayCard(trackSelectorCard)
        trackSelectorCard.focusForAccessibility()
    }

    func trackSelectorView(_ trackSelectorView: TrackSelectorView, didRequestLoadExternalFileForAudio audio: Bool) {
        dismissOverlayCard()
        externalTrackRequestIsAudio = audio
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    func trackSelectorViewDidRequestDownloadSubtitles(_ trackSelectorView: TrackSelectorView) {
        dismissOverlayCard()
        downloadMoreSPU()
    }

    func trackSelectorView(_ trackSelectorView: TrackSelectorView, didRequestDelayForAudio audio: Bool) {
        showDelayView(for: audio ? .audio : .subtitle)
    }

    func trackSelectorViewDidRequestDismissal(_ trackSelectorView: TrackSelectorView) {
        dismissOverlayCard()
    }
}

// MARK: - Delay

extension VideoPlayerViewController {
    func showDelayView(for kind: PlaybackDelayView.Kind) {
        if let delayView = delayView, delayView.kind == kind {
            delayView.refresh()
            return
        }

        let delayView = PlaybackDelayView(kind: kind)
        delayView.delegate = self
        showOverlayCard(delayView)
        delayView.focusForAccessibility()
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands = super.keyCommands ?? []

        let decreaseAudioDelay = UIKeyCommand(input: "j", modifierFlags: [], action: #selector(keyDecreaseAudioDelay))
        decreaseAudioDelay.discoverabilityTitle = NSLocalizedString("KEY_DECREASE_AUDIO_DELAY", comment: "")
        let increaseAudioDelay = UIKeyCommand(input: "k", modifierFlags: [], action: #selector(keyIncreaseAudioDelay))
        increaseAudioDelay.discoverabilityTitle = NSLocalizedString("KEY_INCREASE_AUDIO_DELAY", comment: "")
        commands += [decreaseAudioDelay, increaseAudioDelay]

        if !playbackService.metadata.isAudioOnly {
            let decreaseSubtitleDelay = UIKeyCommand(input: "g", modifierFlags: [], action: #selector(keyDecreaseSubtitleDelay))
            decreaseSubtitleDelay.discoverabilityTitle = NSLocalizedString("KEY_DECREASE_SUBTITLE_DELAY", comment: "")
            let increaseSubtitleDelay = UIKeyCommand(input: "h", modifierFlags: [], action: #selector(keyIncreaseSubtitleDelay))
            increaseSubtitleDelay.discoverabilityTitle = NSLocalizedString("KEY_INCREASE_SUBTITLE_DELAY", comment: "")
            commands += [decreaseSubtitleDelay, increaseSubtitleDelay]
        }

        return commands
    }

    @objc func keyDecreaseAudioDelay() {
        nudgeDelayFromKeyboard(kind: .audio, increasing: false)
    }

    @objc func keyIncreaseAudioDelay() {
        nudgeDelayFromKeyboard(kind: .audio, increasing: true)
    }

    @objc func keyDecreaseSubtitleDelay() {
        nudgeDelayFromKeyboard(kind: .subtitle, increasing: false)
    }

    @objc func keyIncreaseSubtitleDelay() {
        nudgeDelayFromKeyboard(kind: .subtitle, increasing: true)
    }

    private func nudgeDelayFromKeyboard(kind: PlaybackDelayView.Kind, increasing: Bool) {
        showDelayView(for: kind)
        delayView?.nudgeDelay(increasing: increasing)
        scheduleDelayViewHideTimer()
    }

    private func scheduleDelayViewHideTimer() {
        delayViewHideTimer?.invalidate()
        delayViewHideTimer = Timer.scheduledTimer(timeInterval: 4,
                                                  target: self,
                                                  selector: #selector(delayViewHideTimerFired),
                                                  userInfo: nil,
                                                  repeats: false)
    }

    @objc private func delayViewHideTimerFired() {
        dismissOverlayCard()
    }
}

// MARK: - PlaybackDelayViewDelegate

extension VideoPlayerViewController: PlaybackDelayViewDelegate {
    func playbackDelayViewDidChangeDelay(_ delayView: PlaybackDelayView) {
        updatePlaybackSpeedIcon()
        if delayViewHideTimer != nil {
            scheduleDelayViewHideTimer()
        }
    }

    func playbackDelayViewDidRequestDismissal(_ delayView: PlaybackDelayView) {
        dismissOverlayCard()
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

            let loadAsAudio = externalTrackRequestIsAudio ?? !fileURL.path.isSupportedSubtitleFormat()
            externalTrackRequestIsAudio = nil
            if loadAsAudio {
                playbackService.addAudioToCurrentPlayback(from: URL(fileURLWithPath: destinationPath))
            } else {
                playbackService.addSubtitlesToCurrentPlayback(from: URL(fileURLWithPath: destinationPath))
            }
        } else {
            return
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        externalTrackRequestIsAudio = nil
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

// MARK: GameControllerManagerDelegate

extension VideoPlayerViewController: GameControllerManagerDelegate {
    
    func gameControllerManagerDelegateDidTapClosePlayer(_ gameControllerManager: GameControllerManager) {
        playbackService.stopPlayback()
    }
    
    func gameControllerManagerDelegateDidTapPlayPause(_ gameControllerManager: GameControllerManager) {
        playbackService.playPause()
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.isPlaying)
    }
    
    
    func gameControllerManagerDelegateDidTapForward(_ gameControllerManager: GameControllerManager) {
        handleSeek(seekForwardBy, .forward)
    }
    
    func gameControllerManagerDelegateDidTapBackward(_ gameControllerManager: GameControllerManager) {
        handleSeek(seekBackwardBy, .backward)
    }
    
    func gameControllerManagerDelegateDidTapVolume(_ gameControllerManager: GameControllerManager, _ value: Float) {
#if os(iOS)
        var animations : (() -> Void)?
        volumeBackgroundGradientLayer.isHidden = false
        volumeControl.fetchDeviceValue()
        animations = { [volumeControlView, sideBackgroundGradientView] in
            volumeControlView.setVisible(true)
            sideBackgroundGradientView.alpha = 1
        }
        
        if let animations = animations {
            UIView.animate(withDuration: 0.2, delay: 0,
                           options: .beginFromCurrentState, animations: animations,
                           completion: nil)
        }
        
        volumeControl.value = min(max(volumeControl.value + value, 0), 1)
        volumeControl.applyValueToDevice()
        volumeControlView.updateIcon(level: volumeControl.value)
        
        animations = { [volumeControlView, sideBackgroundGradientView] in
            volumeControlView.setVisible(false)
            sideBackgroundGradientView.alpha = 0
        }
        
        if let animations = animations {
            UIView.animate(withDuration: 0.2, delay: 0.5,
                           options: .beginFromCurrentState, animations: animations, completion: {
                [brightnessBackgroundGradientLayer,
                 volumeBackgroundGradientLayer] _ in
                brightnessBackgroundGradientLayer.isHidden = true
                volumeBackgroundGradientLayer.isHidden = true
                self.setControlsHidden(true, animated: true)
            })
        }
#else
        self.setControlsHidden(true, animated: true)
#endif
    }
    
    func gameControllerManagerDelegateDidTapForwardLong(_ gameControllerManager: GameControllerManager) {
        handleSeek(seekForwardBy, .forward, multiplier: 3)
    }
    
    func gameControllerManagerDelegateDidTapBackwardLong(_ gameControllerManager: GameControllerManager) {
        handleSeek(seekBackwardBy, .backward, multiplier: 3)
    }
    
    func gameControllerManagerDelegateDidTapPreviousMedia(_ gameControllerManager: GameControllerManager) {
        playbackService.previous()
    }
    
    func gameControllerManagerDelegateDidTapNextMedia(_ gameControllerManager: GameControllerManager) {
        playbackService.next()
    }
    
    
    func gameControllerManagerDelegateDidScrubForward(_ gameControllerManager: GameControllerManager) {
        handleSeek(scrubForwardBy, .forward)
    }
    
    func gameControllerManagerDelegateDidScrubBackward(_ gameControllerManager: GameControllerManager) {
        handleSeek(scrubBackwardBy, .backward)
    }
    
    private func handleSeek(_ seekValue: Int, _ direction: PlayerSeekState, multiplier: Int = 1) {
        let seek = seekValue * multiplier
        let signedSeek = direction == .forward ? seek : -seek
        
        totalSeekDuration = previousSeekState != direction ? signedSeek : totalSeekDuration + signedSeek
        previousSeekState = direction
        
        displayAndApplySeekDuration(seek)
    }
    
    func gameControllerManagerDelegateDidTogglePlayerQueue(_ gameControllerManager: GameControllerManager) {
        if queueViewController?.parent != nil {
            queueViewController?.dismissPlayqueue()
        } else {
            mediaNavigationBarDidToggleQueueView(mediaNavigationBar)
        }
    }
    
    func gameControllerManagerDelegateDidTogglePlayerOptions(_ gameControllerManager: GameControllerManager) {
        if self.presentedViewController == nil {
            present(moreOptionsActionSheet, animated: false) {
                [unowned self] in
                self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
                self.moreOptionsActionSheet.hidePlayer()
            }
        } else {
            self.moreOptionsActionSheet.dismiss(animated: true, completion: nil)
        }
    }
}
