/*****************************************************************************
 * AutoRepeatButton.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

final class AutoRepeatButton: UIButton {
    private var repeatTimer: Timer?
    private var trackingStartTime: CFTimeInterval = 0
    private var hasRepeated = false

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let shouldTrack = super.beginTracking(touch, with: event)
        trackingStartTime = CACurrentMediaTime()
        hasRepeated = false
        scheduleRepeat(after: 0.5)
        return shouldTrack
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        stopRepeating()
        if !hasRepeated && isTouchInside {
            sendActions(for: .valueChanged)
        }
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        stopRepeating()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopRepeating()
        }
    }

    override func accessibilityActivate() -> Bool {
        sendActions(for: .valueChanged)
        return true
    }

    private func scheduleRepeat(after interval: TimeInterval) {
        let timer = Timer(timeInterval: interval, target: self, selector: #selector(repeatTimerFired), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        repeatTimer = timer
    }

    @objc private func repeatTimerFired() {
        guard isTracking else {
            stopRepeating()
            return
        }

        hasRepeated = true
        sendActions(for: .valueChanged)

        let heldDuration = CACurrentMediaTime() - trackingStartTime
        let interval: TimeInterval
        if heldDuration > 4 {
            interval = 0.15 / 9
        } else if heldDuration > 2 {
            interval = 0.15 / 3
        } else {
            interval = 0.15
        }
        scheduleRepeat(after: interval)
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}
