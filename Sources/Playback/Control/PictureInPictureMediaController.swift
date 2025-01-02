/*****************************************************************************
 * PictureInPictureMediaController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Maxime Chapelet <umxprime # videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import VLCKit

@objc(VLCPictureInPictureMediaController)
final class PictureInPictureMediaController: NSObject {
    private let mediaPlayer: VLCMediaPlayer
    @objc(initWithMediaPlayer:)
    init(_ mediaPlayer: VLCMediaPlayer) {
        self.mediaPlayer = mediaPlayer
    }
}

extension PictureInPictureMediaController: VLCPictureInPictureMediaControlling {
    func play() {
        mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }

    func seek(by offset: Int64, completion: (() -> Void)!) {
        mediaPlayer.jump(withOffset: Int32(offset), completion: completion)
    }

    func mediaLength() -> Int64 {
        return mediaPlayer.media?.length.value?.int64Value ?? 0
    }

    func mediaTime() -> Int64 {
        return mediaPlayer.time.value?.int64Value ?? 0
    }

    func isMediaSeekable() -> Bool {
        return mediaPlayer.isSeekable
    }

    func isMediaPlaying() -> Bool {
        return mediaPlayer.isPlaying
    }
}
