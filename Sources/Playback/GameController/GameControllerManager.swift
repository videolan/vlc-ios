/*****************************************************************************
 * GameControllerManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import GameController

enum PlayerSeekState {
    case `default`
    case forward
    case backward
}

@objc(VLCGameControllerManagerDelegate)
protocol GameControllerManagerDelegate: AnyObject {
    func gameControllerManagerDelegateDidTapForward(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapPlayPause(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapBackward(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapClosePlayer(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapVolume(_ gameControllerManager: GameControllerManager, _ value: Float)
    func gameControllerManagerDelegateDidTapForwardLong(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapBackwardLong(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapPreviousMedia(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTapNextMedia(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidScrubForward(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidScrubBackward(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTogglePlayerQueue(_ gameControllerManager: GameControllerManager)
    func gameControllerManagerDelegateDidTogglePlayerOptions(_ gameControllerManager: GameControllerManager)
}

class GameControllerManager: NSObject {
    
    private(set) var connectedControllers: [GCController] = []
    
    private var observers: [NSObjectProtocol] = []
    @objc weak var delegate: GameControllerManagerDelegate?
    
    private var seekTimer: Timer?
    private var currentDirection: PlayerSeekState?
    private let volumeValue: Float = 0.10
    private let xValueThreshold: Float = 0.5
    private let scrubTimeInterval: TimeInterval = 0.2
    
    @objc func startMonitoring() {
        // Get the controllers that were connected before the app launched.
        connectedControllers = GCController.controllers()

        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.handleControllerConnected(controller)
        }
        
        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.handleControllerDisconnected(controller)
        }
        
        observers = [connectObserver, disconnectObserver]
        
        connectedControllers.forEach { controller in
            handleControllerConnected(controller)
        }
    }
    
    func stopMonitoring() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }
    
    private func handleControllerConnected(_ controller: GCController) {
        connectedControllers.append(controller)
        configureController(controller)
    }
    
    private func handleControllerDisconnected(_ controller: GCController) {
        connectedControllers.removeAll { $0 == controller }
        unassignController(controller)
    }
    
    private func configureController(_ controller: GCController) {
        
        if let gamepad = controller.extendedGamepad {
            setupExtendedGamepadHandlers(gamepad)
            return
        }

#if !os(tvOS)
        // Siri remote control already supported in tvOS, don't override default behavior
        if let gamepad = controller.microGamepad {
            setupMicroGamepadHandlers(gamepad)
            return
        }
#endif
    }

    private func unassignController(_ controller: GCController) {
        if let gamepad = controller.extendedGamepad {
            removeExtendedGamepadHandlers(gamepad)
            return
        }

        if let gamepad = controller.microGamepad {
            removeMicroGamepadHandlers(gamepad)
            return
        }
    }
    
    private func setupExtendedGamepadHandlers(_ gamepad: GCExtendedGamepad) {
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapPlayPause(self)
            }
        }
        
        gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapClosePlayer(self)
            }
        }
        
        gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapForward(self)
            }
        }

        gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapBackward(self)
            }
        }
#if os(iOS)
        // tvOS does not allow apps to control system volume
        gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapVolume(self, volumeValue)
            }
        }

        gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapVolume(self, -volumeValue)
            }
        }
#endif
        gamepad.leftTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapBackwardLong(self)
            }
        }
        
        gamepad.rightTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapForwardLong(self)
            }
        }
        
        gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapPreviousMedia(self)
            }
        }
        
        gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapNextMedia(self)
            }
        }
        
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] dpad, xValue, yValue in
            guard let self = self else { return }
            
            if xValue > xValueThreshold {
                self.startSeeking(direction: .forward)
            } else if xValue < -xValueThreshold {
                self.startSeeking(direction: .backward)
            } else {
                self.stopSeeking()
            }
        }
        
        if #available(iOS 13.0, *, tvOS 13.0, *) {
            gamepad.buttonOptions?.pressedChangedHandler = { [weak self] _, _, pressed in
                guard let self else { return }
                if pressed {
                    self.delegate?.gameControllerManagerDelegateDidTogglePlayerQueue(self)
                }
            }
        }
        
        if #available(iOS 13.0, *, tvOS 13.0, *) {
            gamepad.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
                guard let self else { return }
                if pressed {
                    self.delegate?.gameControllerManagerDelegateDidTogglePlayerOptions(self)
                }
            }
        }
    }
    
    private func startSeeking(direction: PlayerSeekState) {
        guard seekTimer == nil && currentDirection != direction else { return }
        
        stopSeeking()
        currentDirection = direction
        
        seekTimer = Timer.scheduledTimer(withTimeInterval: scrubTimeInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if direction == .forward {
                self.delegate?.gameControllerManagerDelegateDidScrubForward(self)
            } else {
                self.delegate?.gameControllerManagerDelegateDidScrubBackward(self)
            }
        }
    }
    
    private func stopSeeking() {
        seekTimer?.invalidate()
        seekTimer = nil
        currentDirection = nil
    }
    
    private func setupMicroGamepadHandlers(_ gamepad: GCMicroGamepad) {
        gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapPlayPause(self)
            }
        }
        
        gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapForward(self)
            }
        }

        gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapBackward(self)
            }
        }
        
        gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapVolume(self, volumeValue)
            }
        }

        gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.delegate?.gameControllerManagerDelegateDidTapVolume(self, -volumeValue)
            }
        }
    }
    
    private func removeMicroGamepadHandlers(_ gamepad: GCMicroGamepad) {
        gamepad.dpad.right.pressedChangedHandler = nil
        gamepad.dpad.left.pressedChangedHandler = nil
    }
    
    private func removeExtendedGamepadHandlers(_ gamepad: GCExtendedGamepad) {
        gamepad.dpad.right.pressedChangedHandler = nil
        gamepad.dpad.left.pressedChangedHandler = nil
    }
}
