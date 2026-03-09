/*****************************************************************************
 * AppIntent.swift
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")


    @Parameter(title: "Displayed title", default: "Last played")
    var configurableTitle: String
}
