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

 @IBDesignable class PlayingExternallyView: UIView {

    @IBInspectable var nibName: String?
    @IBOutlet weak var playingExternallyTitle: UILabel!
    @IBOutlet weak var playingExternallyDescription: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
        playingExternallyTitle.text = NSLocalizedString("PLAYING_EXTERNALLY_TITLE", comment: "")
        playingExternallyDescription.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
    }

    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask =
            [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }

    func loadViewFromNib() -> PlayingExternallyView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(
            withOwner: self,
            options: nil).first as? PlayingExternallyView
    }

    @objc func updateUI(rendererItem: VLCRendererItem?, title: String) {
        if let rendererItem = rendererItem {
            playingExternallyTitle.text = title + NSLocalizedString("PLAYING_EXTERNALLY_ADDITION", comment:"\n should stay in every translation")
            playingExternallyDescription.text = rendererItem.name
        } else {
            playingExternallyTitle.text = title
            playingExternallyDescription.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
        }
    }
}
