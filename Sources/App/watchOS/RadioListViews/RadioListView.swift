/*****************************************************************************
 * RadioListView.swift
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

struct RadioListView: View {

    @StateObject var playerController = ControlPlayerViewController.shared
    @StateObject var radioController = RadioController.shared
    
    let displayStations: Bool
    let displayRecents: Bool
    let displayFavorites: Bool

    var body: some View {
        ZStack {
            if displayRecents {
                ForEach(radioController.recents) { station in
                    NavigationLink {
                        ControlPlayerView()
                    } label: {
                        RadioListElementView(station: station, isPlaying: false, isFavorite: radioController.isFavorite(station))
                    }
                    .simultaneousGesture(TapGesture().onEnded({ _ in
                        playerController.playStation(station: station)
                        radioController.addStationToRecents(station)
                    }))
                }
            } else if displayFavorites {
                ForEach(radioController.recents) { station in
                    NavigationLink {
                        ControlPlayerView()
                    } label: {
                        RadioListElementView(station: station, isPlaying: false, isFavorite: true)
                    }
                    .simultaneousGesture(TapGesture().onEnded({ _ in
                        playerController.playStation(station: station)
                        radioController.addStationToRecents(station)
                    }))
                }
            } else {
                if displayStations {
                    ForEach(radioController.stations) { station in
                        NavigationLink {
                            ControlPlayerView()
                        } label: {
                            RadioListElementView(station: station, isPlaying: false, isFavorite: radioController.isFavorite(station))
                        }
                        .simultaneousGesture(TapGesture().onEnded({ _ in
                            playerController.playStation(station: station)
                        }))
                    }
                } else {
                    ForEach(radioController.countries) { country in
                        NavigationLink {
                            RadioListView(displayStations: true, displayRecents: false, displayFavorites: false)
                        } label: {
                            RadioListElementView(station: country, isPlaying: false)
                        }
                        .simultaneousGesture(TapGesture().onEnded({ _ in
                            radioController.loadCountryStations(country: country)
                        }))
                    }
                }
            }
        }
        .blur(radius: radioController.hasError ? 10 : 0)
        .disabled(radioController.hasError)
        .overlay {
            if radioController.hasError {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)

                    Text(radioController.errorMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding(.all, 16)
            }
        }
        .onDisappear {
            if displayStations {
                radioController.leaveCountryStations()
            }
            radioController.dismissError()
        }
        .navigationTitle(
            displayRecents ?
            NSLocalizedString("RECENT_STREAMS", comment: "") :
            (displayFavorites ? NSLocalizedString("FAVORITES", comment: "") :
            NSLocalizedString("DISCOVER_LABEL", comment: ""))
        )
    }
}

#Preview {
    NavigationStack {
        RadioListView(displayStations: false, displayRecents: false, displayFavorites: false)
    }
}
