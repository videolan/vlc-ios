/*****************************************************************************
 * PlayerViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import AVFoundation
import MediaPlayer

enum PlayerSeekState {
    case `default`
    case forward
    case backward
}

enum PlayerPanType {
    case none
#if os(iOS)
    case brightness
    case volume
#endif
    case projection
}

enum PlayerSeekGestureType {
    case tap
    case swipe
}

class PlayerViewController: UIViewController {
    // MARK: - Slider Gesture Contol

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

    // MARK: - Properties
    var mediaLibraryService: MediaLibraryService
#if os(iOS)
    var rendererDiscovererManager: VLCRendererDiscovererManager
#endif
    var playerController: PlayerController
    var playbackService: PlaybackService = PlaybackService.sharedInstance()
    var queueViewController: QueueViewController?
    var alertController: UIAlertController?

    // MARK: Seek
    var seekForwardBy: Int = 0
    var seekBackwardBy: Int = 0
    var numberOfGestureSeek: Int = 0
    var totalSeekDuration: Int = 0
    var seekForwardBySwipe: Int = 0
    var seekBackwardBySwipe: Int = 0
    var forwardBackwardEqual: Bool = true
    var tapSwipeEqual: Bool = true
    var numberOfTapSeek: Int = 0
    var previousSeekState: PlayerSeekState = .default

    // MARK: UI Elements
    lazy var statusLabel: VLCStatusLabel = {
        var statusLabel = VLCStatusLabel()
        statusLabel.isHidden = true
        statusLabel.textColor = .white
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }()

    lazy var mediaNavigationBar: MediaNavigationBar = {
#if os(iOS)
        var mediaNavigationBar = MediaNavigationBar(frame: .zero,
                                                    rendererDiscovererService: rendererDiscovererManager)
        mediaNavigationBar.chromeCastButton.isHidden = self.playbackService.renderer == nil
#else
        var mediaNavigationBar = MediaNavigationBar(frame: .zero)
#endif
        mediaNavigationBar.delegate = self
        mediaNavigationBar.presentingViewController = self
        return mediaNavigationBar
    }()

    lazy var mediaScrubProgressBar: MediaScrubProgressBar = {
        var mediaScrubProgressBar: MediaScrubProgressBar = MediaScrubProgressBar()
        mediaScrubProgressBar.delegate = self
        return mediaScrubProgressBar
    }()

    var abRepeatView: ABRepeatView?

    lazy var aMark: ABRepeatMarkView = {
        let aMark = ABRepeatMarkView(icon: UIImage(named: "abRepeatMarkerFill"))
        aMark.translatesAutoresizingMaskIntoConstraints = false
        return aMark
    }()

    lazy var bMark: ABRepeatMarkView = {
        let bMark = ABRepeatMarkView(icon: UIImage(named: "abRepeatMarkerFill"))
        bMark.translatesAutoresizingMaskIntoConstraints = false
        return bMark
    }()

    lazy var moreOptionsActionSheet: MediaMoreOptionsActionSheet = {
        var moreOptionsActionSheet = MediaMoreOptionsActionSheet()
        moreOptionsActionSheet.moreOptionsDelegate = self
        return moreOptionsActionSheet
    }()

    lazy var optionsNavigationBar: OptionsNavigationBar = {
        var optionsNavigationBar = OptionsNavigationBar()
        optionsNavigationBar.delegate = self
        return optionsNavigationBar
    }()

    lazy var equalizerPopupView: PopupView = {
        let equalizerPopupView = PopupView()
        equalizerPopupView.delegate = self
        return equalizerPopupView
    }()

    lazy var externalOutputView: PlayerInfoView = {
        let externalOutputView = PlayerInfoView()
        externalOutputView.isHidden = true
        externalOutputView.translatesAutoresizingMaskIntoConstraints = false
        return externalOutputView
    }()

    private lazy var contentOutputView: UIView = {
        var contentOutputView = UIView()
        contentOutputView.backgroundColor = .clear
        contentOutputView.isUserInteractionEnabled = false
        contentOutputView.translatesAutoresizingMaskIntoConstraints = false
        contentOutputView.accessibilityIgnoresInvertColors = true

        contentOutputView.accessibilityIdentifier = "Video Player Title"
        contentOutputView.accessibilityLabel = NSLocalizedString("VO_VIDEOPLAYER_TITLE",
                                                                 comment: "")
        contentOutputView.accessibilityHint = NSLocalizedString("VO_VIDEOPLAYER_DOUBLETAP",
                                                                comment: "")
        return contentOutputView
    }()

#if os(iOS)
    lazy var brightnessControl: SliderGestureControl = {
        return SliderGestureControl { value in
            UIScreen.main.brightness = CGFloat(value)
        } deviceGetter: {
            return Float(UIScreen.main.brightness)
        }
    }()

    lazy var volumeControl: SliderGestureControl = {
        return SliderGestureControl { [weak self] value in
            self?.volumeView.setVolume(value)
        } deviceGetter: {
            return AVAudioSession.sharedInstance().outputVolume
        }
    }()

    lazy var volumeBackgroundGradientLayer: CAGradientLayer = {
        let volumeBackGroundGradientLayer = CAGradientLayer()

        volumeBackGroundGradientLayer.frame = self.view.bounds
        volumeBackGroundGradientLayer.colors = [UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.black.cgColor]
        volumeBackGroundGradientLayer.locations = [0, 0.2, 0.8, 1]
        volumeBackGroundGradientLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        volumeBackGroundGradientLayer.isHidden = true
        return volumeBackGroundGradientLayer
    }()

    lazy var brightnessBackgroundGradientLayer: CAGradientLayer = {
        let brightnessGroundGradientLayer = CAGradientLayer()

        brightnessGroundGradientLayer.frame = self.view.bounds
        brightnessGroundGradientLayer.colors = [UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.clear.cgColor,
                                                UIColor.black.cgColor]
        brightnessGroundGradientLayer.locations = [0, 0.2, 0.8, 1]
        brightnessGroundGradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        brightnessGroundGradientLayer.isHidden = true
        return brightnessGroundGradientLayer
    }()

    lazy var sideBackgroundGradientView: UIView = {
        let backgroundGradientView = UIView()
        backgroundGradientView.frame = self.view.bounds
        backgroundGradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        backgroundGradientView.layer.addSublayer(brightnessBackgroundGradientLayer)
        backgroundGradientView.layer.addSublayer(volumeBackgroundGradientLayer)
        return backgroundGradientView
    }()

    lazy var brightnessControlView: BrightnessControlView = {
        let vc = BrightnessControlView()
        vc.updateIcon(level: brightnessControl.fetchAndGetDeviceValue())
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.alpha = 0
        return vc
    }()

    lazy var volumeControlView: VolumeControlView = {
        let vc = VolumeControlView(volumeView: self.volumeView)
        vc.updateIcon(level: volumeControl.fetchAndGetDeviceValue())
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.alpha = 0
        return vc
    }()
#endif

#if os(iOS)
    lazy var rendererButton: UIButton = {
        let rendererButton = rendererDiscovererManager.setupRendererButton()
        rendererButton.tintColor = .white

        if playbackService.renderer != nil {
            rendererButton.isSelected = true
        }

        rendererDiscovererManager.addSelectionHandler {
            rendererItem in
            if rendererItem != nil {
                self.changeOutputView(to: self.externalOutputView.displayView)
                let color: UIColor = PresentationTheme.current.colors.orangeUI
                self.mediaNavigationBar.updateDeviceButton(with: UIImage(named: "rendererFull"), color: color)
            } else if let currentRenderer = self.playbackService.renderer {
                self.removedCurrentRendererItem(currentRenderer)
            } else {
                // There is no renderer item
                self.mediaNavigationBar.updateDeviceButton(with: UIImage(named: "renderer"), color: .white)
            }
        }

        return rendererButton
    }()
#endif

#if os(iOS)
    let volumeView = MPVolumeView(frame: .zero)
#endif

    var addBookmarksView: AddBookmarksView? = nil

    var mediaDuration: Int = 0

    private var isGestureActive: Bool = false

    private var currentPanType: PlayerPanType = .none

    private var projectionLocation: CGPoint = .zero

    private var fov: CGFloat = 0

    private var minimizationInitialCenter: CGPoint?

    private lazy var deviceMotion: DeviceMotion = {
        let deviceMotion = DeviceMotion()
        deviceMotion.delegate = self
        return deviceMotion
    }()

    var systemBrightness: Double?

    // MARK: Constants
    private let ZOOM_SENSITIVITY: CGFloat = 5

#if os(iOS)
    private let screenPixelSize = CGSize(width: UIScreen.main.bounds.width,
                                         height: UIScreen.main.bounds.height)
#else
    private let screenPixelSize: CGSize = {
        return UIApplication.shared.delegate?.window??.bounds.size
    }()!
#endif

    private let notificationCenter = NotificationCenter.default

    private let userDefaults = UserDefaults.standard

    // MARK: - Gestures

    lazy var panRecognizer: UIPanGestureRecognizer = {
        let panRecognizer = UIPanGestureRecognizer(target: self,
                                                   action: #selector(handlePanGesture(recognizer:)))
        panRecognizer.maximumNumberOfTouches = 1
        return panRecognizer
    }()

    lazy var playPauseRecognizer: UITapGestureRecognizer = {
        let playPauseRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(handlePlayPauseGesture))
        playPauseRecognizer.numberOfTouchesRequired = 2
        return playPauseRecognizer
    }()

    lazy var pinchRecognizer: UIPinchGestureRecognizer = {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self,
                                                       action: #selector(handlePinchGesture(recognizer:)))
        return pinchRecognizer
    }()

    lazy var leftSwipeRecognizer: UISwipeGestureRecognizer = {
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self,
                                                           action: #selector(handleSwipeGestures(recognizer:)))
        leftSwipeRecognizer.direction = .left
        return leftSwipeRecognizer
    }()

    lazy var rightSwipeRecognizer: UISwipeGestureRecognizer = {
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self,
                                                            action: #selector(handleSwipeGestures(recognizer:)))
        rightSwipeRecognizer.direction = .right
        return rightSwipeRecognizer
    }()

    lazy var minimizeGestureRecognizer: UIPanGestureRecognizer = {
        let minimizeGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                               action: #selector(handleMinimizeGesture(_:)))
        return minimizeGestureRecognizer
    }()

    lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                action: #selector(handleDoubleTapGesture(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        return doubleTapGestureRecognizer
    }()

    // MARK: - Init

#if os(iOS)
    @objc init(mediaLibraryService: MediaLibraryService, rendererDiscovererManager: VLCRendererDiscovererManager, playerController: PlayerController) {
        self.mediaLibraryService = mediaLibraryService
        self.rendererDiscovererManager = rendererDiscovererManager
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
        mediaNavigationBar.chromeCastButton = rendererButton
        mediaNavigationBar.addGestureRecognizer(minimizeGestureRecognizer)
        systemBrightness = UIScreen.main.brightness
    }
#else
    @objc init(mediaLibraryService: MediaLibraryService, playerController: PlayerController) {
        self.mediaLibraryService = mediaLibraryService
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
        mediaNavigationBar.addGestureRecognizer(minimizeGestureRecognizer)
    }
#endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setupObservers()
        hideSystemVolumeInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
#if os(iOS)
        setupRendererDiscovererManager()
#endif

        var color: UIColor = .white
        var image: UIImage? = UIImage(named: "renderer")

        if playbackService.isPlayingOnExternalScreen() {
            color = PresentationTheme.current.colors.orangeUI
            image = UIImage(named: "rendererFull")
        }

        setupSeekDurations()

        mediaNavigationBar.updateDeviceButton(with: image, color: color)

        if playerController.isRememberStateEnabled {
            playbackService.isShuffleMode = playerController.isShuffleEnabled
            playbackService.repeatMode = playerController.isRepeatEnabled
        }

        view.transform = .identity

#if os(iOS)
        //update the system brightness value before player appears
        self.systemBrightness = UIScreen.main.brightness

        //update the value of brightness control view
        //In case of remember brightness option is disabled, this will update the brightness bar with current brightness.
        if !playerController.isRememberBrightnessEnabled && self is VideoPlayerViewController {
            brightnessControlView.updateIcon(level: brightnessControl.fetchAndGetDeviceValue())
        }
#endif
    }

#if os(iOS)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if playerController.isRememberBrightnessEnabled && self is VideoPlayerViewController {
            if let brightness = userDefaults.value(forKey: KVLCPlayerBrightness) as? CGFloat {
                animateBrightness(to: brightness)
                self.brightnessControl.value = Float(brightness)
            }
        }

        addPlayerBrightnessObservers()
    }
#endif

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Adjust the position of the AB Repeat marks if needed based on the device's orientation.
        mediaScrubProgressBar.adjustABRepeatMarks(aMark: aMark, bMark: bMark)
    }

#if os(iOS)
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if playerController.isRememberBrightnessEnabled && self is VideoPlayerViewController {
            let currentBrightness = UIScreen.main.brightness
            self.brightnessControl.value = Float(currentBrightness) // helper in indicating change in the system brightness
            userDefaults.set(currentBrightness, forKey: KVLCPlayerBrightness)
        }
        //set the value of system brightness after closing the app
        //even if the Player Should Remember Brightness option is disabled
        animateBrightness(to: systemBrightness!, duration: 0.35)

        // remove the observer when the view disappears to avoid breaking the brightness view value
        // when the player is not shown to save the persisted values
        removePlayerBrightnessObservers()
    }
#endif

    // MARK: - Public methods

    func showPopup(_ popupView: PopupView, with contentView: UIView, accessoryViewsDelegate: PopupViewAccessoryViewsDelegate? = nil) {
        shouldDisableGestures(true)

        popupView.isShown = true

        popupView.addContentView(contentView, constraintWidth: true)
        if let accessoryViewsDelegate = accessoryViewsDelegate {
            popupView.accessoryViewsDelegate = accessoryViewsDelegate
        }

        view.addSubview(popupView)
    }

    func setControlsHidden(_ hidden: Bool, animated: Bool) {
        // HIDE THE CONTROLS IF NEEDED
    }

    func setupGestures() {
        // SETUP THE GESTURES

        shouldDisableGestures(false)
    }

    func shouldDisableGestures(_ disable: Bool) {
        panRecognizer.isEnabled = !disable
        playPauseRecognizer.isEnabled = !disable
        pinchRecognizer.isEnabled = !disable
        leftSwipeRecognizer.isEnabled = !disable
        rightSwipeRecognizer.isEnabled = !disable
        doubleTapGestureRecognizer.isEnabled = !disable
    }

#if os(iOS)
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // We're observing outputVolume to handle volume changes from physical volume buttons
        // To processd properly we have to check we're not interacting with UI controls or gesture
        if  keyPath == "outputVolume" &&
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
#endif

    func changeOutputView(to output: UIView?) {
        // Change the content output view if necessary according to the type of the player.
    }

    func minimizePlayer() {
        // Minimize the player
    }

    func updateShuffleState() {
        playbackService.isShuffleMode = !playbackService.isShuffleMode
    }

    func updateRepeatMode() {
        playbackService.toggleRepeatMode()
    }

    func displayAndApplySeekDuration(_ currentSeek: Int) {
        var hudString: String
        if totalSeekDuration > 0 {
            hudString = "⇒ "
            jumpForwards(currentSeek)
        } else {
            hudString = "⇐ "
            jumpBackwards(currentSeek)
        }

        // Convert the time in seconds into milliseconds in order to the get the right VLCTime value.
        let duration: VLCTime = VLCTime(number: NSNumber(value: abs(totalSeekDuration) * 1000))
        hudString.append(duration.stringValue)
        statusLabel.showStatusMessage(hudString)
    }

    func togglePlayPause() {
        if playbackService.isPlaying {
            playbackService.pause()
            setControlsHidden(false, animated: playerController.isControlsHidden)
        } else {
            playbackService.play()
        }
    }

    // MARK: - Private methods

    private func jumpBackwards(_ interval: Int = 10) {
        playbackService.jumpBackward(Int32(interval))
    }

    private func jumpForwards(_ interval: Int = 10) {
        playbackService.jumpForward(Int32(interval))
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

    private func showIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = false
        }, completion: nil)
    }

    private func openOptionView(view: ActionSheetCellIdentifier) {
        present(moreOptionsActionSheet, animated: true, completion: {
            self.moreOptionsActionSheet.addView(view)
        })
    }

    private func hideIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = true
        }, completion: nil)
    }

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
            break
        case optionsNavigationBar.abRepeatMarksButton:
            resetABRepeatMarks(true)
            break
        default:
            assertionFailure("VideoPlayerViewController: Unvalid button.")
        }
    }

    private func detectPanType(_ recognizer: UIPanGestureRecognizer) -> PlayerPanType {
        let window: UIWindow = (UIApplication.shared.delegate?.window!)!
        let windowWidth: CGFloat = window.bounds.width
        let location: CGPoint = recognizer.location(in: window)

        // If minimization handler not ended yet, don't detect other gestures to don't block it.
        guard minimizationInitialCenter == nil else { return .none }

        var panType: PlayerPanType = .none
        if location.x < 2 * windowWidth / 3 {
            panType = .none
        }
#if os(iOS)
        if location.x < 1 * windowWidth / 3 && playerController.isBrightnessGestureEnabled {
            panType = .brightness
        }
        if location.x < 3 * windowWidth / 3 && playerController.isVolumeGestureEnabled {
            panType = .volume
        }
#endif

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

#if os(iOS)
    private func setupRendererDiscovererManager() {
        rendererDiscovererManager.presentingViewController = self
        rendererDiscovererManager.delegate = self
    }
#endif

    private func hideSystemVolumeInfo() {
#if os(iOS)
        volumeView.alpha = 0.00001
        view.addSubview(volumeView)
#endif
    }

    private func setupObservers() {
        try? AVAudioSession.sharedInstance().setActive(true)
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)

        notificationCenter.addObserver(self, selector: #selector(updatePlayerControls), name: .VLCDidAppendMediaToQueue, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updatePlayerControls), name: .VLCDidRemoveMediaFromQueue, object: nil)
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

    // MARK: - Observers

#if os(iOS)
    private func addPlayerBrightnessObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(systemBrightnessChanged),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(playerWillResignActive),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(playerWillEnterForeground),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
    }

    private func removePlayerBrightnessObservers() {
        notificationCenter.removeObserver(self,
                                          name: UIApplication.didBecomeActiveNotification,
                                          object: nil)

        notificationCenter.removeObserver(self,
                                          name: UIApplication.willResignActiveNotification,
                                          object: nil)

        notificationCenter.removeObserver(self,
                                          name: UIApplication.willEnterForegroundNotification,
                                          object: nil
        )
    }

    func animateBrightness(to value: CGFloat, duration: CGFloat = 0.3) {
        UIScreen.main.animateBrightnessChange(to: value, duration: duration)
    }

    @objc func systemBrightnessChanged() {
        let conversionThreshold: Float = 0.03 // threshold for conversion error value

        //incase the control center is opened without any changes in the brightness.
        //except setting the brightness value to the system one by the willResignActiveNotification observer.
        //reseting the value of brightness to the player one.
        if abs(Float(UIScreen.main.brightness - self.systemBrightness!)) <= conversionThreshold {
            animateBrightness(to: CGFloat(self.brightnessControl.value))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            // Compare the current screen brightness with the value from the brightness control.
            // If they are different, the value is changed to the control center value.
            // This is important to ensure we do not lose track of the actual system brightness setting

            if abs(Float(UIScreen.main.brightness) - self.brightnessControl.value) > conversionThreshold {
                let brightness = UIScreen.main.brightness
                self.systemBrightness = brightness
                self.brightnessControl.value = Float(brightness)
                self.brightnessControlView.updateIcon(level: Float(brightness))
            }
        })
    }

    @objc func playerWillResignActive() {
        animateBrightness(to: systemBrightness!)
    }

    @objc func playerWillEnterForeground() {
        //updates the value of system brightness
        //if the brightness is changed when the player was in the background
        self.systemBrightness = UIScreen.main.brightness
        animateBrightness(to: systemBrightness!)
    }
#endif

    // MARK: - Gesture handlers

    @objc func handlePlayPauseGesture() {
        guard playerController.isPlayPauseGestureEnabled else {
            return
        }

        togglePlayPause()
    }

    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let verticalPanVelocity: Float = Float(recognizer.velocity(in: view).y)

        let currentPos = recognizer.location(in: view)

        let panType = detectPanType(recognizer)
        if panType == .none {
            return handleMinimizeGesture(recognizer)
        }

#if os(iOS)
        guard panType == .projection
                || (panType == .volume && playerController.isVolumeGestureEnabled)
                || (panType == .brightness && playerController.isBrightnessGestureEnabled)
        else {
            return
        }
#else
        guard panType == .projection
        else {
            return
        }
#endif

        if recognizer.state == .began {
            isGestureActive = true
            var animations : (() -> Void)?
            currentPanType = panType
#if os(iOS)
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
#endif
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
#if os(iOS)
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
#endif
        case .projection:
            updateProjection(with: recognizer)
        case .none:
            break
        }

        if recognizer.state == .ended {
            var animations : (() -> Void)?

#if os(iOS)
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
#endif

#if os(iOS)
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
#else
            self.isGestureActive = false
            self.setControlsHidden(true, animated: true)
#endif

            currentPanType = .none
            if playbackService.currentMediaIs360Video {
                deviceMotion.startDeviceMotion()
            }
        }
    }

    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        if playbackService.currentMediaIs360Video {
            let zoom: CGFloat = MediaProjection.FOV.default * -(ZOOM_SENSITIVITY * recognizer.velocity / screenPixelSize.width)
            if playbackService.updateViewpoint(0, pitch: 0,
                                               roll: 0, fov: zoom, absolute: false) {
                // Clam FOV between min and max
                fov = max(min(fov + zoom, MediaProjection.FOV.max), MediaProjection.FOV.min)
            }
        }
    }

    @objc func handleSwipeGestures(recognizer: UISwipeGestureRecognizer) {
        guard playerController.isSwipeSeekGestureEnabled else {
            return
        }

        // Make sure that we are currently not scrubbing in order to avoid conflicts.
        guard mediaScrubProgressBar.isScrubbing == false else {
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

    @objc private func handleMinimizeGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            // Save the initial center position of the view
            minimizationInitialCenter = view.center

        case .changed:
            // Move the view with the pan gesture
            if let initialCenter = minimizationInitialCenter, translation.y > 0 { // Only allow downward sliding
                view.center = CGPoint(x: view.center.x, y: initialCenter.y + translation.y)
            }

        case .ended, .cancelled, .failed:
            // Determine if the view should be dismissed or return to its original position
            if let initialCenter = minimizationInitialCenter {
                if translation.y > view.bounds.height * 0.1 { // Adjust the threshold as needed
                    minimizePlayer()
                } else {
                    // Animate the view returning to its original position
                    UIView.animate(withDuration: 0.3) {
                        self.view.center = initialCenter
                    }
                }
            }

            minimizationInitialCenter = nil
        default:
            break
        }
    }

    @objc func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        // CHECK THE TAP LOCATION

        executeSeekFromGesture(.tap)
    }

    @objc func updatePlayerControls() {
        // UPDATE THE PLAYER CONTROLS
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension PlayerViewController: VLCPlaybackServiceDelegate {
#if os(iOS)
    func pictureInPictureStateDidChange(enabled: Bool) {
        mediaNavigationBar.updatePictureInPictureButton(enabled: enabled)
    }
#endif

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        mediaScrubProgressBar.updateInterfacePosition()
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState, isPlaying: Bool, currentMediaHasTrackToChooseFrom: Bool, currentMediaHasChapters: Bool, for playbackService: PlaybackService) {
        if currentState == .opening {
            applyCustomEqualizerProfileIfNeeded()
        }

        if currentState == .stopped {
            moreOptionsActionSheet.resetPlaybackSpeed()
            mediaMoreOptionsActionSheetHideIcon(for: .playbackSpeed)
            moreOptionsActionSheet.resetSleepTimer()
            mediaMoreOptionsActionSheetHideIcon(for: .sleepTimer)
        }
    }

    func showStatusMessage(_ statusMessage: String) {
        statusLabel.showStatusMessage(statusMessage)
    }

    func reloadPlayQueue() {
        guard let queueViewController = queueViewController else {
            return
        }

        queueViewController.reload()
    }
}

// MARK: - MediaNavigationBarDelegate

extension PlayerViewController: MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar) {
        playbackService.stopPlayback()
    }

    func mediaNavigationBarDidCloseLongPress(_ mediaNavigationBar: MediaNavigationBar) {
        playbackService.stopPlayback()
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension PlayerViewController: MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        // DISABLE GESTURES
    }

    func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .playbackSpeed:
            showIcon(button: optionsNavigationBar.playbackSpeedButton)
            break
        case .sleepTimer:
            showIcon(button: optionsNavigationBar.sleepTimerButton)
            break
        case .equalizer:
            showIcon(button: optionsNavigationBar.equalizerButton)
            break
        case .abRepeat:
            showIcon(button: optionsNavigationBar.abRepeatButton)
            break
        case .abRepeatMarks:
            showIcon(button: optionsNavigationBar.abRepeatMarksButton)
            break
        default:
            assertionFailure("PlayerViewController: Invalid option.")
        }
    }

    func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier) {
        switch option {
        case .playbackSpeed:
            hideIcon(button: optionsNavigationBar.playbackSpeedButton)
            break
        case .sleepTimer:
            hideIcon(button: optionsNavigationBar.sleepTimerButton)
            break
        case .equalizer:
            hideIcon(button: optionsNavigationBar.equalizerButton)
            break
        case .abRepeat:
            hideIcon(button: optionsNavigationBar.abRepeatButton)
            break
        case .abRepeatMarks:
            hideIcon(button: optionsNavigationBar.abRepeatMarksButton)
            break
        default:
            assertionFailure("PlayerViewController: Invalid option.")
        }
    }

    func mediaMoreOptionsActionSheetHideAlertIfNecessary() {
        guard let alertController = alertController else {
            return
        }

        alertController.dismiss(animated: true)
        self.alertController = nil
    }

    func mediaMoreOptionsActionSheetPresentPopupView(withChild child: UIView) {
        if let equalizerView = child as? EqualizerView {
            guard !equalizerPopupView.isShown else {
                return
            }

            showPopup(equalizerPopupView, with: equalizerView, accessoryViewsDelegate: equalizerView)
        }
    }

    func mediaMoreOptionsActionSheetDisplayEqualizerAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
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

        return mediaLibraryService.fetchMedia(with: media.url)
    }

    func mediaMoreOptionsActionSheetDidSelectBookmark(value: Float) {
        mediaScrubProgressBar.updateSliderWithValue(value: value)

        if !playbackService.isPlaying {
            playbackService.playPause()
        }
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
    }

    func mediaMoreOptionsActionSheetRemoveAddBookmarksView() {
        shouldDisableGestures(false)

        mediaNavigationBar.isHidden = false

        if let bookmarksView = addBookmarksView {
            bookmarksView.removeFromSuperview()
        }

        addBookmarksView = nil
    }

    func mediaMoreOptionsActionSheetDidToggleShuffle(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        updateShuffleState()

        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    func mediaMoreOptionsActionSheetDidTapRepeat(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        updateRepeatMode()

        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    func mediaMoreOptionsActionSheetPresentABRepeatView(with abView: ABRepeatView) {
        abView.translatesAutoresizingMaskIntoConstraints = false
        abRepeatView = abView

        guard let abRepeatView = abRepeatView else {
            return
        }

        abRepeatView.aMarkView.isHidden = false
        mediaScrubProgressBar.shouldHideScrubLabels = true
    }

    func mediaMoreOptionsActionSheetDidSelectAMark() {
        mediaScrubProgressBar.setMark(aMark)
        aMark.isEnabled = true
    }

    func mediaMoreOptionsActionSheetDidSelectBMark() {
        mediaScrubProgressBar.setMark(bMark)
        bMark.isEnabled = true
        mediaScrubProgressBar.shouldHideScrubLabels = false
        abRepeatView?.removeFromSuperview()
    }
}

// MARK: - OptionsNavigationBarDelegate

extension PlayerViewController: OptionsNavigationBarDelegate {
    func optionsNavigationBarDisplayAlert(title: String, message: String, button: UIButton) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)

        let resetButton = UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.handleReset(button: button)
        }

        alertController.addAction(cancelButton)
        alertController.addAction(resetButton)

        self.present(alertController, animated: true)
        self.alertController = alertController
    }

    func optionsNavigationBarGetRemainingTime() -> String {
        return moreOptionsActionSheet.getRemainingTime()
    }

    func resetABRepeat() {
        hideIcon(button: optionsNavigationBar.abRepeatButton)
        if let abRepeatView = abRepeatView {
            abRepeatView.removeFromSuperview()
        }
        resetABRepeatMarks()
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
}

// MARK: - MediaScrubProgressBarDelegate

extension PlayerViewController: MediaScrubProgressBarDelegate {
    func mediaScrubProgressBarSetPlaybackPosition(to value: Float) {
        playbackService.playbackPosition = value
    }

    func mediaScrubProgressBarGetAMark() -> ABRepeatMarkView {
        return aMark
    }

    func mediaScrubProgressBarGetBMark() -> ABRepeatMarkView {
        return bMark
    }
}

// MARK: - PopupViewDelegate

extension PlayerViewController: PopupViewDelegate {
    @objc func popupViewDidClose(_ popupView: PopupView) {
        shouldDisableGestures(false)

        popupView.isShown = false
    }
}

// MARK: - DeviceMotionDelegate

extension PlayerViewController: DeviceMotionDelegate {
    func deviceMotionHasAttitude(deviceMotion: DeviceMotion, pitch: Double, yaw: Double) {
        if panRecognizer.state != .changed
            || panRecognizer.state != .began {
            applyYaw(yaw: CGFloat(yaw), pitch: CGFloat(pitch))
        }
    }
}

// MARK: - VLCRendererDiscovererManagerDelegate

#if os(iOS)
extension PlayerViewController: VLCRendererDiscovererManagerDelegate {
    func removedCurrentRendererItem(_ item: VLCRendererItem) {
        changeOutputView(to: contentOutputView)
        mediaNavigationBar.updateDeviceButton(with: UIImage(named: "renderer"), color: .white)
    }
}
#endif

// MARK: - Keyboard Controls

extension PlayerViewController {
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

    @objc func keyNumber(_ n: Int) {
        guard playbackService.isSeekable else { return }

        // n=6 --> seek to 60%
        playbackService.playbackPosition = (Float(n) / 10.0)
    }

    @objc func keyNumber1() {
        keyNumber(1)
    }

    @objc func keyNumber2() {
        keyNumber(2)
    }

    @objc func keyNumber3() {
        keyNumber(3)
    }

    @objc func keyNumber4() {
        keyNumber(4)
    }

    @objc func keyNumber5() {
        keyNumber(5)
    }

    @objc func keyNumber6() {
        keyNumber(6)
    }

    @objc func keyNumber7() {
        keyNumber(7)
    }

    @objc func keyNumber8() {
        keyNumber(8)
    }

    @objc func keyNumber9() {
        keyNumber(9)
    }

    @objc func keyNumber0() {
        keyNumber(0)
    }

    override var keyCommands: [UIKeyCommand]? {
        let playPauseSpace = UIKeyCommand(input: " ",
                                          modifierFlags: [],
                                          action: #selector(handlePlayPauseGesture))
        playPauseSpace.discoverabilityTitle = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        let playPauseReturn = UIKeyCommand(input: "\r",
                                           modifierFlags: [],
                                           action: #selector(handlePlayPauseGesture))
        playPauseReturn.discoverabilityTitle = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        let jumpBack = UIKeyCommand(input: UIKeyCommand.inputLeftArrow,
                                    modifierFlags: [],
                                    action: #selector(keyLeftArrow))
        jumpBack.discoverabilityTitle = NSLocalizedString("KEY_JUMP_BACKWARDS", comment: "")
        let jumpForward = UIKeyCommand(input: UIKeyCommand.inputRightArrow,
                                       modifierFlags: [],
                                       action: #selector(keyRightArrow))
        jumpForward.discoverabilityTitle = NSLocalizedString("KEY_JUMP_FORWARDS", comment: "")
        let increaseSpeed = UIKeyCommand(input: "[",
                                         modifierFlags: [],
                                         action: #selector(keyRightBracket))
        increaseSpeed.discoverabilityTitle = NSLocalizedString("KEY_INCREASE_PLAYBACK_SPEED", comment: "")
        let decreaseSpeed = UIKeyCommand(input: "]",
                                         modifierFlags: [],
                                         action: #selector(keyLeftBracket))
        decreaseSpeed.discoverabilityTitle = NSLocalizedString("KEY_DECREASE_PLAYBACK_SPEED", comment: "")

        var commands: [UIKeyCommand] = {
            let playPauseCommand1 = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handlePlayPauseGesture))
            playPauseCommand1.discoverabilityTitle = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")

            let playPauseCommand2 = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(handlePlayPauseGesture))
            playPauseCommand2.discoverabilityTitle = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")

            let leftArrowCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(keyLeftArrow))
            leftArrowCommand.discoverabilityTitle = NSLocalizedString("KEY_JUMP_BACKWARDS", comment: "")

            let rightArrowCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(keyRightArrow))
            rightArrowCommand.discoverabilityTitle = NSLocalizedString("KEY_JUMP_FORWARDS", comment: "")

            let increaseSpeedCommand = UIKeyCommand(input: "[", modifierFlags: [], action: #selector(keyRightBracket))
            increaseSpeedCommand.discoverabilityTitle = NSLocalizedString("KEY_INCREASE_PLAYBACK_SPEED", comment: "")

            let decreaseSpeedCommand = UIKeyCommand(input: "]", modifierFlags: [], action: #selector(keyLeftBracket))
            decreaseSpeedCommand.discoverabilityTitle = NSLocalizedString("KEY_DECREASE_PLAYBACK_SPEED", comment: "")

            let numberCommands = (0...9).map { number -> UIKeyCommand in
                let input = "\(number)"
                let selector = Selector("keyNumber\(number)")
                let command = UIKeyCommand(input: input, modifierFlags: [], action: selector)
                command.discoverabilityTitle = String(format:NSLocalizedString("KEY_SEEK_TO_PERCENT", comment: ""), number * 10)
                return command
            }

            return [playPauseCommand1, playPauseCommand2, leftArrowCommand, rightArrowCommand, increaseSpeedCommand, decreaseSpeedCommand] + numberCommands
        }()

        if abs(playbackService.playbackRate - 1.0) > .ulpOfOne {
            let resetSpeed = UIKeyCommand(input: "=",
                                          modifierFlags: [],
                                          action: #selector(keyEqual))
            resetSpeed.discoverabilityTitle = NSLocalizedString("KEY_RESET_PLAYBACK_SPEED",
                                                                comment: "")
            commands.append(resetSpeed)
        }

        if #available(iOS 15, *) {
            commands.forEach {
                if $0.input == UIKeyCommand.inputRightArrow
                    || $0.input == UIKeyCommand.inputLeftArrow {
                    $0.wantsPriorityOverSystemBehavior = true
                }
            }
        }

        return commands
    }
}
