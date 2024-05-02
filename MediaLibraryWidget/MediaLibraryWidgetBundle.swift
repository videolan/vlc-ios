/*****************************************************************************
 * MediaLibraryWidgetBundle.swift
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import WidgetKit
import SwiftUI

@main
struct MediaLibraryWidgetBundle: WidgetBundle {
    var body: some Widget {
        MediaLibraryWidget()
    }
}
