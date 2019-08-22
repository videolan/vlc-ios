/*****************************************************************************
 * MovieViewController+Delegates.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


extension VLCMovieViewController: VideoOptionsControlBarDelegate {

    func videoOptionsControlBarDidToggleFullScreen(_ optionsBar: VideoOptionsControlBar) {
        vpc.switchAspectRatio(true)
    }

    func videoOptionsControlBarDidToggleRepeat(_ optionsBar: VideoOptionsControlBar) {
        vpc.toggleRepeatMode()
        optionsBar.repeatMode = vpc.repeatMode
    }

    func videoOptionsControlBarDidSelectSubtitle(_ optionsBar: VideoOptionsControlBar) {
        assertionFailure("didSelectSubtitle not implemented")
    }

    func videoOptionsControlBarDidSelectMoreOptions(_ optionsBar: VideoOptionsControlBar) {
        toggleMoreOptionsActionSheet()
    }
}

extension VLCMovieViewController: MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        toggleUILock()
    }
}
