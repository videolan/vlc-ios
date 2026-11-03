/*****************************************************************************
 * BaseCollectionViewCell.Swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class BaseCollectionViewCell: UICollectionViewCell {

    static var defaultReuseIdentifier: String {
        return NSStringFromClass(self)
    }

    class var nibName: String {
        return String(describing:self)
    }

    var media: VLCMLObject?

    private(set) var checkImageView: UIImageView?
    private(set) var selectionViewOverlay: UIView?
    private(set) var secondDescriptionLabelView: UILabel?
    private(set) var descriptionSeparatorLabel: UILabel?

    @available(*, deprecated, message: "use numberOfColumns(for:safeAreaInsets:) instead")
    class func numberOfColumns(for width: CGFloat) -> CGFloat {
        return numberOfColumns(for: width, safeAreaInsets: UIDevice.keyWindowSafeAreaInsets)
    }

    class func numberOfColumns(for width: CGFloat, safeAreaInsets: UIEdgeInsets) -> CGFloat {
        return CGFloat.zero
    }

    @available(*, deprecated, message: "use cellSizeForWidth(_:safeAreaInsets:) instead")
    class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        return cellSizeForWidth(width, safeAreaInsets: UIDevice.keyWindowSafeAreaInsets)
    }

    class func cellSizeForWidth(_ width: CGFloat, safeAreaInsets: UIEdgeInsets) -> CGSize {
        return CGSize.zero
    }

    class var edgePadding: CGFloat {
        return 15
    }

    class var interItemPadding: CGFloat {
        return 5
    }

    func update(folderLocation location: VLCMLFolder.Location) {
    }

    func scaleUpCell(with duration: CGFloat, and scale: CGFloat) {
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: { _ in
            self.transform = .identity
        }
    }
}

enum LayoutWidth: CGFloat {
    /// The narrowest phone layout, as on the iPhone SE 1st generation in portrait.
    case narrowest = 320
    /// Phones in portrait, up to the folded iPhone Duo held upright (466 pt).
    case compact = 480
    /// Phones in landscape and most iPads in portrait.
    case medium = 926
    /// Large iPads in portrait and small iPads in landscape.
    case regular = 1024
}
