/*****************************************************************************
 * VideoIntents.swift
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
import VLCMediaLibraryKit

enum VideoIntentStrings {
    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPINTENT_PLAY_VIDEO_TITLE", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_VIDEO_DESCRIPTION", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_VIDEO_PARAM", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_VIDEO_PLAY_${video}", comment: ""),
    ]
}

@available(iOS 18.4, visionOS 2.4, *)
struct PlayVideoIntent: AppIntent {
    static var title: LocalizedStringResource = "APPINTENT_PLAY_VIDEO_TITLE"
    static var description = IntentDescription("APPINTENT_PLAY_VIDEO_DESCRIPTION")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "APPINTENT_PLAY_VIDEO_PARAM")
    var video: VideoEntity

    static var parameterSummary: some ParameterSummary {
        Summary("APPINTENT_PLAY_VIDEO_PLAY_\(\.$video)")
    }

    func perform() async throws -> some IntentResult {
        guard let media = IntentContext.resolver.video(for: VLCMLIdentifier(video.id)) else {
            throw IntentError.noMatchingMedia
        }

        let playbackService = PlaybackService.sharedInstance()
        await MainActor.run {
            playbackService.fullscreenSessionRequested = true
            playbackService.playCollection([media])
        }

        return .result()
    }
}
