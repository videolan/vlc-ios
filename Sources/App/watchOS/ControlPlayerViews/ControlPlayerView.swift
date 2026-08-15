/*****************************************************************************
 * ControlPlayerView.swift
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

struct ControlPlayerView: View {
    @State private var marqueeOffset: CGFloat = 0

    @StateObject var playerController = ControlPlayerViewController.shared
    let playerInstance = PlaybackService.sharedInstance()

    private var title: String { playerController.nowPlayingTitle}
    private var titleWidth: CGFloat {
        (title as NSString).size(withAttributes: [.font: UIFont.preferredFont(forTextStyle: .headline)]).width
    }
    private var titleHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .headline).lineHeight
    }

    var body: some View {
        ZStack {
            
            VStack {
                GeometryReader { geo in
                    let availableWidth = geo.size.width
                    let shouldAnimate = titleWidth > availableWidth
                    
                    ZStack(alignment: .center) {
                        if shouldAnimate {
                            HStack(spacing: 48) {
                                Text(title).font(.headline).fixedSize()
                                Text(title).font(.headline).fixedSize()
                            }
                            .offset(x: -marqueeOffset)
                            .frame(width: availableWidth, alignment: .leading)
                        } else {
                            Text(title)
                                .font(.headline)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .frame(width: availableWidth, height: titleHeight)
                    .clipped()
                }
                .frame(height: titleHeight)
                .padding(.bottom)
                .task(id: title) {
                    marqueeOffset = 0
                    let band = titleWidth + 48
                    while !Task.isCancelled {
                        while marqueeOffset < band {
                            try? await Task.sleep(nanoseconds: 33_000_000) // 33ms
                            if Task.isCancelled { return }
                            marqueeOffset += 1
                        }
                        marqueeOffset = 0
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                        if Task.isCancelled { return }
                    }
                }
                
                ProgressBarView(
                    currentTime: playerInstance.playedTime(),
                    totalTime: playerInstance.mediaLength,
                    isPlaying: playerController.isPlaying,
                    text: ""
                )
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            
            VStack {
                Spacer()
                HStack {
                    if playerInstance.isNextMediaAvailable {
                        Button(action: {
                            playerController.playPrevious()
                        }) {
                            Image(systemName: "backward.end.fill")
                                .frame(width: 32, height: 32)
                                .padding(.all, 2)
                        }
                        .buttonStyle(.plain)
                        .liquidGlassStyle()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        playerController.pauseResumeToggle()
                    }) {
                        Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
                            .frame(width: 32, height: 32)
                            .id(playerController.isPlaying)
                            .transition(.opacity)
                            .padding(.all, 2)
                    }
                    .buttonStyle(.plain)
                    .liquidGlassStyle()
                    
                    Spacer()
                    
                    Button(action: {
                        playerController.playNext()
                    }) {
                        Image(systemName: "forward.end.fill")
                            .frame(width: 32, height: 32)
                            .padding(.all, 2)
                    }
                    .buttonStyle(.plain)
                    .liquidGlassStyle()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea()
        .toolbar() {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ExtrasControlPlayerView()
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .background {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if let url = playerController.nowPlayingArtworkURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.black
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .scaleEffect(0.92)
                    .clipped()
                    .blur(radius: 10)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
        }
        .blur(radius: playerController.hasError ? 10 : 0)
        .disabled(playerController.hasError)
        .overlay {
            if playerController.hasError {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)

                    Text(playerController.errorMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding(.all, 16)
            }
        }
        .onDisappear {
            playerController.dismissError()
        }
    }
}
