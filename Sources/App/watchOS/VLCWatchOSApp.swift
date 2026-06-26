/*****************************************************************************
 * VLCWatchOSApp.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import SwiftUI
import Combine
import WatchConnectivity

@main
struct VLCWatchOSApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: VLCWatchAppDelegate
//    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    @StateObject var artistsViewModel: ArtistsViewModel
    @StateObject var albumsViewModel: AlbumsViewModel
    @StateObject var tracksViewModel: TracksViewModel
    @State private var selection: Command = .updateAppContext

    private let appCoordinator = VLCAppCoordinator.sharedInstance()

    // For testing WatchConnectivity APIs
    let commands: [Command] = [.updateAppContext, .sendMessage, .sendMessageData,
                               .transferFile, .transferUserInfo,
                               .transferCurrentComplicationUserInfo]

    let mediaLibraryService: MediaLibraryService
    let snapshotMediaLibraryService: MediaLibraryService
    let playbackService: PlaybackService

    init() {
        mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
        snapshotMediaLibraryService = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService
        playbackService = PlaybackService.sharedInstance()
        let artistsViewModel = ArtistsViewModel(medialibrary: mediaLibraryService, snapshotMediaLibrary: snapshotMediaLibraryService)
        let albumsViewModel = AlbumsViewModel(medialibrary: mediaLibraryService, snapshotMediaLibrary: snapshotMediaLibraryService)
        let tracksViewModel = TracksViewModel(medialibrary: mediaLibraryService, snapshotMediaLibrary: snapshotMediaLibraryService)

        _artistsViewModel = StateObject(wrappedValue: artistsViewModel)
        _albumsViewModel = StateObject(wrappedValue: albumsViewModel)
        _tracksViewModel = StateObject(wrappedValue: tracksViewModel)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selection) {

                NavigationStack {
                    MediaListView(items: artistsViewModel.snapshotArtists) { artist in
                        Text(artist.subtitleText)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } didTapCell: { artist in
                        print("tap artist: \(artist)")
                    }
                    .navigationTitle("Artists")
                    .onAppear {
                        guard artistsViewModel.isFirstLoad else { return }
                        artistsViewModel.loadArtists()
                    }
                }

                NavigationStack(path: $albumsViewModel.path) {
                    MediaListView(items: albumsViewModel.snapshotAlbums) { album in
                        Text(album.subtitleText)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } didTapCell: { album in
                        albumsViewModel.path.append(album)
                    }
                    .navigationTitle("Albums")
                    .onAppear {
                        guard albumsViewModel.isFirstLoad else { return }
                        albumsViewModel.loadAlbums()
                    }
                    .navigationDestination(for: VLCWatchMLAlbum.self) { album in
                        let medias = album.tracks.map {
                            var media = VLCWatchMLMedia($0)
                            media.showTrackNumber = true
                            return media
                        }
                        MediaListView(items: medias) { media in
                            HStack(spacing: 2) {
                                if !isDownloaded(iphoneMediaId: media.id, syncIds: tracksViewModel.mediaSyncIds, downloadedItemIds: tracksViewModel.downloadedMediaIDs) {
                                    Image("Downloads")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                                Text(media.subtitleText)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        } didTapCell: { media in
                            tracksViewModel.play(media: media)
                        }
                        .navigationTitle(album.title)
                    }
                }

                NavigationStack {
                    MediaListView(items: tracksViewModel.snapshotMedias) { media in
                        HStack(spacing: 2) {
                            if !isDownloaded(iphoneMediaId: media.id, syncIds: tracksViewModel.mediaSyncIds, downloadedItemIds: tracksViewModel.downloadedMediaIDs) {
                                Image("Downloads")
                                    .renderingMode(.original)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            Text(media.subtitleText)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } didTapCell: { media in
                        tracksViewModel.play(media: media)
                    }
                    .navigationTitle("Songs")
                    .onAppear {
                        guard tracksViewModel.isFirstLoad else { return }
                        tracksViewModel.loadTracks()
                    }
                }

                // TODO: Radio Discovery tab

                // For testing WatchConnectivity APIs
                //                ForEach(commands, id: \.self) { command in
                //                    CommandView(command: command, selectedTab: $selection).tag(command)
                //                }
            }
            .onReceive(NotificationCenter.default.activationDidCompletePublisher) { notification in
                activationDidComplete(notification)
            }
            .onReceive(NotificationCenter.default.reachabilityDidChangePublisher) { notification in
                reachabilityDidChange(notification)
            }
            .environmentObject(tracksViewModel)
        }
    }

    /**
     Observe the activation state change and log the current state.
     */
    private func activationDidComplete(_ notification: Notification) {
        print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    /**
     Observe the reachability state change and log the current state.
     */
    private func reachabilityDidChange(_ notification: Notification) {
        print("\(#function): isReachable:\(WCSession.default.isReachable)")
    }

    private func isDownloaded(iphoneMediaId: VLCMLIdentifier, syncIds: [MediaSyncID], downloadedItemIds: Set<VLCMLIdentifier>) -> Bool {
        guard let watchMediaId = syncIds.first(where: { $0.iphoneMediaId == iphoneMediaId })?.watchMediaId else { return false }
        return downloadedItemIds.contains(watchMediaId)
    }
}


extension NotificationCenter {
    var activationDidCompletePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .activationDidComplete).receive(on: .main)
    }
    var reachabilityDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .reachabilityDidChange).receive(on: .main)
    }
}
