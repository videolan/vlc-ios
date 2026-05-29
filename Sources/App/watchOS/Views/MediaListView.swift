/*****************************************************************************
 * MediaListView.swift
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

struct MediaListView: View {
    @EnvironmentObject var contentViewModel: TracksViewModel
    var medias: [VLCWatchMLMedia]
    var didTapCell: (VLCWatchMLMedia) -> Void

    var body: some View {
        List(medias) { media in
            MediaCellView(thumbnail: media.thumbnail, title: media.title, subtitle: media.artist?.name ?? "")
                .onTapGesture {
                    didTapCell(media)
                }
        }
    }
}

struct MediaCellView: View {
    var thumbnail: URL?
    var title: String
    var subtitle: String

    var body: some View {
        HStack {
            Group {
                if let thumbnailPath = thumbnail?.path(),
                   let uiImage = UIImage(contentsOfFile: thumbnailPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                }
            }
            .frame(width: 42, height: 42)
            .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(title)
                    .lineLimit(1)
                Text(subtitle)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
    }

}

//#Preview {
//    AlbumListView()
//}
