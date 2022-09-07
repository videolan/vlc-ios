/*****************************************************************************
* UIScrollView+flashScrollIndicatorsIfNeeded.swift
*
* Copyright © 2021 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

extension UIScrollView {
    func flashScrollIndicatorsIfNeeded() {
        let overflowsRight = contentOffset.x + frame.width < contentSize.width
        let overflowsLeft = contentOffset.x > 0
        let overflowsTop = contentOffset.y > 0
        let overflowsBottom = contentOffset.y + frame.height < contentSize.height

        if overflowsLeft || overflowsRight || overflowsTop || overflowsBottom {
            flashScrollIndicators()
        }
    }
}
