/*****************************************************************************
 * FeedbackGenerators.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

///Haptic feedback generator wrapper that generates haptics *only when available*.

class ImpactFeedbackGenerator {

    private let feedbackGenerator = UIImpactFeedbackGenerator()

    func prepare() {
        feedbackGenerator.prepare()
    }

    func selectionChanged() {
        genericImpactFeedback(intensity: 0.5)
    }

    func limitOverstepped() {
        genericImpactFeedback(intensity: 1.0)
    }

    private func genericImpactFeedback(intensity: CGFloat) {
        feedbackGenerator.impactOccurred(intensity: intensity)
    }
}

class NotificationFeedbackGenerator {

    private let feedbackGenerator: UINotificationFeedbackGenerator?

    init() {
        feedbackGenerator = UINotificationFeedbackGenerator()
    }

    func prepare() {
        feedbackGenerator?.prepare()
    }

    func success() {
        feedbackGenerator?.notificationOccurred(.success)
    }

    func warning() {
        feedbackGenerator?.notificationOccurred(.warning)
    }

    func error() {
        feedbackGenerator?.notificationOccurred(.error)
    }
}
