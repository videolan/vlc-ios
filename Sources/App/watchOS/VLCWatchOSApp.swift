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

//        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
//        documentsDir.printAllFiles()
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selection) {
                ArtistView(artistsViewModel: artistsViewModel, tracksViewModel: tracksViewModel)
                AlbumView(albumsViewModel: albumsViewModel, tracksViewModel: tracksViewModel)
                TrackView(tracksViewModel: tracksViewModel)

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
}


extension NotificationCenter {
    var activationDidCompletePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .activationDidComplete).receive(on: .main)
    }
    var reachabilityDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .reachabilityDidChange).receive(on: .main)
    }
}
