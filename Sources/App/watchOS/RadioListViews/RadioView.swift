/*****************************************************************************
 * RadioView.swift
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

struct RadioView: View {
    
    @StateObject var radioController = RadioController.shared
    @StateObject var playerController = ControlPlayerViewController.shared
    
    var body: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                NavigationLink {
                    RadioListView(displayStations: false, displayRecents: true, displayFavorites: false)
                } label: {
                    MainScreenTileView(
                        iconName: "music.note.square.stack.fill",
                        tileColor: .mainTileBackground,
                        tileText: NSLocalizedString("RECENTS", comment: "")
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    RadioListView(displayStations: false, displayRecents: false, displayFavorites: true)
                } label: {
                    MainScreenTileView(
                        iconName: "star.fill",
                        tileColor: .lightTileBackground,
                        tileText: NSLocalizedString("FAVORITES", comment: "")
                    )
                }
                .buttonStyle(.plain)
            }
            
            NavigationLink {
                RadioListView(displayStations: false, displayRecents: false, displayFavorites: false)
            } label: {
                MainScreenTileView(
                    iconName: "dot.radiowaves.left.and.right",
                    tileColor: .tileAccent,
                    tileText: NSLocalizedString("DISCOVER_LABEL", comment: "")
                )
                .simultaneousGesture(TapGesture().onEnded({ _ in
                    radioController.enableDiscovery()
                }))
            }
            .buttonStyle(.plain)
        }
        .onDisappear {
            radioController.stopDiscovery()
        }
        .navigationTitle(NSLocalizedString("RADIO", comment: ""))
    }
}

#Preview {
    RadioView()
}
