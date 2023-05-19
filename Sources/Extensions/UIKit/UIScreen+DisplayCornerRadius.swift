/*****************************************************************************
 * UIScreen+DisplayCornerRadius.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2023 VLC authors and VideoLAN
 * Copyright © 2023 Videolabs
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UIScreen {
    public var displayCornerRadius: CGFloat {
        let selector = NSSelectorFromString("_displayCornerRadius")
        if self.responds(to: selector) {
            guard let cornerRadius = self.value(forKey: "_displayCornerRadius") as? CGFloat else {
                return 0.0
            }

            return cornerRadius
        }
        return 0.0
    }
}
