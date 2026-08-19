/*****************************************************************************
 * Image+WidgetAccentedRenderingMode.swift
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Neo Salmon <neos_dev@outlook.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import SwiftUI

extension Image {
    @ViewBuilder
    func fullColorWidgetAccentedRenderingMode() -> some View {
        if #available(iOS 18, *) {
            self
                .widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}
