/*****************************************************************************
 * VLCAppDelegate+UITests.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Kevin Bettin <Kevin # evenly.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

extension VLCAppDelegate {

    @objc func setupUITests() {
        disableAnimations()
    }

    private func disableAnimations() {
        guard CommandLine.arguments.contains("-disableAnimations") else {
            UIView.setAnimationsEnabled(true)
            return
        }
        
        UIView.setAnimationsEnabled(false)
    }
}
