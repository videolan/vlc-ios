/*****************************************************************************
 * SortOption.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

public enum SortOption:String {
    case alphabetically = "Name"
    case insertonDate = "Date"
    case size = "Size"

    var localizedDescription: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
