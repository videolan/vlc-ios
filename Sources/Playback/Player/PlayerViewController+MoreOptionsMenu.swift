/*****************************************************************************
 * PlayerViewController+MoreOptionsMenu.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension PlayerViewController {
    func setupMoreOptionsMenu() {
        moreOptionsMenuButton?.menu = UIMenu(children: [UIDeferredMenuElement.uncached { [weak self] completion in
            completion(self?.makeMoreOptionsMenuElements() ?? [])
        }])
    }

    private func makeMoreOptionsMenuElements() -> [UIMenuElement] {
        let isInterfaceLocked = playerController.isInterfaceLocked
        let interfaceLockAction = UIAction(title: NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: ""),
                                           image: menuIcon(named: "interfaceLock"),
                                           state: isInterfaceLocked ? .on : .off) { _ in
            self.moreOptionsMenuDidToggleInterfaceLock(state: !isInterfaceLocked)
        }
        guard !isInterfaceLocked else {
            return [interfaceLockAction]
        }

        let videoFiltersAction = UIAction(title: NSLocalizedString("VIDEO_FILTER", comment: ""),
                                          image: menuIcon(named: "filter")) { _ in
            self.showVideoFiltersCard()
        }
        let abRepeatAction = UIAction(title: NSLocalizedString("AB_LOOP", comment: ""),
                                      image: menuIcon(named: "abRepeat")) { _ in
            self.presentABRepeatView()
        }

        var playbackActions = [makePlaybackSpeedAction(), makeSleepTimerAction(), makeEqualizerAction()]
        if !(self is AudioPlayerViewController) {
            playbackActions.append(videoFiltersAction)
        }

        return [makePlaybackModesSection(interfaceLockAction: interfaceLockAction),
                UIMenu(options: .displayInline, children: playbackActions),
                UIMenu(options: .displayInline, children: [abRepeatAction] + makeNavigationActions())]
    }

    private func makePlaybackModesSection(interfaceLockAction: UIAction) -> UIMenu {
        var keepsMenuPresented: UIMenuElement.Attributes = []
        if #available(iOS 16.0, *) {
            keepsMenuPresented = .keepsMenuPresented
        }

        let repeatMode = configureRepeatMode()
        let repeatAction = UIAction(title: repeatMode.title,
                                    image: repeatMode.image?.withRenderingMode(.alwaysTemplate),
                                    attributes: keepsMenuPresented,
                                    state: repeatMode.isEnabled ? .on : .off) { _ in
            self.moreOptionsMenuDidTapRepeat()
            self.refreshVisibleMoreOptionsMenu()
        }

        let shuffleMode = configureShuffleMode()
        let shuffleAction = UIAction(title: shuffleMode.title,
                                     image: shuffleMode.image?.withRenderingMode(.alwaysTemplate),
                                     attributes: keepsMenuPresented,
                                     state: shuffleMode.isEnabled ? .on : .off) { _ in
            self.moreOptionsMenuDidToggleShuffle()
            self.refreshVisibleMoreOptionsMenu()
        }

        let section = UIMenu(options: .displayInline, children: [repeatAction, shuffleAction, interfaceLockAction])
        if #available(iOS 16.0, *) {
            section.preferredElementSize = .medium
        }
        return section
    }

    private func configureRepeatMode() -> (image: UIImage?, title: String, isEnabled: Bool) {
        var image: UIImage?
        var localization: String = ""
        var isEnabled: Bool = false
        switch playbackService.repeatMode {
        case .doNotRepeat:
            isEnabled = false
            image = UIImage(named: "iconRepeat")
            localization = NSLocalizedString("MENU_REPEAT_DISABLED", comment: "")
        case .repeatCurrentItem:
            isEnabled = true
            image = UIImage(named: "iconRepeatOne")
            localization = NSLocalizedString("MENU_REPEAT_SINGLE", comment: "")
        case .repeatAllItems:
            isEnabled = true
            image = UIImage(named: "iconRepeat")
            localization = NSLocalizedString("MENU_REPEAT_ALL", comment: "")
        @unknown default: break

        }
        return (image, localization, isEnabled)
    }

    private func configureShuffleMode() -> (image: UIImage?, title: String, isEnabled: Bool) {
        let image: UIImage? = UIImage(named: "iconShuffle")
        let localization: String = playbackService.isShuffleMode ? NSLocalizedString("SHUFFLE", comment: "") : NSLocalizedString("SHUFFLE_DISABLED", comment: "")
        let isEnabled: Bool = playbackService.isShuffleMode

        return (image, localization, isEnabled)
    }

    private func refreshVisibleMoreOptionsMenu() {
        if #available(iOS 16.0, *) {
            moreOptionsMenuButton?.contextMenuInteraction?.updateVisibleMenu { menu in
                menu.replacingChildren(self.makeMoreOptionsMenuElements())
            }
        }
    }

    private func menuIcon(named name: String) -> UIImage? {
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
    }

    private func makePlaybackSpeedAction() -> UIAction {
        let currentSpeed = PlaybackSpeedScale.rounded(playbackService.playbackRate)
        return UIAction(title: NSLocalizedString("PLAYBACK_SPEED", comment: ""),
                        subtitle: PlaybackSpeedFormatter.string(forSpeed: currentSpeed),
                        image: menuIcon(named: "playback")) { _ in
            self.showPlaybackSpeedCard()
        }
    }

    private func makeSleepTimerAction() -> UIAction {
        var summary = NSLocalizedString("OFF", comment: "")
        if let fireDate = playbackService.sleepTimer?.fireDate {
            summary = SleepTimerControlsView.remainingTimeString(for: max(fireDate.timeIntervalSinceNow, 0))
        } else if playbackService.stopAfterCurrentItem {
            summary = self is AudioPlayerViewController ? NSLocalizedString("SLEEP_TIMER_STOP_AFTER_THIS_TRACK", comment: "")
                                                        : NSLocalizedString("SLEEP_TIMER_STOP_AFTER_THIS_VIDEO", comment: "")
        }

        return UIAction(title: NSLocalizedString("BUTTON_SLEEP_TIMER", comment: ""),
                        subtitle: summary,
                        image: menuIcon(named: "sleepTimer")) { _ in
            self.showSleepTimerCard()
        }
    }

    private func makeEqualizerAction() -> UIAction {
        let summary = EqualizerView.presetName(for: playbackService.selectedEqualizerProfile(),
                                               presets: playbackService.equalizerProfiles(),
                                               customProfileNames: playbackService.customEqualizerProfileNames)

        return UIAction(title: NSLocalizedString("EQUALIZER_CELL_TITLE", comment: ""),
                        subtitle: summary,
                        image: menuIcon(named: "equalizer")) { _ in
            self.showEqualizerCard()
        }
    }

    private func makeNavigationActions() -> [UIMenuElement] {
        let currentMedia = playbackService.currentlyPlayingLibraryMedia
        var children: [UIMenuElement] = []

        children.append(UIAction(title: NSLocalizedString("ADD_BOOKMARK", comment: ""),
                                 image: UIImage(systemName: "bookmark"),
                                 attributes: currentMedia == nil ? .disabled : []) { _ in
            self.addBookmark()
        })
        children.append(UIAction(title: NSLocalizedString("BOOKMARKS_TITLE", comment: ""),
                                 image: menuIcon(named: "bookmarks"),
                                 attributes: currentMedia?.bookmarks?.isEmpty == false ? [] : .disabled) { _ in
            self.showBookmarksCard()
        })

        if currentMediaHasChapters {
            children.append(makeChaptersMenu())
        }

        return children
    }

    private func addBookmark() {
        if let currentMedia = playbackService.currentlyPlayingLibraryMedia {
            let currentTime = playbackService.playedTime()
            let currentTimeInt64 = Int64(truncating: currentTime.value ?? 0)
            currentMedia.addBookmark(atTime: currentTimeInt64)
            if let bookmark = currentMedia.bookmark(atTime: currentTimeInt64) {
                bookmark.name = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + " " + currentTime.stringValue
                showStatusMessage(bookmark.name)
            }
        }
    }

    private func makeChaptersMenu() -> UIMenu {
        var sections: [UIMenuElement] = []

        let numberOfTitles = playbackService.numberOfTitles
        if numberOfTitles > 1 {
            let currentTitleIndex = playbackService.indexOfCurrentTitle
            let titleActions = (0..<numberOfTitles).map { index -> UIAction in
                let description = playbackService.titleDescription(at: index)
                return UIAction(title: description?.name ?? "",
                                subtitle: description?.durationTime.stringValue,
                                state: currentTitleIndex == index ? .on : .off) { _ in
                    self.playbackService.selectTitle(at: index)
                }
            }
            sections.append(UIMenu(title: NSLocalizedString("CHOOSE_TITLE", comment: ""),
                                   options: .displayInline,
                                   children: titleActions))
        }

        let chapters = playbackService.currentTitleDescription?.chapterDescriptions ?? []
        let currentChapterIndex = playbackService.indexOfCurrentChapter
        let chapterActions = chapters.enumerated().map { index, chapter -> UIAction in
            return UIAction(title: chapter.name ?? "",
                            subtitle: chapter.durationTime.stringValue,
                            state: currentChapterIndex == index ? .on : .off) { _ in
                self.playbackService.selectChapter(at: index)
                if !self.playbackService.isPlaying {
                    self.playbackService.playPause()
                }
            }
        }
        sections.append(UIMenu(title: NSLocalizedString("CHOOSE_CHAPTER", comment: ""),
                               options: .displayInline,
                               children: chapterActions))

        return UIMenu(title: NSLocalizedString("CHAPTER_SELECTION_TITLE", comment: ""),
                      image: menuIcon(named: "chapters"),
                      children: sections)
    }
}
