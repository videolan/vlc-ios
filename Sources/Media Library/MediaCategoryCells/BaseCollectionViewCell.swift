/*****************************************************************************
 * BaseCollectionViewCell.Swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
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

    func scaleUpCell(with duration: CGFloat, and scale: CGFloat) {
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: { _ in
            self.transform = .identity
        }
    }
}

enum DeviceDimensions: CGFloat {
    case iPhone4sPortrait = 320
    case iPhone5Landscape = 568
    case iPhone6Portrait = 375
    case iPhonePortrait = 414
    case iPhone12ProMaxPortrait = 428
    case iPhone14ProMaxPortrait = 430
    case iPhone16ProMaxPortrait = 440
    case iPhoneLandscape = 926
    case iPadLandscape = 1024
}
