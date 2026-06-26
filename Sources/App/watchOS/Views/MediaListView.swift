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
    func placeholderName(for color: ColorScheme) -> String
}

struct MediaListView<T: VLCWatchMLCellItem, Subtitle: View> : View {
    @Environment(\.colorScheme) var colorScheme
    var items: [T]
    @ViewBuilder var subtitle: (T) -> Subtitle
    var didTapCell: (T) -> Void

    var body: some View {
        List(items) { item in
            MediaCellView(title: item.titleText,
                          thumbnail: item.thumbnail,
                          placeholderImageName: item.placeholderName(for: colorScheme)) {
                subtitle(item)
            }
            .onTapGesture {
                didTapCell(item)
            }
        }
    }
}

struct MediaCellView<Subtitle: View>: View {
    var title: String
    var thumbnail: URL?
    var placeholderImageName: String
    @ViewBuilder var subtitle: () -> Subtitle

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
                Text(title)
                    .lineLimit(1)
                subtitle()
            }
        }
    }
}
