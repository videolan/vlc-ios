/*****************************************************************************
 * ProgressBarView.swift
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
import VLCKit

struct ProgressBarView: View {
    var currentTime: VLCTime
    var totalTime: VLCTime

    var isPlaying: Bool
    var text: String
    
    var progress: Double {
        guard Double(totalTime.intValue) > 0 else { return 0 }
        return min(max(Double(currentTime.intValue) / Double(totalTime.intValue), 0), 1)
    }

    var body: some View {
        VStack {
            HStack {
                Text(currentTime.stringValue)
                    .font(.footnote)
                    .foregroundStyle(isPlaying ? Color.primary : Color.secondary)

                Spacer()

                Text(text)
                    .font(.footnote)
                    .foregroundStyle(isPlaying ? Color.primary : Color.secondary)
                    .lineLimit(1)

                Spacer()

                Text(totalTime.stringValue)
                    .font(.footnote)
                    .foregroundStyle(isPlaying ? Color.primary : Color.secondary)

            }
            .animation(.easeInOut, value: isPlaying)

            ProgressView(value: progress)
                .frame(height: 5)
                .foregroundStyle(isPlaying ? Color.primary : Color.secondary)
                .animation(.easeInOut, value: isPlaying)

        }
    }
}
