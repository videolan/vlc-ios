/*****************************************************************************
 * IntentContext.swift
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

enum IntentContext {
    static var resolver: MediaResolver {
        return MediaResolver(mediaLibraryService: VLCAppCoordinator.sharedInstance().mediaLibraryService)
    }
}

enum IntentStrings {
    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPINTENT_ERROR_NO_MEDIA", comment: ""),
        NSLocalizedString("APPINTENT_ERROR_PLAYLIST_UPDATE", comment: ""),
        NSLocalizedString("APPINTENT_ERROR_PLAYBACK_START", comment: ""),
    ]
}

@available(iOS 16.0, *)
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noMatchingMedia
    case playlistUpdateFailed
    case playbackDidNotStart

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noMatchingMedia:
            return "APPINTENT_ERROR_NO_MEDIA"
        case .playlistUpdateFailed:
            return "APPINTENT_ERROR_PLAYLIST_UPDATE"
        case .playbackDidNotStart:
            return "APPINTENT_ERROR_PLAYBACK_START"
        }
    }
}

// The system only lets an audio intent activate its audio session while perform() is still running.
@available(iOS 16.0, *)
final class PlaybackStartWaiter {
    private static let defaultTimeout: TimeInterval = 15

    private var continuation: CheckedContinuation<Bool, Never>?
    private var observers: [NSObjectProtocol] = []

    @MainActor
    func waitForPlaybackStart(timeout: TimeInterval = PlaybackStartWaiter.defaultTimeout) async -> Bool {
        if PlaybackService.sharedInstance().isPlaying {
            return true
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            let notificationCenter = NotificationCenter.default
            let names = [VLCPlaybackServicePlaybackDidResume,
                         VLCPlaybackServicePlaybackDidFail,
                         VLCPlaybackServicePlaybackDidStop]

            for name in names {
                let observer = notificationCenter.addObserver(forName: Notification.Name(name),
                                                              object: nil,
                                                              queue: .main) { notification in
                    self.finish(notification.name.rawValue == VLCPlaybackServicePlaybackDidResume)
                }
                observers.append(observer)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                self.finish(false)
            }
        }
    }

    private func finish(_ didStart: Bool) {
        guard let continuation = continuation else {
            return
        }

        self.continuation = nil

        let notificationCenter = NotificationCenter.default
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        observers.removeAll()

        continuation.resume(returning: didStart)
    }
}
