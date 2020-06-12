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

    func videoPlayerControlsDelgateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls) {
        // FIXME
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
        }

    }


}
