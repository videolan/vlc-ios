/*****************************************************************************
 * UIScrollView+VLCMiniPlayerInset.swift
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

extension UIScrollView {
    func setMiniPlayerInset(_ visible: Bool) {
        let inset = visible ? CGFloat(AudioMiniPlayer.height) : 0
        contentInset.bottom = inset
        verticalScrollIndicatorInsets.bottom = inset
    }
}
