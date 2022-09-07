/*****************************************************************************
 * MiniPlayer.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCMiniPlayer)
protocol MiniPlayer: VLCMiniPlaybackViewInterface, VLCPlaybackServiceDelegate {
    var contentHeight: Float { get }
    func updatePlayPauseButton()
}
