/*****************************************************************************
 * TimedColor.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


import UIKit
import WatchConnectivity

// Wrap a timed color payload dictionary with a stronger type.
struct TimedColor {
    var timeStamp: String
    var colorData: Data

    var color: UIColor {
        let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData)
        guard let color = uiColor as? UIColor else {
            fatalError("Failed to unarchive a UIColor object!")
        }
        return color
    }

    var timedColor: [String: Any] {
        return [PayloadKey.timeStamp: timeStamp, PayloadKey.colorData: colorData]
    }

    init(_ timedColor: [String: Any]) {
        guard let timeStamp = timedColor[PayloadKey.timeStamp] as? String,
            let colorData = timedColor[PayloadKey.colorData] as? Data else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.timeStamp = timeStamp
        self.colorData = colorData
    }

    init(_ timedColor: Data) {
        let data = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSString.self, NSData.self], from: timedColor)
        guard let dictionary = data as? [String: Any] else {
            fatalError("Failed to unarchive a timedColor dictionary!")
        }
        self.init(dictionary)
    }
}
