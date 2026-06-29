/*****************************************************************************
 * UIView+Corners.swift
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
    func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
    }

    // Neutral rounded chrome for floating controls over the player (footer buttons, sync row).
    func styleAsNeutralOverlayControl(cornerRadius: CGFloat) {
        let colors = PresentationTheme.currentExcludingWhite.colors
        roundCorners(radius: cornerRadius)
        layer.borderWidth = 1
        layer.borderColor = colors.overlayHairlineColor.cgColor
        backgroundColor = UIAccessibility.isReduceTransparencyEnabled ? colors.background : colors.overlayControlFillColor
    }
}
