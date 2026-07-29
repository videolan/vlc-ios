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
    @objc func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
    }

    @objc func roundCorners(radius: CGFloat, maskedCorners: CACornerMask) {
        roundCorners(radius: radius)
        layer.maskedCorners = maskedCorners
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

@objc extension UIButton {
    // Accent-filled call to action on a card. Shape stays with the caller, so this
    // suits both the pill-shaped and the circular buttons.
    func styleAsPrimaryAction() {
        backgroundColor = PresentationTheme.current.colors.orangeUI
        tintColor = .white
        setTitleColor(.white, for: .normal)
    }

    // Outlined counterpart, used beside a primary action.
    func styleAsSecondaryAction() {
        let colors = PresentationTheme.current.colors
        backgroundColor = .clear
        tintColor = colors.cellTextColor
        setTitleColor(colors.cellTextColor, for: .normal)
        layer.borderWidth = 1
        layer.borderColor = colors.cellDetailTextColor.cgColor
    }
}
