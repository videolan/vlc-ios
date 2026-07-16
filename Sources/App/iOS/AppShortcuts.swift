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

@available(iOS 17.4, *)
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
        if #available(iOS 18.4, visionOS 2.4, *) {
            AppShortcut(
                intent: PlayVideoIntent(),
                phrases: [
                    "APPSHORTCUT_PLAY_VIDEO_PHRASE_PLAY_\(.applicationName)",
                    "APPSHORTCUT_PLAY_VIDEO_PHRASE_WATCH_\(.applicationName)"
                ],
                shortTitle: "APPSHORTCUT_PLAY_VIDEO_SHORT_TITLE",
                systemImageName: "film"
            )
        }
        // iOS 27 SDK
#if canImport(MediaIntents)
        if #available(iOS 27, *) {
            AppShortcut(
                intent: PlayAudioIntent(),
                phrases: [
                    "APPSHORTCUT_PLAY_AUDIO_PHRASE_PLAY_\(.applicationName)",
                    "APPSHORTCUT_PLAY_AUDIO_PHRASE_SONG_\(.applicationName)"
                ],
                shortTitle: "APPSHORTCUT_PLAY_AUDIO_SHORT_TITLE",
                systemImageName: "music.note"
            )
        }
        if #available(iOS 27, *) {
            AppShortcut(
                intent: AddAudioToPlaylistIntent(),
                phrases: [
                    "APPSHORTCUT_ADD_TO_PLAYLIST_PHRASE_\(.applicationName)"
                ],
                shortTitle: "APPSHORTCUT_ADD_TO_PLAYLIST_SHORT_TITLE",
                systemImageName: "text.badge.plus"
            )
        }
        if #available(iOS 27, *) {
            AppShortcut(
                intent: UpdateAudioAffinityIntent(),
                phrases: [
                    "APPSHORTCUT_UPDATE_AFFINITY_PHRASE_\(.applicationName)"
                ],
                shortTitle: "APPSHORTCUT_UPDATE_AFFINITY_SHORT_TITLE",
                systemImageName: "heart"
            )
        }
#endif
    }

    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_SHORT_TITLE", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_PHRASE_PLAY_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_PHRASE_PLAYLIST_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_MEDIA_PHRASE_START_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_AUDIO_SHORT_TITLE", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_AUDIO_PHRASE_PLAY_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_AUDIO_PHRASE_SONG_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_VIDEO_SHORT_TITLE", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_VIDEO_PHRASE_PLAY_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_PLAY_VIDEO_PHRASE_WATCH_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_ADD_TO_PLAYLIST_SHORT_TITLE", comment: ""),
        NSLocalizedString("APPSHORTCUT_ADD_TO_PLAYLIST_PHRASE_${applicationName}", comment: ""),
        NSLocalizedString("APPSHORTCUT_UPDATE_AFFINITY_SHORT_TITLE", comment: ""),
        NSLocalizedString("APPSHORTCUT_UPDATE_AFFINITY_PHRASE_${applicationName}", comment: ""),
    ]
}
