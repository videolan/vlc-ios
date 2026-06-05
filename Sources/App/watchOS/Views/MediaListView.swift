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

protocol VLCWatchMLCellItem: Identifiable {
    var id: VLCMLIdentifier { get }
    var titleText: String { get }
    var subtitleText: String { get }
    var thumbnail: URL? { get }
}

struct MediaListView<T: VLCWatchMLCellItem> : View {
    @EnvironmentObject var contentViewModel: TracksViewModel
    var items: [T]
    var didTapCell: (T) -> Void

    var body: some View {
        List(items) { item in
            MediaCellView(thumbnail: item.thumbnail, title: item.titleText, subtitle: item.subtitleText)
                .onTapGesture {
                    didTapCell(item)
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
            AsyncImage(url: thumbnail) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 8))

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
