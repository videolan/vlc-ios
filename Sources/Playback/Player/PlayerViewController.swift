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

enum PlayerPanType {
    case none
    case brightness
    case volume
    case projection
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
    var rendererDiscovererManager: VLCRendererDiscovererManager
    var playerController: PlayerController
    var playbackService: PlaybackService = PlaybackService.sharedInstance()
    var queueViewController: QueueViewController?
    var alertController: UIAlertController?
    var seekBy: Int = 0

    lazy var statusLabel: VLCStatusLabel = {
        var statusLabel = VLCStatusLabel()
        statusLabel.isHidden = true
        statusLabel.textColor = .white
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }()

    lazy var mediaNavigationBar: MediaNavigationBar = {
        var mediaNavigationBar = MediaNavigationBar(frame: .zero,
                                                    rendererDiscovererService: rendererDiscovererManager)
        mediaNavigationBar.delegate = self
        mediaNavigationBar.presentingViewController = self
        mediaNavigationBar.chromeCastButton.isHidden =
            self.playbackService.renderer == nil
        return mediaNavigationBar
    }()

    lazy var mediaScrubProgressBar: MediaScrubProgressBar = {
        var mediaScrubProgressBar: MediaScrubProgressBar = MediaScrubProgressBar()
        return mediaScrubProgressBar
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

    lazy var sideBackgroundGradientView: UIView = {
        let backgroundGradientView = UIView()
        backgroundGradientView.frame = UIScreen.main.bounds
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

    let volumeView = MPVolumeView(frame: .zero)

    var addBookmarksView: AddBookmarksView? = nil

    var mediaDuration: Int = 0

    private var isGestureActive: Bool = false

    private var currentPanType: PlayerPanType = .none

    private var projectionLocation: CGPoint = .zero

    private var fov: CGFloat = 0

    private lazy var deviceMotion: DeviceMotion = {
        let deviceMotion = DeviceMotion()
        deviceMotion.delegate = self
        return deviceMotion
    }()

    private let ZOOM_SENSITIVITY: CGFloat = 5

    private let screenPixelSize = CGSize(width: UIScreen.main.bounds.width,
                                         height: UIScreen.main.bounds.height)

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

    // MARK: - Init

    @objc init(mediaLibraryService: MediaLibraryService, rendererDiscovererManager: VLCRendererDiscovererManager, playerController: PlayerController) {
        self.mediaLibraryService = mediaLibraryService
        self.rendererDiscovererManager = rendererDiscovererManager
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
    }

    // MARK: - Private methods

    private func jumpBackwards(_ interval: Int = 10) {
        playbackService.jumpBackward(Int32(interval))
    }

    private func jumpForwards(_ interval: Int = 10) {
        playbackService.jumpForward(Int32(interval))
    }

    private func showIcon(button: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            button.isHidden = false
        }, completion: nil)
    }

    private func openOptionView(view: MediaPlayerActionSheetCellIdentifier) {
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
        default:
            assertionFailure("VideoPlayerViewController: Unvalid button.")
        }
    }

    private func detectPanType(_ recognizer: UIPanGestureRecognizer) -> PlayerPanType {
        let window: UIWindow = UIApplication.shared.keyWindow!
        let windowWidth: CGFloat = window.bounds.width
        let location: CGPoint = recognizer.location(in: window)

        // Default or right side of the screen
        var panType: PlayerPanType = .volume

        if location.x < windowWidth / 2 {
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

    // MARK: - Gesture handlers

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

    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let verticalPanVelocity: Float = Float(recognizer.velocity(in: view).y)

        let currentPos = recognizer.location(in: view)

        let panType = detectPanType(recognizer)

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

    @objc private func handleSwipeGestures(recognizer: UISwipeGestureRecognizer) {
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
            let timeRemaining = -Int(Double(playbackService.remainingTime().intValue) * 0.001)

            if seekBy < timeRemaining {
                if seekBy < 1 {
                    seekBy = 1
                }

                jumpForwards(seekBy)
                hudString = String(format: "⇒ %is", seekBy)
            } else {
                jumpForwards(timeRemaining - 5)
                hudString = String(format: "⇒ %is", (timeRemaining - 5))
            }
        case .left:
            jumpBackwards(seekBy)
            hudString = String(format: "⇐ %is", seekBy)
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
}

// MARK: - VLCPlaybackServiceDelegate

extension PlayerViewController: VLCPlaybackServiceDelegate {
    func savePlaybackState(_ playbackService: PlaybackService) {
        mediaLibraryService.savePlaybackState(from: playbackService)
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        mediaScrubProgressBar.updateInterfacePosition()
    }

    func showStatusMessage(_ statusMessage: String) {
        statusLabel.showStatusMessage(statusMessage)
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
        default:
            assertionFailure("AudioPlayerViewController: Invalid option.")
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
        default:
            assertionFailure("AudioPlayerViewController: Invalid option.")
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
        moreOptionsActionSheet.dismiss(animated: true, completion: {
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

            self.present(alertController, animated: true, completion: nil)
            self.alertController = alertController
        })
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
        playbackService.isShuffleMode = !playbackService.isShuffleMode

        if playerController.isRememberStateEnabled {
            UserDefaults.standard.setValue(playbackService.isShuffleMode, forKey: kVLCPlayerIsShuffleEnabled)
        }

        mediaMoreOptionsActionSheet.collectionView.reloadData()
    }

    func mediaMoreOptionsActionSheetDidTapRepeat(_ mediaMoreOptionsActionSheet: MediaMoreOptionsActionSheet) {
        playbackService.toggleRepeatMode()
        mediaMoreOptionsActionSheet.collectionView.reloadData()
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

// MARK: - Keyboard Controls

extension PlayerViewController {
    @objc func keyLeftArrow() {
        jumpBackwards(seekBy)
    }

    @objc func keyRightArrow() {
        jumpForwards(seekBy)
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
