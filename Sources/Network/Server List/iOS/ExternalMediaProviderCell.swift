/*****************************************************************************
 * ExternalMediaProviderCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCExternalMediaProviderCell)
class ExternalMediaProviderCell: UITableViewCell {
    @objc static var cellIdentifier: String {
        NSStringFromClass(self)
    }

    class var edgePadding: CGFloat {
        return 15
    }

    class var interItemPadding: CGFloat {
        return 5
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
        textLabel?.numberOfLines = 1
        detailTextLabel?.numberOfLines = 1
        updateTheme()
    }

    @objc private func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        detailTextLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }
}
