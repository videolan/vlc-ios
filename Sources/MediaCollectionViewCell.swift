/*****************************************************************************
 * MediaCollectionViewCell.Swift
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

class MediaCollectionViewCell: UICollectionViewCell {

    static var defaultReuseIdentifier: String {
        return NSStringFromClass(self)
    }

    class var nibName: String {
        fatalError("needs to be implemented by subclass")
    }

    func sizeWithWidth(_ width: CGFloat, media: VLCMLObject) -> CGSize {
        return .zero
    }

    var media: VLCMLObject?
}
