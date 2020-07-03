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

@available(iOS 10.0, *)
class ImpactFeedbackGenerator {

    private let feedbackGenerator: UIFeedbackGenerator?

    init() {
        if #available(iOS 13, *) {
            feedbackGenerator = UIImpactFeedbackGenerator()
        }
        else {
            feedbackGenerator = UISelectionFeedbackGenerator()
        }
    }

    func prepare() {
        if #available(iOS 13, *) {
            guard let feedbackGenerator = feedbackGenerator as? UIImpactFeedbackGenerator else { return }
            feedbackGenerator.prepare()
        }
        else {
            guard let feedbackGenerator = feedbackGenerator as? UISelectionFeedbackGenerator else { return }
            feedbackGenerator.prepare()
        }
    }

    func selectionChanged() {
        if #available(iOS 13, *) {
            guard let feedbackGenerator = feedbackGenerator as? UIImpactFeedbackGenerator else { return }
            feedbackGenerator.impactOccurred(intensity: 0.5)
        }
        else {
            guard let feedbackGenerator = feedbackGenerator as? UISelectionFeedbackGenerator else { return }
            feedbackGenerator.selectionChanged()
        }
    }
}

@available(iOS 10.0, *)
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
