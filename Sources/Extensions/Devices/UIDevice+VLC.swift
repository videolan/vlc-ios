/*****************************************************************************
 * UIDevice+VLC.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc extension UIDevice {

    @available(*, deprecated, message: "read safeAreaInsets from the view's own window instead")
    static var keyWindowSafeAreaInsets: UIEdgeInsets {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return keyWindow?.safeAreaInsets ?? .zero
    }

    @available(*, deprecated, message: "read safeAreaInsets from the view's own window instead")
    @objc(VLCDeviceHasSafeArea)
    static var hasSafeArea: Bool {
        return keyWindowSafeAreaInsets.bottom > 0
    }

    @available(*, deprecated, message: "read safeAreaInsets from the view's own window instead")
    static var hasNotch: Bool {
        return hasSafeArea
    }
}
