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

protocol VLCWatchMLObject: Identifiable {
    var id: VLCMLIdentifier { get }
}

protocol VLCWatchMLCellItem {
    var thumbnail: URL? { get }
    func placeholderName(for color: ColorScheme) -> String
}

struct MediaListView<Item: VLCWatchMLCellItem & VLCWatchMLObject, Title: View, Subtitle: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let items: [Item]
    @ViewBuilder let titleView: (Item) -> Title
    @ViewBuilder let subtitleView: (Item) -> Subtitle
    let didTapCell: (Item) -> Void

    var body: some View {
        List(items) { item in
            MediaCellView(
                titleView: titleView(item),
                subtitleView: subtitleView(item),
                thumbnail: item.thumbnail,
                placeholderImageName: item.placeholderName(for: colorScheme)
            )
            .onTapGesture {
                didTapCell(item)
            }
        }
    }
}

struct MediaCellView<Title: View, Subtitle: View>: View {
    let titleView: Title
    let subtitleView: Subtitle
    let thumbnail: URL?
    let placeholderImageName: String

    var body: some View {
        HStack {
            AsyncImage(url: thumbnail) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Image(placeholderImageName)
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 0) {
                titleView
                subtitleView
            }
        }
    }
}
