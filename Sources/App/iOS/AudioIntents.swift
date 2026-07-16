/*****************************************************************************
 * AudioIntents.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// iOS 27 SDK
#if canImport(MediaIntents)

import AppIntents
import Foundation
import VLCMediaLibraryKit

@available(iOS 27, *)
enum AudioIntentStrings {
    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPINTENT_AFFINITY_FAVORITE", comment: ""),
        NSLocalizedString("APPINTENT_AFFINITY_NOT_FAVORITE", comment: ""),
        NSLocalizedString("APPINTENT_AFFINITY_UNSET", comment: ""),
    ]
}

@available(iOS 27, *)
@AppEnum(schema: .audio.playbackAttributes)
enum PlaybackAttributes: String {
    case shuffle
    case `repeat`

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .shuffle: "SHUFFLE",
        .repeat: "REPEAT_MODE"
    ]
}

@available(iOS 27, *)
@AppEnum(schema: .audio.queueInsertionLocation)
enum QueueInsertionLocation: String {
    case next
    case tail

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .next: "PLAY_NEXT_IN_QUEUE_LABEL",
        .tail: "APPEND_TO_QUEUE_LABEL"
    ]
}

@available(iOS 27, *)
@AppEnum(schema: .audio.affinityState)
enum AffinityState: String {
    case like
    case dislike
    case unset

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .like: "APPINTENT_AFFINITY_FAVORITE",
        .dislike: "APPINTENT_AFFINITY_NOT_FAVORITE",
        .unset: "APPINTENT_AFFINITY_UNSET"
    ]
}

@available(iOS 27, *)
@AppIntent(schema: .audio.playAudio)
struct PlayAudioIntent {
    var audioEntity: AudioItem
    var playbackAttributes: Set<PlaybackAttributes>
    var warmupAudioQueueResult: WarmupAudioQueueResult?
    var queueLocation: QueueInsertionLocation?

    func perform() async throws -> some IntentResult {
        guard let media = audioEntity.playableMedia, !media.isEmpty else {
            throw IntentError.noMatchingMedia
        }

        let shuffle = playbackAttributes.contains(.shuffle)
        let repeatAll = playbackAttributes.contains(.repeat)
        let location = queueLocation
        let playbackService = PlaybackService.sharedInstance()
        playbackService.fullscreenSessionRequested = false

        await MainActor.run {
            playbackService.isShuffleMode = shuffle
            playbackService.repeatMode = repeatAll ? .repeatAllItems : .doNotRepeat

            switch location {
            case .next:
                playbackService.playCollectionNextInQueue(media)
            case .tail:
                playbackService.appendCollectionToQueue(media)
            case nil:
                playbackService.playCollection(media)
            }
        }

        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .audio.warmupAudioQueue)
struct WarmupAudioQueueIntent {
    var audioEntity: AudioItem
    var playbackAttributes: Set<PlaybackAttributes>

    func perform() async throws -> some ReturnsValue<WarmupAudioQueueResult> {
        guard let media = audioEntity.playableMedia, !media.isEmpty else {
            throw IntentError.noMatchingMedia
        }

        return .result(value: WarmupAudioQueueResult(id: audioEntity.entityID))
    }
}

@available(iOS 27, *)
@AppIntent(schema: .audio.addToPlaylist)
struct AddAudioToPlaylistIntent {
    var audioEntity: AudioItem
    var playlist: PlaylistEntity

    func perform() async throws -> some IntentResult {
        let resolver = IntentContext.resolver

        guard let target = resolver.playlist(for: VLCMLIdentifier(playlist.id)),
              let media = audioEntity.playableMedia, !media.isEmpty else {
            throw IntentError.noMatchingMedia
        }

        let appended = media.filter { target.appendMedia(withIdentifier: $0.identifier()) }
        guard !appended.isEmpty else {
            throw IntentError.playlistUpdateFailed
        }

        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .audio.updateAudioAffinity)
struct UpdateAudioAffinityIntent {
    var affinityState: AffinityState
    var target: AudioItem

    func perform() async throws -> some IntentResult {
        let resolver = IntentContext.resolver

        guard resolver.isLibraryExposable,
              resolver.setFavorite(affinityState == .like,
                                   for: target.identifier,
                                   kind: target.kind) else {
            throw IntentError.noMatchingMedia
        }

        return .result()
    }
}

#endif
