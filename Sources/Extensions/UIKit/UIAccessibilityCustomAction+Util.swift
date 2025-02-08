/*****************************************************************************
 * UIAccessibilityCustomAction+Util.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension UIAccessibilityCustomAction {
    /// Creates an instance of UIAccessibilityCustomAction with the title and
    /// image provided. Older versions of iOS will not use the image.
    static func create(name: String, image: UIImage?, target: Any?, selector: Selector) -> UIAccessibilityCustomAction {
        let a = UIAccessibilityCustomAction(name: name, target: target, selector: selector)

        if #available(iOS 13.0, *) {
            a.image = image
        }

        return a
    }
}
