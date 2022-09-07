/*****************************************************************************
 * UISegmentedControl+CustomLabels.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2021 VLC authors and VideoLAN
 * Copyright © 2021 Videolabs
 *
 * Authors: Maxime CHAPELET <umxprime@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension UISegmentedControl {
    /// Allow multiline text with hyphenation by constraining labels size to match their segment superview
    func extendAndHyphenateLabels() {
        let horizontalMargin: CGFloat = 8.0
        let verticalMargin: CGFloat = 0.0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0
        paragraphStyle.alignment = .center

        let hyphenAttribute = [
            NSAttributedString.Key.paragraphStyle : paragraphStyle,
        ] as [NSAttributedString.Key: Any]

        self.setTitleTextAttributes(hyphenAttribute, for: .normal)
        self.setTitleTextAttributes(hyphenAttribute, for: .selected)

        for segment in self.subviews {
            guard let segment = segment as? UIImageView else {continue}
            for label in segment.subviews {
                guard let label = label as? UILabel else {continue}

                label.translatesAutoresizingMaskIntoConstraints = false
                let widthConstraint = NSLayoutConstraint(item: label,
                                                         attribute: .width,
                                                         relatedBy: .equal,
                                                         toItem: segment,
                                                         attribute: .width,
                                                         multiplier: 1.0,
                                                         constant: -horizontalMargin)
                widthConstraint.priority = .defaultHigh
                let heightConstraint = NSLayoutConstraint(item: label,
                                                          attribute: .height,
                                                          relatedBy: .equal,
                                                          toItem: segment,
                                                          attribute: .height,
                                                          multiplier: 1.0,
                                                          constant: verticalMargin)

                segment.addConstraints([widthConstraint, heightConstraint])
            }
        }
    }
}
