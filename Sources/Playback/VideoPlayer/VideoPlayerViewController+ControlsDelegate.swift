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

extension VideoPlayerViewController: VideoPlayerControlsDelgate {
    func videoPlayerControlsDelgateDidTapSubtitle(_ videoPlayerControls: VideoPlayerControls) {
        if self.trackSelector.isHidden == true
            || trackSelector.switchingTracksNotChapters == false {
            trackSelector.switchingTracksNotChapters = true
            trackSelector.isHidden = false
            trackSelector.alpha = 1
            trackSelector.update()
        } else {
            trackSelector.isHidden = true
            trackSelector.switchingTracksNotChapters = false
        }
    }

    func videoPlayerControlsDelgateDidTapDVD(_ videoPlayerControls: VideoPlayerControls) {
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

    func videoPlayerControlsDelgateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls) {
        let mask = getInterfaceOrientationMask(orientation: UIApplication.shared.statusBarOrientation)

        if supportedInterfaceOrientations == .allButUpsideDown {
            supportedInterfaceOrientations = mask
            videoPlayerControls.rotationLockButton.tintColor = PresentationTheme.current.colors.orangeUI
        } else {
            supportedInterfaceOrientations = .allButUpsideDown
            videoPlayerControls.rotationLockButton.tintColor = .white
        }
    }

    func videoPlayerControlsDelgateDidTapBackward(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.jumpBackward(10)
    }

    func videoPlayerControlsDelgateDidTapPreviousMedia(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.previous()
    }

    func videoPlayerControlsDelgateDidTapPlayPause(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.playPause()
        videoPlayerControls.updatePlayPauseButton(toState: playbackService.isPlaying)
    }

    func videoPlayerControlsDelgateDidTapNextMedia(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.next()
    }

    func videoPlayerControlsDelgateDidTapForeward(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.jumpForward(10)
    }

    func videoPlayerControlsDelgateDidTapAspectRatio(_ videoPlayerControls: VideoPlayerControls) {
        playbackService.switchAspectRatio(false)
        
        aspectRatioStatusLabel.text = playbackService.string(for: playbackService.currentAspectRatio)
        aspectRatioStatusLabel.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 1.0) {
                self.aspectRatioStatusLabel.isHidden = true
            }
        }
    }

    func videoPlayerControlsDelgateDidMoreActions(_ videoPlayerControls: VideoPlayerControls) {
        present(moreOptionsActionSheet, animated: false) {
            [unowned self] in
            self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
            self.moreOptionsActionSheet.hidePlayer()
        }
    }


}
