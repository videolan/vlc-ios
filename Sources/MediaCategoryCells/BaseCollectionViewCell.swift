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

    class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        return CGSize.zero
    }

    class var cellPadding: CGFloat {
        return 0
    }
}
