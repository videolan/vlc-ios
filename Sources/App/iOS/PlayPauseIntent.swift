/*****************************************************************************
 * PlayPauseIntent.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AppIntents
import Foundation

@available(iOS 17.0, *)
struct PlayPauseIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "APPINTENT_PLAY_PAUSE_TITLE"
    static var description = IntentDescription("APPINTENT_PLAY_PAUSE_DESCRIPTION")
    static var openAppWhenRun: Bool = false

    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPINTENT_PLAY_PAUSE_TITLE", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_PAUSE_DESCRIPTION", comment: ""),
    ]

    @MainActor
    func perform() async throws -> some IntentResult {
        let playbackService = PlaybackService.sharedInstance()

        if playbackService.isPlaying {
            playbackService.pause()
            return .result()
        }

        if !playbackService.playerIsSetup {
            guard await restoreLastPlayedMediaList() else {
                throw IntentError.nothingToResume
            }
        }

        let waiter = PlaybackStartWaiter()
        playbackService.play()

        guard await waiter.waitForPlaybackStart() else {
            APLog("PlayPauseIntent: playback did not resume")
            throw IntentError.playbackDidNotStart
        }

        return .result()
    }

    @MainActor
    private func restoreLastPlayedMediaList() async -> Bool {
        guard !KeychainCoordinator.passcodeService.hasSecret else {
            return false
        }

        PlaybackService.sharedInstance().fullscreenSessionRequested = false

        let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
        return await withCheckedContinuation { continuation in
            mediaLibraryService.restoreLastPlayedMediaList(onDemand: false,
                                                           openInMiniPlayer: true) { restored in
                continuation.resume(returning: restored)
            }
        }
    }
}
