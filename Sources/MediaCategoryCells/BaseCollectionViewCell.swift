/*****************************************************************************
 * BaseCollectionViewCell.Swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
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

    class func numberOfColumns(for width: CGFloat) -> CGFloat {
        return CGFloat.zero
    }

    class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        return CGSize.zero
    }

    class var edgePadding: CGFloat {
        return 15
    }

    class var interItemPadding: CGFloat {
        return 5
    }
}

enum DeviceWidth: CGFloat {
    case iPhonePortrait = 414
    case iPhoneLandscape = 896
    case iPadLandscape = 1024
}
