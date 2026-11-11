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
                                           image: menuIcon(for: .interfaceLock),
                                           state: isInterfaceLocked ? .on : .off) { _ in
            self.mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: !isInterfaceLocked)
        }
        guard !isInterfaceLocked else {
            return [interfaceLockAction]
        }

        let videoFiltersAction = UIAction(title: ActionSheetCellIdentifier.filter.description,
                                          image: menuIcon(for: .filter)) { _ in
            self.mediaMoreOptionsActionSheetPresentVideoFilters()
        }
        let abRepeatAction = UIAction(title: ActionSheetCellIdentifier.abRepeat.description,
                                      image: menuIcon(for: .abRepeat)) { _ in
            self.mediaMoreOptionsActionSheetPresentABRepeatView(with: self.moreOptionsActionSheet.abRepeatView)
        }

        var playbackActions = [makePlaybackSpeedAction(), makeSleepTimerAction(), makeEqualizerAction()]
        if !(self is AudioPlayerViewController) {
            playbackActions.append(videoFiltersAction)
        }

        return [makePlaybackModesSection(interfaceLockAction: interfaceLockAction),
                UIMenu(options: .displayInline, children: playbackActions),
                UIMenu(options: .displayInline, children: [abRepeatAction, makeNavigationMenu()])]
    }

    private func makePlaybackModesSection(interfaceLockAction: UIAction) -> UIMenu {
        var keepsMenuPresented: UIMenuElement.Attributes = []
        if #available(iOS 16.0, *) {
            keepsMenuPresented = .keepsMenuPresented
        }

        let repeatMode = moreOptionsActionSheet.configureRepeatMode()
        let repeatAction = UIAction(title: repeatMode.title,
                                    image: repeatMode.image?.withRenderingMode(.alwaysTemplate),
                                    attributes: keepsMenuPresented,
                                    state: repeatMode.isEnabled ? .on : .off) { _ in
            self.mediaMoreOptionsActionSheetDidTapRepeat(self.moreOptionsActionSheet)
            self.refreshVisibleMoreOptionsMenu()
        }

        let shuffleMode = moreOptionsActionSheet.configureShuffleMode()
        let shuffleAction = UIAction(title: shuffleMode.title,
                                     image: shuffleMode.image?.withRenderingMode(.alwaysTemplate),
                                     attributes: keepsMenuPresented,
                                     state: shuffleMode.isEnabled ? .on : .off) { _ in
            self.mediaMoreOptionsActionSheetDidToggleShuffle(self.moreOptionsActionSheet)
            self.refreshVisibleMoreOptionsMenu()
        }

        let section = UIMenu(options: .displayInline, children: [repeatAction, shuffleAction, interfaceLockAction])
        if #available(iOS 16.0, *) {
            section.preferredElementSize = .medium
        }
        return section
    }

    private func refreshVisibleMoreOptionsMenu() {
        if #available(iOS 16.0, *) {
            moreOptionsMenuButton?.contextMenuInteraction?.updateVisibleMenu { menu in
                menu.replacingChildren(self.makeMoreOptionsMenuElements())
            }
        }
    }

    private func menuIcon(for identifier: ActionSheetCellIdentifier) -> UIImage? {
        return UIImage(named: identifier.rawValue)?.withRenderingMode(.alwaysTemplate)
    }

    private func makePlaybackSpeedAction() -> UIAction {
        let currentSpeed = PlaybackSpeedScale.rounded(playbackService.playbackRate)
        return UIAction(title: ActionSheetCellIdentifier.playback.description,
                        subtitle: PlaybackSpeedFormatter.string(forSpeed: currentSpeed),
                        image: menuIcon(for: .playback)) { _ in
            self.mediaMoreOptionsActionSheetPresentPlaybackSpeed()
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

        return UIAction(title: ActionSheetCellIdentifier.sleepTimer.description,
                        subtitle: summary,
                        image: menuIcon(for: .sleepTimer)) { _ in
            self.mediaMoreOptionsActionSheetPresentSleepTimer()
        }
    }

    private func makeEqualizerAction() -> UIAction {
        let summary = EqualizerView.presetName(for: playbackService.selectedEqualizerProfile(),
                                               presets: playbackService.equalizerProfiles(),
                                               customProfileNames: playbackService.customEqualizerProfileNames)

        return UIAction(title: ActionSheetCellIdentifier.equalizer.description,
                        subtitle: summary,
                        image: menuIcon(for: .equalizer)) { _ in
            self.mediaMoreOptionsActionSheetPresentEqualizer()
        }
    }

    private func makeNavigationMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        if moreOptionsActionSheet.currentMediaHasChapters {
            children.append(makeChaptersMenu())
        }

        children.append(UIAction(title: ActionSheetCellIdentifier.bookmarks.description,
                                 image: menuIcon(for: .bookmarks)) { _ in
            self.presentBookmarks()
        })
        children.append(UIAction(title: NSLocalizedString("ADD_BOOKMARK", comment: ""),
                                 image: UIImage(systemName: "bookmark"),
                                 attributes: playbackService.currentlyPlayingLibraryMedia == nil ? .disabled : []) { _ in
            self.moreOptionsActionSheet.addBookmarkAtCurrentTime()
        })

        return UIMenu(title: NSLocalizedString("MORE_OPTIONS_NAVIGATION", comment: ""),
                      image: menuIcon(for: .chapters),
                      children: children)
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
                self.mediaMoreOptionsActionSheetUpdateProgressBar()
            }
        }
        sections.append(UIMenu(title: NSLocalizedString("CHOOSE_CHAPTER", comment: ""),
                               options: .displayInline,
                               children: chapterActions))

        return UIMenu(title: ActionSheetCellIdentifier.chapters.description,
                      image: menuIcon(for: .chapters),
                      children: sections)
    }

    private func presentBookmarks() {
        present(moreOptionsActionSheet, animated: false) {
            self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
            self.moreOptionsActionSheet.hidePlayer()
            self.moreOptionsActionSheet.addView(.bookmarks)
        }
    }
}
