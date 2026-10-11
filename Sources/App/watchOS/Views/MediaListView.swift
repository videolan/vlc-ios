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

protocol VLCWatchMLCellItem {
    var placeholderName: String { get }
}

struct MediaCellView<Title: View, Subtitle: View>: View {
    let titleView: Title
    let subtitleView: Subtitle
    let thumbnail: URL?
    let placeholderName: String

    private let artworkSide: CGFloat = 42

    var body: some View {
        HStack {
            AsyncImage(url: thumbnail) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ZStack {
                    Color(uiColor: VLCPlaceholderArtwork.backgroundColor(forName: placeholderName))
                    Text(VLCPlaceholderArtwork.initials(forName: placeholderName))
                        .font(.system(size: VLCPlaceholderArtwork.fontSize(forSide: artworkSide), weight: .heavy))
                        .foregroundStyle(Color(uiColor: VLCPlaceholderArtwork.foregroundColor(forName: placeholderName)))
                }
            }
            .frame(width: artworkSide, height: artworkSide)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 0) {
                titleView
                subtitleView
            }
        }
    }
}
