/*****************************************************************************
 * UINavigationController+CollectionCategory.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UINavigationController {
    var topCollectionCategoryViewController: CollectionCategoryViewController? {
        let topViewController = viewControllers.last
        if #available(iOS 27.1, visionOS 27.1, *),
           let arrangementViewController = topViewController as? VLCArrangementViewController {
            return arrangementViewController.primaryViewController as? CollectionCategoryViewController
        }
        return topViewController as? CollectionCategoryViewController
    }
}
