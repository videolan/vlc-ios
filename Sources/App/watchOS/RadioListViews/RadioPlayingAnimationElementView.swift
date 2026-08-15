/*****************************************************************************
 * RadioPlayingAnimationElementView.swift
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

struct RadioPlayingAnimationElementView: View {
    var lowerLimit: CGFloat
    var higherLimit: CGFloat

    var isPlaying: Bool

    @State private var lineSize: CGFloat = 20
    
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        Capsule()
            .fill(isLuminanceReduced ? .gray : .white)
            .opacity(1.0)
            .frame(width: lineSize, height: 3)
            .task(id: isPlaying) {
                guard isPlaying else { return }
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        lineSize = CGFloat.random(in: lowerLimit...higherLimit)
                    }
                    try? await Task.sleep(for: .seconds(0.25))
                }
            }
    }
}

#Preview {
    RadioPlayingAnimationElementView(lowerLimit: 10, higherLimit: 30, isPlaying: true)
}
