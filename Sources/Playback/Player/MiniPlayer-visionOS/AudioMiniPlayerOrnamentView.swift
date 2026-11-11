/*****************************************************************************
 * AudioMiniPlayerOrnamentView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Neo Salmon <neos_dev@outlook.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import SwiftUI

struct AudioMiniPlayerOrnamentView: UIViewRepresentable {
    func makeUIView(context: Context) -> AudioMiniPlayer {
        let miniPlayer = AudioMiniPlayer()
        miniPlayer.prepare(forMediaPlayback: PlaybackService.sharedInstance())
        return miniPlayer
    }

    func updateUIView(_ uiView: AudioMiniPlayer, context: Context) {}
}
