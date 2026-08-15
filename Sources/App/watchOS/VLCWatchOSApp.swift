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
import WatchKit

final class WatchNavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
}

enum WatchRoute: Hashable {
    case tracks
    case artists
    case albums
    case radio
    case nowPlaying
}

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
    @StateObject var router = WatchNavigationRouter()

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
            .environmentObject(router)
        }
    }
}

// Have to create wrapper to allow protocol @ObservedObject (https://stackoverflow.com/a/59504489)
struct VLCWatchContentView<MLSyncManager>: View where MLSyncManager: ObservableMLSyncManager {
    @ObservedObject var mlSyncManager: MLSyncManager
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var albumsViewModel: AlbumsViewModel
    @ObservedObject var tracksViewModel: TracksViewModel
    
    @StateObject var playerController = ControlPlayerViewController.shared
    @EnvironmentObject var router: WatchNavigationRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                GridRow {
                    NavigationLink(value: WatchRoute.tracks) {
                        MainScreenTileView(
                            iconName: "music.note.square.stack.fill",
                            tileColor: .mainTileBackground,
                            tileText: NSLocalizedString("TRACKS_WO_COUNTER", comment: "")
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(value: WatchRoute.artists) {
                        MainScreenTileView(
                            iconName: "music.note.list",
                            tileColor: .lightTileBackground,
                            tileText: NSLocalizedString("ARTISTS", comment: "")
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                GridRow {
                    NavigationLink(value: WatchRoute.albums) {
                        MainScreenTileView(
                            iconName: "music.pages.fill",
                            tileColor: .mediumTileBackground,
                            tileText: NSLocalizedString("ALBUMS", comment: "")
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(value: WatchRoute.radio) {
                        MainScreenTileView(
                            iconName: "dot.radiowaves.left.and.right",
                            tileColor: .tileAccent,
                            tileText: NSLocalizedString("RADIO", comment: "")
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 4)
            .navigationDestination(for: WatchRoute.self) { route in
                switch route {
                case .tracks:
                    TrackView(
                        tracksViewModel: tracksViewModel,
                        mediaSyncIds: mlSyncManager.state.mediaSyncIds
                    )
                case .artists:
                    ArtistView(
                        artistsViewModel: artistsViewModel,
                        mlSyncState: mlSyncManager.state
                    )
                case .albums:
                    AlbumView(
                        albumsViewModel: albumsViewModel,
                        mlSyncState: mlSyncManager.state
                    )
                case .radio:
                    RadioView()
                case .nowPlaying:
                    ControlPlayerView()
                }
            }
            .padding(.horizontal)
            .navigationDestination(for: VLCWatchMLArtist.self) { artist in
                ArtistDetailView(
                    artist: artist,
                    mlSyncState: mlSyncManager.state,
                    didTapAlbum: { album in router.path.append(album) }
                )
            }
            .navigationDestination(for: VLCWatchMLAlbum.self) { album in
                AlbumDetailView(
                    album: album,
                    mlSyncState: mlSyncManager.state
                )
            }
            .navigationDestination(for: VLCWatchMLMedia.self) { _ in
                ControlPlayerView()
            }
            .toolbar {
                if playerController.isMedia {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            router.path.append(WatchRoute.nowPlaying)
                        } label: {
                            RadioPlayingAnimationView(isPlaying: playerController.isPlaying)
                                .scaleEffect(0.6)
                        }
                    }
                    
                }
            }
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
