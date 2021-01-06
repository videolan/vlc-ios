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
        // FIXME
    }

    func videoPlayerControlsDelgateDidTapDVD(_ videoPlayerControls: VideoPlayerControls) {
        // Not DVD support yet.
    }

    private func getInterfaceOrientationMask(orientation: UIDeviceOrientation) -> UIInterfaceOrientationMask {
        if orientation.isValidInterfaceOrientation {
            if orientation == .portrait {
                return .portrait
            } else if orientation == .landscapeLeft || orientation == .landscapeRight || orientation == .portraitUpsideDown {
                return .landscape
            } else {
                return .allButUpsideDown
            }
        } else {
            return .allButUpsideDown
        }
    }

    func videoPlayerControlsDelgateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls) {
        let mask = getInterfaceOrientationMask(orientation: UIDevice.current.orientation)

        if supportedInterfaceOrientations == .allButUpsideDown && mask != .allButUpsideDown {
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
    }

    func videoPlayerControlsDelgateDidMoreActions(_ videoPlayerControls: VideoPlayerControls) {
        present(moreOptionsActionSheet, animated: false) {
            [unowned self] in
            self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
            self.moreOptionsActionSheet.hidePlayer()
        }
    }


}
