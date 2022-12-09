/*****************************************************************************
 * UIImage+TintColor.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UIImage {
    func imageWithTint(tint: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext(),
              let cgImage = self.cgImage else {
            return self
        }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(origin: .zero, size: size)
        context.clip(to: rect, mask: cgImage)
        tint.setFill()
        context.fill(rect)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return self
        }

        UIGraphicsEndImageContext()
        return image
    }
}
