/*****************************************************************************
 * VideoPlayerViewController+ControlsDelegate.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2020 VideoLAN. All rights reserved.
 * Copyright © 2020 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
*****************************************************************************/

// MARK: VideoPlayerControlsDelegate

extension VideoPlayerViewController: VideoPlayerControlsDelegate {
    func videoPlayerControlsDelegateDidTapSubtitle(_ videoPlayerControls: VideoPlayerControls) {
        trackSelector.trackChapters = false
        trackSelector.update()
        shouldShowTrackSelectorPopup(!trackSelectorPopupView.isShown)
    }
    
    func videoPlayerControlsDelegateRepeat(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.toggleRepeatMode()
        self.setRepeatMode()
    }

    func videoPlayerControlsDelegateDidTapDVD(_ videoPlayerControls: VideoPlayerControls) {
        // Not DVD support yet.
    }

    private func getInterfaceOrientationMask(orientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
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

    func videoPlayerControlsDelegateDidTapBackward(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.jumpBackward(10)
    }

    func videoPlayerControlsDelegateDidTapPreviousMedia(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.previous()
    }

    func videoPlayerControlsDelegateDidTapPlayPause(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.playPause()
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.isPlaying)
    }

    func videoPlayerControlsDelegateDidTapNextMedia(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.next()
    }

    func videoPlayerControlsDelegateDidTapForeward(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.jumpForward(10)
    }

    func videoPlayerControlsDelegateDidTapAspectRatio(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.switchAspectRatio(false)
        
        aspectRatioStatusLabel.text = playbackService.string(for: playbackService.currentAspectRatio)
        aspectRatioStatusLabel.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 1.0) {
                self.aspectRatioStatusLabel.isHidden = true
            }
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
