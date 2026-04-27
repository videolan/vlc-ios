/*****************************************************************************
 * Character+Utility.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Timmy Nguyen <timmypass21 # gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


import Foundation

// Find out if Character in String is emoji by Kevin R (https://stackoverflow.com/a/39425959/20237973)
extension Character {
    // A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    // Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }

    var isLatin: Bool {
        return String(self).range(of: "\\p{Latin}", options: .regularExpression) != nil
    }
}
