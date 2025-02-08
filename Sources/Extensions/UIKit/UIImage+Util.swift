/*****************************************************************************
 * UIImage+Util.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension UIImage {
    /// Returns a UIImage with the given systemName, unless running an older
    /// version of iOS, in which case it returns nil.
    static func with(systemName: String) -> UIImage? {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return UIImage(systemName: systemName)
        } else {
            return nil
        }
    }
}
