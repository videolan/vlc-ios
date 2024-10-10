/*****************************************************************************
 * PlayMediaIntent.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AppIntents
import Foundation
import OSLog

extension UnitDuration: @unchecked Sendable {
}

@available(iOS 16.4, *)
extension Logger {
    static let intentLogging = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "App Intent")
}

@available(iOS 16.4, *)
enum ShuffleMode: String, Codable, Sendable {
    case on
    case off
}

@available(iOS 16.4, *)
extension ShuffleMode: AppEnum {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("SHUFFLE")
        )
    }

    static var caseDisplayRepresentations: [ShuffleMode: DisplayRepresentation] = [
        .on: DisplayRepresentation(
            title: LocalizedStringResource("ON"),
            subtitle: nil),

        .off: DisplayRepresentation(
            title: LocalizedStringResource("OFF"),
            subtitle: nil),
    ]
}

@available(iOS 16.4, *)
enum PlaybackQueueLocation: String, Codable, Sendable {
    case now
    case next
    case later
}

@available(iOS 16.4, *)
extension PlaybackQueueLocation: AppEnum {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("QUEUE_LABEL")
        )
    }

    static var caseDisplayRepresentations: [PlaybackQueueLocation: DisplayRepresentation] = [
        .now: DisplayRepresentation(
            title: LocalizedStringResource("PLAY_LABEL"),
            subtitle: nil),

        .next: DisplayRepresentation(
            title: LocalizedStringResource("PLAY_NEXT_IN_QUEUE_LABEL"),
            subtitle: nil),

        .later: DisplayRepresentation(
            title: LocalizedStringResource("APPEND_TO_QUEUE_LABEL"),
            subtitle: nil),
    ]
}

@available(iOS 16.4, *)
enum PlaybackRepeatMode: String, Codable, Sendable {
    case doNotRepeat
    case repeatAllItems
    case repeatCurrentItem
}

@available(iOS 16.4, *)
extension PlaybackRepeatMode: AppEnum {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("REPEAT_MODE")
        )
    }

    static var caseDisplayRepresentations: [PlaybackRepeatMode: DisplayRepresentation] = [
        .doNotRepeat: DisplayRepresentation(
            title: LocalizedStringResource("MENU_REPEAT_DISABLED"),
            subtitle: nil),

        .repeatAllItems: DisplayRepresentation(
            title: LocalizedStringResource("MENU_REPEAT_ALL"),
            subtitle: nil),

        .repeatCurrentItem: DisplayRepresentation(
            title: LocalizedStringResource("MENU_REPEAT_SINGLE"),
            subtitle: nil),
    ]
}

@available(iOS 16.4, *)
struct PlayMediaIntent: AudioStartingIntent {
    init() {

    }

    struct MediaOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> ItemCollection<String> {
            let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService

            let playlists = mediaLibraryService.playlists()
            return ItemCollection {
                ItemSection(LocalizedStringResource("PLAYLISTS")) {
                    for playlist in playlists {
                        Item(playlist.title())
                    }
                }
            }
        }
    }

    static var title: LocalizedStringResource = LocalizedStringResource("APPINTENT_PLAY_MEDIA_TITLE")
    static var description = IntentDescription(LocalizedStringResource("APPINTENT_PLAY_MEDIA_DESCRIPTION"))
    static var openAppWhenRun: Bool = false

    @Parameter(title: LocalizedStringResource("PLAYLIST_PLACEHOLDER"), optionsProvider: MediaOptionsProvider())
    var mediaName: String

    @Parameter(
        title: LocalizedStringResource("SHUFFLE"), description: nil, default: .off)
    var playShuffled: ShuffleMode?

    @Parameter(
        title: LocalizedStringResource("QUEUE_LABEL"),
        description: nil, default: .now)
    var playbackQueueLocation: PlaybackQueueLocation?

    @Parameter(title: LocalizedStringResource("PLAYBACK_SPEED"), description: nil, default: 1.0)
    var playbackSpeed: Double?

    @Parameter(
        title: LocalizedStringResource("REPEAT_MODE"), description: nil,
        default: Optional.none)
    var playbackRepeatMode: PlaybackRepeatMode?

    @Parameter(title: LocalizedStringResource("BUTTON_SLEEP_TIMER"), description: nil)
    var sleepTimer: Measurement<UnitDuration>?

    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("APPINTENT_PLAY_MEDIA_TITLE", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_MEDIA_DESCRIPTION", comment: ""),
        NSLocalizedString("APPINTENT_PLAY_MEDIA_PLAY_${mediaName}", comment: ""),
    ]
    
    static var parameterSummary: some ParameterSummary {
        Summary("APPINTENT_PLAY_MEDIA_PLAY_\(\.$mediaName)") {
            \.$playShuffled
            \.$playbackQueueLocation
            \.$playbackSpeed
            \.$playbackRepeatMode
            \.$sleepTimer
        }
    }



    func perform() async throws -> some IntentResult {

        let processinfo = ProcessInfo()
        processinfo.performExpiringActivity(withReason: "VLC Play Media Intent Triggered") { (expired) in

            Logger.intentLogging.debug("VLC Play Media Intent: \(mediaName)")

            let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
            let playbackService = PlaybackService.sharedInstance()

            if let playlist = mediaLibraryService.medialib.searchPlaylists(byName: mediaName, of: .all)?.first {
                if let media = playlist.files() {
                    Logger.intentLogging.debug("Found media for playlist \(playlist.title())")
                    playbackService.fullscreenSessionRequested = false
                    DispatchQueue.main.async {
                        var mediaToPlay = media
                        if let isShuffle = playShuffled {
                            playbackService.isShuffleMode = isShuffle == .on
                            if isShuffle == .on {
                                mediaToPlay = mediaToPlay.shuffled()
                            }
                        }
                        switch playbackQueueLocation {
                        case .now:
                            playbackService.playCollection(mediaToPlay)
                        case .next:
                            playbackService.playCollectionNextInQueue(mediaToPlay)
                        case .later:
                            playbackService.appendCollectionToQueue(mediaToPlay)
                        case nil:
                            playbackService.playCollection(mediaToPlay)
                        }
                        if let playbackRate = playbackSpeed {
                            playbackService.playbackRate = Float(playbackRate)
                        }
                        playbackService.repeatMode = {
                            switch playbackRepeatMode {
                            case .doNotRepeat:
                                return .doNotRepeat
                            case .repeatAllItems:
                                return .repeatAllItems
                            case .repeatCurrentItem:
                                return .repeatCurrentItem
                            case nil:
                                return .doNotRepeat
                            }
                        }()
                        if let sleepTimer = sleepTimer {
                            let sleepTimerSeconds = sleepTimer.converted(to: .seconds).value
                            let timeInterval: TimeInterval = TimeInterval(sleepTimerSeconds)
                            playbackService.scheduleSleepTimer(withInterval: timeInterval)
                        }
                    }
                } else {
                    Logger.intentLogging.debug("No media found for playlist \(playlist.title())")
                }
            }
        }

        return .result()
    }
}
