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

    #if targetEnvironment(simulator)
    @StateObject var mlSyncManager: DummyMLSyncManager
    #else
    @StateObject var mlSyncManager: VLCMLSyncManager
    #endif
    @StateObject var artistsViewModel: ArtistsViewModel
    @StateObject var albumsViewModel: AlbumsViewModel
    @StateObject var tracksViewModel: TracksViewModel

    private let appCoordinator = VLCAppCoordinator.sharedInstance()

    let mediaLibraryService: MediaLibraryService

    init() {
        mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService

        #if targetEnvironment(simulator)
        let mlSyncManager = DummyMLSyncManager()
        #else
        let mlSyncManager = VLCMLSyncManager()
        #endif

        let artistsViewModel = ArtistsViewModel(medialibrary: mediaLibraryService)
        let albumsViewModel = AlbumsViewModel(medialibrary: mediaLibraryService)
        let tracksViewModel = TracksViewModel(medialibrary: mediaLibraryService)

        _mlSyncManager = StateObject(wrappedValue: mlSyncManager)
        _artistsViewModel = StateObject(wrappedValue: artistsViewModel)
        _albumsViewModel = StateObject(wrappedValue: albumsViewModel)
        _tracksViewModel = StateObject(wrappedValue: tracksViewModel)

        appDelegate.sessionDelegate.mlSyncManager = mlSyncManager

//        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
//        documentsDir.printAllFiles()
    }

    var body: some Scene {
        WindowGroup {
            VLCWatchContentView(
                mlSyncManager: mlSyncManager,
                artistsViewModel: artistsViewModel,
                albumsViewModel: albumsViewModel,
                tracksViewModel: tracksViewModel
            )
        }
    }
}

// Have to create wrapper to allow protocol @ObservedObject (https://stackoverflow.com/a/59504489)
struct VLCWatchContentView<MLSyncManager>: View where MLSyncManager: ObservableMLSyncManager {
    @ObservedObject var mlSyncManager: MLSyncManager
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var albumsViewModel: AlbumsViewModel
    @ObservedObject var tracksViewModel: TracksViewModel

    var body: some View {
        TabView {
            ArtistView(
                artistsViewModel: artistsViewModel,
                mlSyncState: mlSyncManager.state
            )

            AlbumView(
                albumsViewModel: albumsViewModel,
                mlSyncState: mlSyncManager.state
            )

            TrackView(
                tracksViewModel: tracksViewModel,
                mediaSyncIds: mlSyncManager.state.mediaSyncIds
            )

            // TODO: Radio Discovery tab
        }
        .onReceive(NotificationCenter.default.activationDidCompletePublisher) { notification in
            activationDidComplete(notification)
        }
        .onReceive(NotificationCenter.default.reachabilityDidChangePublisher) { notification in
            reachabilityDidChange(notification)
        }
        .environmentObject(tracksViewModel)
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
