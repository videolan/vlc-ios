/*****************************************************************************
 * VLCAccessibilityIdentifier.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc class VLCAccessibilityIdentifier: NSObject {
    static let video = "video"
    static let audio = "audio"
    static let songs = "songs"
    static let artists = "artists"
    @objc static let localNetwork = "localNetwork"
    static let playlist = "playlist"
    @objc static let settings = "settings"
    static let local = "local"
    static let cloud = "cloud"
    static let stream = "stream"
    static let downloads = "downloads"
    static let favorite = "favorite"
    @objc static let done = "done"
    static let contact = "contact"
    @objc static let about = "about"
    @objc static let playPause = "playPause"
    static let videoPlayerScrubBar = "videoPlayerScrubBar"
}
