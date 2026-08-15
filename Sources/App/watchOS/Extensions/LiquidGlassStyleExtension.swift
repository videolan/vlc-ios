/*****************************************************************************
 * LiquidGlassStyleExtension.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: David Neacsu <neacsudavid287 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import SwiftUI

extension View {
    /// Applies Liquid Glass with a custom shape (Circle, Capsule, RoundedRectangle, etc.).
    @ViewBuilder
    func liquidGlassStyle<S: Shape>(_ shape: S = Capsule()) -> some View {
        if #available(watchOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}
