/*****************************************************************************
 * UIButton+OverlayControl.swift
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

extension UIButton {
    func applyOverlayControlStyle(title: String?, image: UIImage?, isActive: Bool, cornerRadius: CGFloat, activeColor: UIColor? = nil) {
        let colors = PresentationTheme.currentExcludingWhite.colors
        let accentColor = activeColor ?? colors.orangeUI
        accessibilityTraits = isActive ? [.button, .selected] : .button

        var configuration = makeOverlayControlConfiguration(isActive: isActive, cornerRadius: cornerRadius, accentColor: accentColor)
        configuration.title = title
        configuration.image = image
        configuration.imagePadding = 8
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIButton.overlayControlFont
            return attributes
        }
        self.configuration = configuration
    }

    private func makeOverlayControlConfiguration(isActive: Bool, cornerRadius: CGFloat, accentColor: UIColor) -> UIButton.Configuration {
        let colors = PresentationTheme.currentExcludingWhite.colors
#if !os(visionOS)
        if #available(iOS 26.0, *), !UIAccessibility.isReduceTransparencyEnabled {
            var configuration: UIButton.Configuration = isActive ? .prominentGlass() : .glass()
            if isActive {
                configuration.baseBackgroundColor = accentColor
                configuration.baseForegroundColor = .white
            } else {
                configuration.baseForegroundColor = colors.overlayPrimaryTextColor
            }
            configuration.cornerStyle = .capsule
            return configuration
        }
#endif
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = isActive ? accentColor : colors.overlayPrimaryTextColor
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = cornerRadius
        configuration.background.strokeWidth = 1
        configuration.background.strokeColor = isActive ? accentColor : colors.overlayHairlineColor
        if isActive {
            configuration.background.backgroundColor = accentColor.withAlphaComponent(0.2)
        } else if UIAccessibility.isReduceTransparencyEnabled || UIAccessibility.isDarkerSystemColorsEnabled {
            configuration.background.backgroundColor = colors.background
        } else {
            configuration.background.backgroundColor = colors.overlayControlFillColor
        }
        return configuration
    }

    private static var overlayControlFont: UIFont {
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
    }
}
