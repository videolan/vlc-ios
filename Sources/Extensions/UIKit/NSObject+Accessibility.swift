/*****************************************************************************
 * NSObject+Accessibility.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension NSObject {
    /// 
    public func applyAccessibilityControls(_ elements: UIControl?...) {
        self.accessibilityElements = elements
            .compactMap {
                $0.flatMap {
                    $0.isEnabled && !$0.isHidden ? $0 : nil
                }
            }
    }
}
