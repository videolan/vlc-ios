/*****************************************************************************
 * PlayerController.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

struct MediaProjection {
    struct FOV {
        static let `default`: CGFloat = 80
        static let max: CGFloat = 150
        static let min: CGFloat = 20
    }
}

protocol PlayerControllerDelegate: AnyObject {
    func playerControllerExternalScreenDidConnect(_ playerController: PlayerController)
    func playerControllerExternalScreenDidDisconnect(_ playerController: PlayerController)
    func playerControllerApplicationBecameActive(_ playerController: PlayerController)
    func playerControllerPlaybackDidStop(_ playerController: PlayerController)
}

@objc(VLCPlayerController)
class PlayerController: NSObject {
    weak var delegate: PlayerControllerDelegate?

    private var playbackService: PlaybackService = PlaybackService.sharedInstance()

    // MARK: - States

    var isControlsHidden: Bool = false

    var lockedOrientation: UIInterfaceOrientation = .unknown

    var isInterfaceLocked: Bool = false

    var isTapSeeking: Bool = false

    // MARK: - UserDefaults computed properties getters

    var displayRemainingTime: Bool {
        return UserDefaults.standard.bool(forKey: kVLCShowRemainingTime)
    }

    var isVolumeGestureEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingVolumeGesture)
    }

    var isPlayPauseGestureEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingPlayPauseGesture)
    }

    var isBrightnessGestureEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingBrightnessGesture)
    }

    var isSwipeSeekGestureEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingSeekGesture)
    }

    var isCloseGestureEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingCloseGesture)
    }

    var isShuffleEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCPlayerIsShuffleEnabled)
    }

    var isRepeatEnabled: VLCRepeatMode {
        let storedValue = UserDefaults.standard.integer(forKey: kVLCPlayerIsRepeatEnabled)

        return VLCRepeatMode(rawValue: storedValue) ?? .doNotRepeat
    }

    var isRememberStateEnabled: Bool {
        return UserDefaults.standard.bool(forKey: kVLCPlayerShouldRememberState)
    }


    @objc override init() {
        super.init()
        setupObservers()
    }

    func updateUserDefaults() {

    }

    private func setupObservers() {
        let notificationCenter = NotificationCenter.default

        // External Screen
        if #available(iOS 13.0, *) {
            notificationCenter.addObserver(self,
                                           selector: #selector(handleExternalScreenDidConnect),
                                           name: NSNotification.Name(rawValue: VLCNonInteractiveWindowSceneBecameActive),
                                           object: nil)
            notificationCenter.addObserver(self,
                                           selector: #selector(handleExternalScreenDidDisconnect),
                                           name: NSNotification.Name(rawValue: VLCNonInteractiveWindowSceneDisconnected),
                                           object: nil)
        } else {
            notificationCenter.addObserver(self,
                                           selector: #selector(handleExternalScreenDidConnect),
                                           name: UIScreen.didConnectNotification,
                                           object: nil)
            notificationCenter.addObserver(self,
                                           selector: #selector(handleExternalScreenDidDisconnect),
                                           name: UIScreen.didDisconnectNotification,
                                           object: nil)
        }
        // UIApplication
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAppBecameActive),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
        //
        notificationCenter.addObserver(self,
                                       selector: #selector(handlePlaybackDidStop),
                                       name: NSNotification.Name(rawValue: VLCPlaybackServicePlaybackDidStop),
                                       object: nil)
    }
}

// MARK: - Observers

extension PlayerController {
    @objc func handleExternalScreenDidConnect() {
        delegate?.playerControllerExternalScreenDidConnect(self)
    }

    @objc func handleExternalScreenDidDisconnect() {
        delegate?.playerControllerExternalScreenDidDisconnect(self)
    }

    @objc func handleAppBecameActive() {
        delegate?.playerControllerApplicationBecameActive(self)
    }

    @objc func handlePlaybackDidStop() {
        delegate?.playerControllerPlaybackDidStop(self)
    }
}
