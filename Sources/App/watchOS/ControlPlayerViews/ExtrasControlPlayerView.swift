/*****************************************************************************
 * ExtrasControlPlayerView.swift
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

struct ExtrasControlPlayerView: View {
    
    @StateObject var playerController = ControlPlayerViewController.shared
    @StateObject var radioController = RadioController.shared
    
    var body: some View {
        ScrollView {
            VStack {
                if let station = playerController.nowPlayingRadioStation {
                    Button {
                        radioController.toggleFavorites(station)
                    } label: {
                        HStack {
                            Text(NSLocalizedString("FAVORITES", comment: ""))
                                .font(.headline)
                            Spacer()
                            Text(radioController.isFavorite(station) ?
                                 NSLocalizedString("ON", comment: "") :
                                    NSLocalizedString("OFF", comment: "")
                            )
                                .font(.headline)
                        }
                    }
                    .liquidGlassStyle(Capsule())
                }
                
                Button {
                    playerController.changeRepeatMode()
                } label: {
                    HStack {
                        Text(NSLocalizedString("REPEAT_MODE", comment: ""))
                            .font(.headline)
                        Spacer()
                        Text(playerController.repeatMode.getName())
                            .font(.headline)
                    }
                }
                .liquidGlassStyle(Capsule())
                
                Button {
                    playerController.toggleShuffle()
                } label: {
                    HStack {
                        Text(NSLocalizedString("SHUFFLE", comment: ""))
                            .font(.headline)
                        Spacer()
                        Text(playerController.shuffle ?
                             NSLocalizedString("ON", comment: "") :
                                NSLocalizedString("OFF", comment: "")
                        )
                        .font(.headline)
                    }
                }
                .liquidGlassStyle(Capsule())
                
                Divider()
                
                ForEach(Array(playerController.nextInQueue.enumerated()), id: \.offset) { index, media in
                    Button {
                        playerController.skipTrack(index)
                    } label: {
                        QueueSongView(imageURL: media.thumbnail(), title: media.title)
                    }
                    .controlRowStyle()
                }
            }
            .padding(.horizontal)
        }
        .containerBackground(for: .navigation) {
            if let url = playerController.nowPlayingArtworkURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Color.black }
                    .scaleEffect(0.92).clipped().blur(radius: 10).ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }
}

struct QueueSongView: View {
    let imageURL: URL?
    let title: String
    
    var body: some View {
        HStack {
            if let artworkURL = imageURL {
                AsyncImage(url: artworkURL) { Image in
                    Image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Image(systemName: "music.note")
                    .font(.title)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Text(title)
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
                .truncationMode(.tail)
                .lineLimit(2)
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ExtrasControlPlayerView()
}
