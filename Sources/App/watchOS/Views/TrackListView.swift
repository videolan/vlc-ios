/*****************************************************************************
 * TrackListView.swift
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

struct TrackListView: View {
    let snapshotMedias: [VLCWatchMLMedia]
    var mediaSyncIds: [MLSyncID]
    var showTrackNumber: Bool = false
    var didTapMedia: (VLCWatchMLMedia) -> Void

    var body: some View {
        List(snapshotMedias) { media in
            TrackCellView(
                media: media,
                thumbnail: media.thumbnail,
                showTrackNumber: showTrackNumber,
                isDownloaded: media.isDownloaded(mediaSyncIds)
            )
            .onTapGesture {
                didTapMedia(media)
            }
        }
    }

}
