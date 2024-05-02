/*****************************************************************************
 * MLWidgetBridge.swift
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

struct MLWidgetBridge: Codable {
    var albumName: String
    var artistName: String
    var imageData: String
    var mediaURL: String

    // The average color of the imageData
    var color: CodableColor
}

struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
}
