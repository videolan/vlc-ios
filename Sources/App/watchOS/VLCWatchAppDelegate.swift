/*****************************************************************************
 * VLCWatchAppDelegate.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import WatchKit
import WatchConnectivity

class VLCWatchAppDelegate: NSObject, WKApplicationDelegate {

    private lazy var sessionDelegate: VLCSessionDelegate = {
        return VLCSessionDelegate()
    }()

    // Hold the KVO observers to keep observing the change in the extension's lifetime.
    //
    private var activationStateObservation: NSKeyValueObservation?
    private var hasContentPendingObservation: NSKeyValueObservation?

    // An array to keep the background tasks.
    //
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()

    override init() {
        super.init()
        assert(WCSession.isSupported(), "This sample requires a platform supporting Watch Connectivity!")

        let appDefaults: [String : Any] = [
            kVLCSettingAppTheme : kVLCSettingAppThemeBright,
            kVLCSettingPasscodeEnableBiometricAuth : 1,
            kVLCSettingContinueAudioInBackgroundKey : true,
            kVLCSettingStretchAudio : true,
            kVLCSettingDefaultPreampLevel : 6,
            kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
            kVLCSettingSkipLoopFilter : 1,
            kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
            kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
            kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
            kVLCSettingSubtitlesBoldFont: false,
            kVLCSettingDeinterlace : -1,
            kVLCSettingHardwareDecoding : kVLCSettingHardwareDecodingDefault,
            kVLCSettingNetworkCaching : 999,
            kVLCSettingVolumeGesture : true,
            kVLCSettingPlayPauseGesture : true,
            kVLCSettingBrightnessGesture : true,
            kVLCSettingSeekGesture : true,
            kVLCSettingCloseGesture : true,
            kVLCSettingSnapshotGesture : false,
            kVLCSettingPlaybackLongTouchSpeedUp : true,
            kVLCSettingVideoFullscreenPlayback : true,
            kVLCSettingContinuePlayback : 1,
            kVLCSettingContinueAudioPlayback : 1,
            kVLCSettingWiFiSharingIPv6 : false,
            kVLCSettingNetworkRTSPTCP : false,
            kVLCSettingNetworkRTSPHTTP : false,
            kVLCSettingNetworkSatIPChannelListUrl : "",
            kVLCSettingEqualizerProfile : 0,
            kVLCSettingEqualizerProfileDisabled : true,
            kVLCSettingPlaybackForwardBackwardEqual: true,
            kVLCSettingPlaybackTapSwipeEqual:  true,
            kVLCSettingPlaybackForwardSkipLength : 10,
            kVLCSettingPlaybackBackwardSkipLength : 10,
            kVLCSettingPlaybackForwardSkipLengthSwipe : 10,
            kVLCSettingPlaybackBackwardSkipLengthSwipe : 10,
            kVLCSettingPlaybackLockscreenSkip : false,
            kVLCSettingPlaybackRemoteControlSkip : false,
            kVLCSettingOpenAppForPlayback : true,
            kVLCAutomaticallyPlayNextItem : true,
            kVLCPlaylistPlayNextItem: true,
            kVLCSettingEnableMediaCellTextScrolling : false,
            kVLCSettingShowThumbnails : true,
            kVLCSettingShowArtworks : true,
            kVLCSettingBackupMediaLibrary : false,
            kVLCSettingCastingAudioPassthrough : false,
            kVLCSettingCastingConversionQuality : 2,
            kVLCForceSMBV1 : true,
            kVLCAudioLibraryGridLayoutALBUMS : true,
            kVLCAudioLibraryGridLayoutARTISTS : true,
            kVLCAudioLibraryGridLayoutGENRES : true,
            kVLCVideoLibraryGridLayoutALL_VIDEOS : true,
            kVLCVideoLibraryGridLayoutVIDEO_GROUPS : true,
            kVLCVideoLibraryGridLayoutVLCMLMediaGroupCollections : true,
            kVLCPlayerShouldRememberState: true,
            kVLCPlayerIsShuffleEnabled: false,
            kVLCPlayerIsRepeatEnabled: 0,
            kVLCSettingPlaybackSpeedDefaultValue: 1.0,
            kVLCPlayerShowPlaybackSpeedShortcut: false,
            kVLCSettingAlwaysPlayURLs: false,
            kVLCRestoreLastPlayedMedia: false,
            kVLCSettingPlayerControlDuration: 4,
            kVLCSettingPauseWhenShowingControls: false
        ]

        UserDefaults.standard.register(defaults: appDefaults)

        // Apps must complete WKWatchConnectivityRefreshBackgroundTask. Otherwise, tasks keep consuming
        // the background executing time and eventually cause a crash.
        // The timing to complete the tasks is when the current WCSession turns to a state other than .activated
        // or hasContentPending flips false (see completeBackgroundTasks), so use KVO to observe
        // the changes of the two properties.
        //
        activationStateObservation = WCSession.default.observe(\.activationState) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }
        hasContentPendingObservation = WCSession.default.observe(\.hasContentPending) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }

        // Activate the session asynchronously as early as possible.
        // When the system needs to launch the app to run a background task, this saves some background runtime budget.
        //
        WCSession.default.delegate = sessionDelegate
        WCSession.default.activate()
    }

    // Complete the background tasks, and schedule a snapshot refresh.
    //
    func completeBackgroundTasks() {
        guard !wcBackgroundTasks.isEmpty else { return }

        guard WCSession.default.activationState == .activated,
            WCSession.default.hasContentPending == false else { return }

        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }

        // Use Logger to log tasks for debugging purposes.
        //
        print("\(#function):\(wcBackgroundTasks) was completed!")

        // Schedule a snapshot refresh if the UI is updated by background tasks.
        //
        let date = Date(timeIntervalSinceNow: 1)
        WKApplication.shared().scheduleSnapshotRefresh(withPreferredDate: date, userInfo: nil) { error in

            if let error = error {
                print("scheduleSnapshotRefresh error: \(error)!")
            }
        }
        wcBackgroundTasks.removeAll()
    }

    // Apps must complete WKWatchConnectivityRefreshBackgroundTask after the pending data is received.
    // This sample retains the tasks first, and complete them in the following cases:
    // 1. hasContentPending flips false, meaning no pending data waiting for processing. Pending data means
    //    the data the device receives prior to when the WCSession gets activated.
    //    More data might arrive, but it isn't pending when the session gets activated.
    // 2. The end of the handle method.
    //    This happens when hasContentPending flips to false before the app retains the tasks.
    //

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let wcTask = task as? WKWatchConnectivityRefreshBackgroundTask {
                wcBackgroundTasks.append(wcTask)
                print("\(#function):\(wcTask.description) was appended!")
            } else {
                task.setTaskCompletedWithSnapshot(false)
                print("\(#function):\(task.description) was completed!")
            }
        }
        completeBackgroundTasks()
    }
}
