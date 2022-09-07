/*****************************************************************************
 * UIFont+Styling.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2021 VLC authors and VideoLAN
 * Copyright © 2021 Videolabs
 *
 * Authors: Felix Paul Kühne <fkuehne@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UIFont {

    /// Returns a bold version of `self`
    public var bolded: UIFont {
        return fontDescriptor.withSymbolicTraits(.traitBold)
            .map { UIFont(descriptor: $0, size: 0) } ?? self
    }

    /// Returns a semi-bold version of `self`
    public var semibolded: UIFont {
        let newDescriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        newDescriptor!.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]])
        return UIFont(descriptor: newDescriptor!, size: 0)
    }

    /// Returns a scaled version of `self`
    func scaled(scaleFactor: CGFloat) -> UIFont {
        let newDescriptor = fontDescriptor.withSize(fontDescriptor.pointSize * scaleFactor)
        return UIFont(descriptor: newDescriptor, size: 0)
    }

    class func preferredCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let systemFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        let customFontDescriptor = UIFontDescriptor.init(fontAttributes: [
            UIFontDescriptor.AttributeName.size: systemFontDescriptor.pointSize
        ])

        return UIFont(descriptor: customFontDescriptor, size: 0)
    }

}
