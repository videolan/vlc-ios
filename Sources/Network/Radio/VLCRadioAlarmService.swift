/*****************************************************************************
 * VLCRadioAlarmService.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

#if canImport(AlarmKit)
import AlarmKit
import AppIntents
import CryptoKit
import SwiftUI

/// AlarmAttributes is generic over its metadata, but an alarm never hands it back to us,
/// so there is nothing worth carrying here.
@available(iOS 26.1, *)
struct VLCRadioAlarmMetadata: AlarmMetadata {
}

/// AlarmKit only accepts a LiveActivityIntent, which the Shortcuts app never lists,
/// so this is a separate type from the user facing PlayRadioStationIntent.
@available(iOS 26.1, *)
struct PlayRadioStationAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("APPINTENT_PLAY_RADIO_TITLE")
    static var isDiscoverable: Bool = false
    static var supportedModes: IntentModes = .foreground

    @Parameter(title: LocalizedStringResource("RADIO"))
    var station: RadioStationEntity

    init() {
    }

    init(station: RadioStationEntity) {
        self.station = station
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await station.play()
        return .result()
    }
}
#endif

@objc(VLCRadioAlarmError)
enum VLCRadioAlarmError: Int, Error {
    case authorizationDenied = 1
    case schedulingFailed = 2
    case unsupported = 3
}

@objc(VLCRadioAlarmInfo)
class VLCRadioAlarmInfo: NSObject {
    @objc let hour: Int
    @objc let minute: Int
    /// Calendar weekdays, 1 = Sunday … 7 = Saturday. An empty array means the alarm fires once.
    @objc let weekdays: [NSNumber]

    init(hour: Int, minute: Int, weekdays: [NSNumber]) {
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }
}

@objc(VLCRadioAlarmService)
class VLCRadioAlarmService: NSObject {
    @objc static let shared = VLCRadioAlarmService()

    // MARK: - queries

    @objc func alarm(forURL url: URL) -> VLCRadioAlarmInfo? {
#if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            let identifier = VLCRadioAlarmService.identifier(for: url)
            guard let alarms = try? AlarmManager.shared.alarms,
                  let alarm = alarms.first(where: { $0.id == identifier }),
                  case .relative(let relative)? = alarm.schedule else {
                return nil
            }

            var weekdays: [NSNumber] = []
            if case .weekly(let days) = relative.repeats {
                weekdays = days.compactMap { VLCRadioAlarmService.calendarWeekdays.firstIndex(of: $0) }
                                .map { NSNumber(value: $0 + 1) }
            }

            return VLCRadioAlarmInfo(hour: relative.time.hour,
                                     minute: relative.time.minute,
                                     weekdays: weekdays)
        }
#endif
        return nil
    }

    @objc func localizedAlarmDescription(forURL url: URL) -> String? {
        guard let info = alarm(forURL: url) else {
            return nil
        }

        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = info.hour
        components.minute = info.minute
        guard let date = calendar.date(from: components) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: date)

        if info.weekdays.isEmpty {
            return time
        }

        let symbols = calendar.shortWeekdaySymbols
        let days = info.weekdays.map { $0.intValue }.sorted()
            .compactMap { $0 >= 1 && $0 <= symbols.count ? symbols[$0 - 1] : nil }

        return "\(time) · \(days.joined(separator: " "))"
    }

    // MARK: - scheduling

    @objc func scheduleAlarm(forFavorite favorite: VLCFavorite,
                             hour: Int,
                             minute: Int,
                             weekdays: [NSNumber],
                             completion: @escaping (Error?) -> Void) {
#if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            Task {
                var failure: Error? = nil
                do {
                    try await self.schedule(favorite: favorite, hour: hour, minute: minute, weekdays: weekdays)
                } catch {
                    failure = error
                }
                DispatchQueue.main.async {
                    completion(failure)
                }
            }
            return
        }
#endif
        DispatchQueue.main.async {
            completion(VLCRadioAlarmError.unsupported)
        }
    }

    @objc func removeAlarm(forURL url: URL) {
#if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            try? AlarmManager.shared.cancel(id: VLCRadioAlarmService.identifier(for: url))
        }
#endif
    }

#if canImport(AlarmKit)
    /// 1 = Sunday … 7 = Saturday, matching Calendar and its weekday symbols.
    @available(iOS 26.1, *)
    private static let calendarWeekdays: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday,
                                                             .thursday, .friday, .saturday]

    @available(iOS 26.1, *)
    private func schedule(favorite: VLCFavorite, hour: Int, minute: Int, weekdays: [NSNumber]) async throws {
        try await requestAuthorizationIfNeeded()

        let days = weekdays.map { $0.intValue }.sorted().compactMap { weekday -> Locale.Weekday? in
            let all = VLCRadioAlarmService.calendarWeekdays
            return weekday >= 1 && weekday <= all.count ? all[weekday - 1] : nil
        }
        let schedule = Alarm.Schedule.relative(.init(time: .init(hour: hour, minute: minute),
                                                     repeats: days.isEmpty ? .never : .weekly(days)))

        let tintColor = Color(PresentationTheme.current.colors.orangeUI)
        let listenButton = AlarmButton(text: LocalizedStringResource("RADIO_ALARM_LISTEN"),
                                       textColor: tintColor,
                                       systemImageName: "play.fill")
        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: favorite.userVisibleName),
                                            secondaryButton: listenButton,
                                            secondaryButtonBehavior: .custom)
        let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alert),
                                         metadata: VLCRadioAlarmMetadata(),
                                         tintColor: tintColor)

        let intent = PlayRadioStationAlarmIntent(station: RadioStationEntity(favorite: favorite))
        let configuration = AlarmManager.AlarmConfiguration(schedule: schedule,
                                                            attributes: attributes,
                                                            secondaryIntent: intent)

        do {
            _ = try await AlarmManager.shared.schedule(id: VLCRadioAlarmService.identifier(for: favorite.url),
                                                       configuration: configuration)
        } catch {
            throw VLCRadioAlarmError.schedulingFailed
        }
    }

    @available(iOS 26.1, *)
    private func requestAuthorizationIfNeeded() async throws {
        switch AlarmManager.shared.authorizationState {
        case .authorized:
            return
        case .notDetermined:
            guard try await AlarmManager.shared.requestAuthorization() == .authorized else {
                throw VLCRadioAlarmError.authorizationDenied
            }
        default:
            throw VLCRadioAlarmError.authorizationDenied
        }
    }

    /// Alarms carry no readable metadata, so the identifier is derived from the station URL.
    /// This keeps AlarmManager the only place where our alarms are stored.
    @available(iOS 26.1, *)
    private static func identifier(for url: URL) -> UUID {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return UUID(uuid: digest.withUnsafeBytes { $0.loadUnaligned(as: uuid_t.self) })
    }
#endif

    // Required so that genstrings/update_strings.py doesn't delete the localized strings
    static var _genstringsDummy = [
        NSLocalizedString("RADIO_ALARM_LISTEN", comment: ""),
    ]
}
