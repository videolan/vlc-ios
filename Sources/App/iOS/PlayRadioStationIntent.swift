/*****************************************************************************
 * PlayRadioStationIntent.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AppIntents
import Foundation

@available(iOS 16.0, visionOS 1.0, *)
struct PlayRadioStationIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("APPINTENT_PLAY_RADIO_TITLE")
    static var description = IntentDescription(LocalizedStringResource("APPINTENT_PLAY_RADIO_DESCRIPTION"))

    @Parameter(title: LocalizedStringResource("RADIO"))
    var station: RadioStationEntity?

    init() {
    }

    static var parameterSummary: some ParameterSummary {
        Summary("APPINTENT_PLAY_RADIO_PLAY_\(\.$station)")
    }

    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPINTENT_PLAY_RADIO_TITLE", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_RADIO_DESCRIPTION", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_RADIO_PLAY_${station}", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_RADIO_PROMPT", comment: ""),
    ]

    @MainActor
    func perform() async throws -> some IntentResult {
        if let station {
            try await station.play()
            return .result()
        }

        // run without a station, e.g. from the App Shortcut, so ask which one
        let favorites = RadioStationEntity.radioFavorites.map { RadioStationEntity(favorite: $0) }
        guard let first = favorites.first else {
            throw IntentError.noMatchingMedia
        }

        let chosen = favorites.count == 1 ? first
            : try await $station.requestDisambiguation(among: favorites,
                                                       dialog: IntentDialog(LocalizedStringResource("APPINTENT_PLAY_RADIO_PROMPT")))
        try await chosen.play()
        return .result()
    }
}
