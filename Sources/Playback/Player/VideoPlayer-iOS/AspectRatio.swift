/*****************************************************************************
 * AspectRatio.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc (VLCAspectRatio)
enum AspectRatio: Int, CaseIterable {
    case Default = 0
    case fillToScreen
    case fourToThree
    case fiveToFour
    case sixteenToNine
    case sixteenToTen
    case twentyOneToOne
    case thirtyFiveToOne
    case thirtyNineToOne

    var stringToDisplay: String {
        switch self {
        case .Default:
            return NSLocalizedString("DEFAULT", comment: "")
        case .fillToScreen:
            return NSLocalizedString("FILL_TO_SCREEN", comment: "")
        case .fourToThree:
            return "4:3"
        case .fiveToFour:
            return "5:4"
        case .sixteenToNine:
            return "16:9"
        case .sixteenToTen:
            return "16:10"
        case .twentyOneToOne:
            return "2.21:1"
        case .thirtyFiveToOne:
            return "2.35:1"
        case .thirtyNineToOne:
            return "2.39:1"
        }
    }

    var value: String {
        switch self {
        case .twentyOneToOne:
            return "221:100"
        case .thirtyFiveToOne:
            return "235:100"
        case .thirtyNineToOne:
            return "239:100"
        default:
            return stringToDisplay
        }
    }
}

@objc (VLCAspectRatioBridge)
class AspectRatioBridge: NSObject {
    @objc class func stringToDisplay(for rawValue: Int) -> String? {
        guard let aspectRatio = AspectRatio(rawValue: rawValue) else {
            return nil
        }

        return aspectRatio.stringToDisplay
    }

    @objc class func value(for rawValue: Int) -> String? {
        guard let aspectRatio = AspectRatio(rawValue: rawValue) else {
            return nil
        }

        return aspectRatio.value
    }
}
