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
            // For some reason, an image specified on these accessibility
            // actions will get scaled up in size significantly. Below, we work
            // against that by adding our own padding to the image. If Apple
            // ever fixes the problem on their end, or offers an alternative
            // approach to prevent this from happening, everything below should
            // be removed or at least made conditional based on OS version.
            a.image = image.flatMap { img in
                // This was determined empirically:
                let newSize = CGSize(width: 40, height: 40)

                let renderer = UIGraphicsImageRenderer(size: newSize)
                return renderer.image { context in
                    UIColor.clear.setFill()
                    context.fill(CGRect(origin: .zero, size: newSize))

                    let x = (newSize.width - img.size.width) / 2
                    let y = (newSize.height - img.size.height) / 2
                    let imageOrigin = CGPoint(x: x, y: y)
                    img.draw(at: imageOrigin)
                }
            }
        }

        return a
    }
}
