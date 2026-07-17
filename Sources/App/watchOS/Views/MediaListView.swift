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
    func placeholderName(for color: ColorScheme) -> String
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
