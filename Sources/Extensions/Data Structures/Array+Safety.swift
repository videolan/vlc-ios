/*****************************************************************************
 * Array+Safety.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Author: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension Array {
     func objectAtIndex(index: Int) -> Element? {
         return index < self.count ? self[index] : nil
    }
}
