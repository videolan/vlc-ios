/*****************************************************************************
 * VideoPlayerViewController+ControlsDelegate.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2020 VideoLAN. All rights reserved.
 * Copyright © 2020 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
*****************************************************************************/

// MARK: VideoPlayerControlsDelegate

extension VideoPlayerViewController: VideoPlayerControlsDelegate {
    func videoPlayerControlsDelegateDidTapSubtitle(_ videoPlayerControls: VideoPlayerControls) {
#if os(iOS)
        let orientation = getInterfaceOrientationMask(orientation: UIApplication.shared.statusBarOrientation)

        titleSelectionView.mainStackView.axis = orientation == .landscape ? .horizontal : .vertical
        titleSelectionView.mainStackView.distribution = orientation == .landscape ? .fillEqually : .fill

        titleSelectionView.updateHeightConstraints()
        titleSelectionView.reload()

        view.bringSubviewToFront(titleSelectionView)
        // Show warning for subtitles when connected to a renderer.
        guard playbackService.renderer == nil else {
            let subtitleCastWarningAlert = UIAlertController(title: NSLocalizedString("PLAYER_WARNING_SUBTITLE_CAST_TITLE", comment: ""),
                                                             message: NSLocalizedString("PLAYER_WARNING_SUBTITLE_CAST_DESCRIPTION", comment: ""),
                                                             preferredStyle: .alert)
            let doneButton = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""),
                                           style: .default) {
                [titleSelectionView] _ in
                titleSelectionView.isHidden = !titleSelectionView.isHidden
            }
            subtitleCastWarningAlert.addAction(doneButton)
            present(subtitleCastWarningAlert, animated: true)
            return
        }
#else
        titleSelectionView.mainStackView.axis = .horizontal
        titleSelectionView.mainStackView.distribution = .fillEqually

        titleSelectionView.updateHeightConstraints()
        titleSelectionView.reload()

        view.bringSubviewToFront(titleSelectionView)
#endif
        titleSelectionView.isHidden = !titleSelectionView.isHidden
    }

    func videoPlayerControlsDelegateRepeat(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.toggleRepeatMode()
        self.playModeUpdated()
    }

    func videoPlayerControlsDelegateDidTapDVD(_ videoPlayerControls: VideoPlayerControls) {
        // Not DVD support yet.
    }

    func getInterfaceOrientationMask(orientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
        if orientation == .portrait {
            return .portrait
        } else if orientation == .landscapeLeft
                    || orientation == .landscapeRight
                    || orientation == .portraitUpsideDown {
            return .landscape
        } else {
            return .allButUpsideDown
        }
    }

#if os(iOS)
    func videoPlayerControlsDelegateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls) {
        let mask = getInterfaceOrientationMask(orientation: UIApplication.shared.statusBarOrientation)

        if supportedInterfaceOrientations == .allButUpsideDown {
            supportedInterfaceOrientations = mask
            videoPlayerControls.rotationLockButton.tintColor = PresentationTheme.current.colors.orangeUI
        } else {
            supportedInterfaceOrientations = .allButUpsideDown
            videoPlayerControls.rotationLockButton.tintColor = .white
        }
    }
#else
    func videoPlayerControlsDelegateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls) {
    }
#endif

    func videoPlayerControlsDelegateDidTapBackward(_ videoPlayerControls: VideoPlayerControls) {
        totalSeekDuration = previousSeekState == .forward ? -seekBackwardBy : totalSeekDuration - seekBackwardBy
        previousSeekState = .backward

        displayAndApplySeekDuration(seekBackwardBy)
    }

    func videoPlayerControlsDelegateDidTapPreviousMedia(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.previous()
    }

    func videoPlayerControlsDelegateDidTapPlayPause(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.playPause()
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.isPlaying)
    }

    func videoPlayerControlsDelegateDidLongPressPlayPauseEnded(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.stopPlayback()
    }

    func videoPlayerControlsDelegateDidTapNextMedia(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.next()
    }

    func videoPlayerControlsDelegateDidTapForward(_ videoPlayerControls: VideoPlayerControls) {
        totalSeekDuration = previousSeekState == .backward ? seekForwardBy : totalSeekDuration + seekForwardBy
        previousSeekState = .forward

        displayAndApplySeekDuration(seekForwardBy)
    }

    func videoPlayerControlsDelegateDidTapAspectRatio(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.switchAspectRatio(false)
    }

    func videoPlayerControlsDelegateDidLongPressAspectRatio(_ videoPlayerControls: VideoPlayerControls) {
        present(aspectRatioActionSheet, animated: false) {
            let selectedIndexPath = IndexPath(row: self.playbackService.currentAspectRatio, section: 0)
            self.aspectRatioActionSheet.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredVertically)
        }
    }

    func videoPlayerControlsDelegateShuffle(_ videoPlayerControls: VideoPlayerControls) {
        if playbackService.isShuffleMode {
            playbackService.isShuffleMode = false
            videoPlayerControls.shuffleButton.tintColor = .white
        } else {
            playbackService.isShuffleMode = true
            videoPlayerControls.shuffleButton.tintColor = PresentationTheme.current.colors.orangeUI
        }
    }

    func videoPlayerControlsDelegateDidMoreActions(_ videoPlayerControls: VideoPlayerControls) {
        present(moreOptionsActionSheet, animated: false) {
            [unowned self] in
            self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
            self.moreOptionsActionSheet.hidePlayer()
        }
    }
}
