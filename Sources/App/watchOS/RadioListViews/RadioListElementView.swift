/*****************************************************************************
 * RadioListElementView.swift
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

struct RadioListElementView: View {
    @State var station: RadioStation
    @State var isPlaying: Bool
    @State var isFavorite: Bool = false
    
    var body: some View {
        HStack {
            if let artworkURL = station.imageURL {
                AsyncImage(url: artworkURL) { Image in
                    Image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .blur(radius: isPlaying ? 4 : 0)
                        .overlay {
                            if isPlaying {
                                ZStack {
                                    RadioPlayingAnimationView(isPlaying: isPlaying)
                                }
                                .padding()
                            }
                        }
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .blur(radius: isPlaying ? 4 : 0)
                        .overlay {
                            if isPlaying {
                                ZStack {
                                    RadioPlayingAnimationView(isPlaying: isPlaying)
                                }
                                .padding()
                            }
                        }
                }
            } else {
                Image(systemName: "music.note")
                    .font(.title)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .blur(radius: isPlaying ? 4 : 0)
                    .overlay {
                        if isPlaying {
                            ZStack {
                                RadioPlayingAnimationView(isPlaying: isPlaying)
                            }
                            .padding()
                        }
                    }
            }
            
            Text(station.title)
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
                .truncationMode(.tail)
                .lineLimit(2)
            
            Spacer()
            
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
