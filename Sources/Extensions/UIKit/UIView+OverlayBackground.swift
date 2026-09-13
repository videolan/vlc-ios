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
        if UIAccessibility.isReduceTransparencyEnabled {
            let view = UIView()
            view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
            return view
        }

#if !os(visionOS)
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect())
        }
#endif

        return UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    }
}
