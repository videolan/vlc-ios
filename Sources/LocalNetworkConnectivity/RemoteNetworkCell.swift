/*****************************************************************************
 * RemoteNetworkCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class VLCRemoteNetworkCell: UITableViewCell {
    @objc static let cellIdentifier = "RemoteNetworkCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        accessoryType = .disclosureIndicator
        updateTheme()
    }

    @objc func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        detailTextLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }
}
