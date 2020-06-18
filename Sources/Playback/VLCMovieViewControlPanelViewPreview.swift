/*****************************************************************************
 * VLCMovieViewControlPanelViewPreview.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Andrew <asbreckenridge # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#if canImport(SwiftUI)
import SwiftUI
import UIKit

@available(iOS 13, *)
struct WrappedVLCMovieViewControlPanelView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = VLCMovieViewControlPanelView()

        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }
}

@available(iOS 13, *)
struct VLCMovieViewControlPanelView_Preview: PreviewProvider {
    static var previews: some View {
        WrappedVLCMovieViewControlPanelView()
    }
}

#endif
