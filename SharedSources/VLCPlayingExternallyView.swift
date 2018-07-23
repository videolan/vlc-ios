/*****************************************************************************
 * VLCPlayingExternallyView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class VLCPlayingExternallyView: UIView {

    @IBOutlet weak var playingExternallyTitle: UILabel!
    @IBOutlet weak var playingExternallyDescription: UILabel!
    @objc var displayView: UIView? {
        return externalWindow?.rootViewController?.view
    }
    var externalWindow: UIWindow?

    @objc func shouldDisplay(_ show: Bool, movieView: UIView) {
        self.isHidden = !show
        if show {
            guard let screen = UIScreen.screens.count > 1 ? UIScreen.screens[1] : nil else {
                return
            }
            screen.overscanCompensation = .none
            externalWindow = UIWindow(frame: screen.bounds)
            guard let externalWindow = externalWindow else {
                return
            }
            externalWindow.rootViewController = VLCExternalDisplayController()
            externalWindow.rootViewController?.view.addSubview(movieView)
            externalWindow.screen = screen
            externalWindow.rootViewController?.view.frame = externalWindow.bounds
            movieView.frame = externalWindow.bounds
        } else {
            externalWindow = nil
        }
        externalWindow?.isHidden = !show
    }

    override func awakeFromNib() {
        playingExternallyTitle.text = NSLocalizedString("PLAYING_EXTERNALLY_TITLE", comment: "")
        playingExternallyDescription.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
    }

    @objc func updateUI(rendererItem: VLCRendererItem?) {
        if let rendererItem = rendererItem {
            playingExternallyTitle.text = NSLocalizedString("PLAYING_EXTERNALLY_TITLE_CHROMECAST", comment:"")
            playingExternallyDescription.text = rendererItem.name
        } else {
            playingExternallyTitle.text = NSLocalizedString("PLAYING_EXTERNALLY_TITLE", comment: "")
            playingExternallyDescription.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
        }
    }
}
