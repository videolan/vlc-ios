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
    ]
}

@available(iOS 16.0, *)
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noMatchingMedia
    case playlistUpdateFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noMatchingMedia:
            return "APPINTENT_ERROR_NO_MEDIA"
        case .playlistUpdateFailed:
            return "APPINTENT_ERROR_PLAYLIST_UPDATE"
        }
    }
}
