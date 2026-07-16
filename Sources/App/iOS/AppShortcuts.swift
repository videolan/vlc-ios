/*****************************************************************************
 * AppShortcuts.swift
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

@available(iOS 16.4, *)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayMediaIntent(),
            phrases: [
                "APPSHORTCUT_PLAY_MEDIA_PHRASE_PLAY_\(.applicationName)",
                "APPSHORTCUT_PLAY_MEDIA_PHRASE_PLAYLIST_\(.applicationName)",
                "APPSHORTCUT_PLAY_MEDIA_PHRASE_START_\(.applicationName)"
            ],
            shortTitle: "APPSHORTCUT_PLAY_MEDIA_SHORT_TITLE",
            systemImageName: "play.circle"
        )
    }

    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_SHORT_TITLE", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_PHRASE_PLAY_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_PHRASE_PLAYLIST_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_PHRASE_START_${applicationName}", comment: ""),
    ]
}
