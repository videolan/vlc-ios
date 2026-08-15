/*****************************************************************************
 * MainScreenTileView.swift
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
import WatchKit

struct MainScreenTileView: View {
    let iconName: String
    let tileColor: Color
    let tileText: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.title2)
                .frame(width: 28, height: 28)
            
            Text(tileText)
                .font(.headline)
        }
        .foregroundStyle(tileColor == .mainTileBackground || tileColor == .tileAccent ? .white : .mainTileForeground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tileColor.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
        .liquidGlassStyle(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MainScreenTileView(iconName: "music.pages.fill", tileColor: .mediumTileBackground, tileText: "Albums")
}
