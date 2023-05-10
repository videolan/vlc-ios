/*****************************************************************************
 * UIImage+Gradient.swift
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

    func imageWithGradient() -> UIImage {
        autoreleasepool {
            UIGraphicsBeginImageContext(self.size)
            let context = UIGraphicsGetCurrentContext()

            self.draw(at: CGPoint(x: 0, y: 0))

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let loc: [CGFloat] = [0.0, 0.65, 1.0]

            let top = UIColor.black.cgColor
            let middle = UIColor.clear.cgColor
            let bottom = UIColor.black.cgColor

            let colors = [top, middle, bottom] as CFArray

            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: loc)

            let startPoint = CGPoint(x: self.size.width/2, y: 0)
            let endPoint = CGPoint(x: self.size.width/2, y: self.size.height)

            guard let context = context,
                  let gradient = gradient else {
                UIGraphicsEndImageContext()
                return self
            }

            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))

            let image = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()

            guard let image = image else {
                return self
            }

            return image
        }
    }
}
