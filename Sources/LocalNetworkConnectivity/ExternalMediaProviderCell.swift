/*****************************************************************************
 * ExternalMediaProviderCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCExternalMediaProviderCell)
class ExternalMediaProviderCell: UITableViewCell {
    @objc static var cellIdentifier: String {
        NSStringFromClass(self)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTheme),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
        updateTheme()
    }

    @objc private func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        detailTextLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }
}
