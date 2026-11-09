/*****************************************************************************
 * UIView+OverlayBackground.swift
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

extension UIView {
    static func makeOverlayBackgroundView() -> UIView {
        let view = UIVisualEffectView()
        view.applyOverlayBackgroundStyle()
        return view
    }
}

extension UIVisualEffectView {
    func applyOverlayBackgroundStyle() {
        if UIAccessibility.isReduceTransparencyEnabled {
            effect = nil
            backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
            return
        }

        backgroundColor = .clear
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            effect = UIGlassEffect()
            return
        }
#endif

        effect = UIBlurEffect(style: .systemChromeMaterialDark)
    }
}
