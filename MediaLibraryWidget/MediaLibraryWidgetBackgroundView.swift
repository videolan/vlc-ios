/*****************************************************************************
 * MediaLibraryWidgetBackgroundView.swift
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Neo Salmon <neos_dev@outlook.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import SwiftUI

struct MediaLibraryWidgetBackgroundView: View {
    private let entry: SimpleEntry
    
    init(entry: SimpleEntry) {
        self.entry = entry
    }
    
    var body: some View {
        ZStack {
            if #available(iOS 26, *) {
                ZStack {
                    Image(uiImage: albumArtImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                }
            } else {
                entry.backgroundColor()
            }
            
            Rectangle()
                .foregroundStyle(.black)
                .opacity(0.4)
        }
    }
    
    private var albumArtImage: UIImage {
        guard let decodedData = entry.decodedData else { return UIImage(named: "vlc")! }
        
        if let imageData = Data(base64Encoded: decodedData.imageData, options: .ignoreUnknownCharacters), let uiImage = UIImage(data: imageData) {
            return uiImage
        } else {
            return UIImage(named: "vlc")!
        }
    }
}
