/*****************************************************************************
 * ArtistView.swift
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

struct ArtistView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var tracksViewModel: TracksViewModel

    var body: some View {
        NavigationStack(path: $artistsViewModel.path) {
            ArtistListView(snapshotArtists: artistsViewModel.snapshotArtists) { artist in
                artistsViewModel.path.append(artist)
            }
            .navigationTitle("Artists")
            .onAppear {
                guard artistsViewModel.isFirstLoad else { return }
                artistsViewModel.loadArtists()
            }
            .navigationDestination(for: VLCWatchMLArtist.self) { artist in
                Group {
                    if artist.albumsCount == 0 {
                        TrackListView(snapshotMedias: artist.tracks,
                                      downloadedMediaIDs: tracksViewModel.downloadedMediaIDs,
                                      mediaSyncIds: tracksViewModel.mediaSyncIds) { track in
                            tracksViewModel.play(media: track)
                        }
                    } else {
                        ArtistDetailListView(
                            snapshotAlbums: artist.albums,
                            snapshotMedias: artist.tracks,
                            downloadedMediaIDs: tracksViewModel.downloadedMediaIDs,
                            mediaSyncIds: tracksViewModel.mediaSyncIds,
                            didTapAlbum: { album in
                                artistsViewModel.path.append(album)
                            },
                            didTapMedia: { media in
                                tracksViewModel.play(media: media)
                            }
                        )
                    }
                }
                .navigationTitle(artist.name)
            }
            .navigationDestination(for: VLCWatchMLAlbum.self) { album in
                let medias = album.tracks.map { VLCWatchMLMedia($0) }
                TrackListView(snapshotMedias: medias,
                              downloadedMediaIDs: tracksViewModel.downloadedMediaIDs,
                              mediaSyncIds: tracksViewModel.mediaSyncIds,
                              showTrackNumber: true
                ) { track in
                    tracksViewModel.play(media: track)
                }
                .navigationTitle(album.title)
            }
        }
    }
}
