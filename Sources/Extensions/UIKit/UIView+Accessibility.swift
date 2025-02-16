/*****************************************************************************
 * UIView+Accessibility.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension UIView {
    /// Sets `accessibilityElements` using the elements provided, by filtering
    /// non-nil elements.
    public func applyAccessibilityControls(_ elements: UIView?...) {
        self.accessibilityElements = elements
            .compactMap { $0 }
    }
}
