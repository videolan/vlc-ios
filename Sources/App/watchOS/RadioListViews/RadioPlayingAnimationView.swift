/*****************************************************************************
 * RadioPlayingAnimationView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: David Neacsu <neacsudavid287 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import SwiftUI

struct RadioPlayingAnimationView: View {

    var isPlaying: Bool

    var body: some View {
        VStack(spacing: 3) {
            RadioPlayingAnimationElementView(lowerLimit: 5, higherLimit: 20, isPlaying: isPlaying)
            
            RadioPlayingAnimationElementView(lowerLimit: 15, higherLimit: 25, isPlaying: isPlaying)
            
            RadioPlayingAnimationElementView(lowerLimit: 15, higherLimit: 30, isPlaying: isPlaying)
            
            RadioPlayingAnimationElementView(lowerLimit: 10, higherLimit: 20, isPlaying: isPlaying)
            
            RadioPlayingAnimationElementView(lowerLimit: 5, higherLimit: 15, isPlaying: isPlaying)
        }
        .rotationEffect(Angle(degrees: 90))
        .frame(width: 20, height: 30)
    }
}

#Preview {
    RadioPlayingAnimationView(isPlaying: true)
        .scaleEffect(0.5)
}
