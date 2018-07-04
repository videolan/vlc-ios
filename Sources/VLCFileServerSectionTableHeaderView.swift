/*****************************************************************************
 * VLCFileServerSectionTableHeaderView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Carola Nitz <caro # videolan.org>

 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc protocol VLCFileServerSectionTableHeaderViewDelegate: NSObjectProtocol {

    func connectToServer()
}

class VLCFileServerSectionTableHeaderView: VLCSectionTableHeaderView {

    @objc static let identifier = "VLCFileServerSectionTableHeaderView"
    @objc weak var delegate: VLCFileServerSectionTableHeaderViewDelegate?

    override func setupUI() {
        super.setupUI()

        let connectButton = UIButton(type: .system)
        connectButton.setTitle(NSLocalizedString("CONNECT", comment: ""), for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        connectButton.titleLabel?.textColor = PresentationTheme.current.colors.orangeUI
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.addTarget(self, action: #selector(connectButtonDidPress), for: .touchUpInside)
        contentView.addSubview(connectButton)

        NSLayoutConstraint.activate([
            connectButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            connectButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
    }

    @objc func connectButtonDidPress() {
        delegate?.connectToServer()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.textLabel?.text = NSLocalizedString("FILE_SERVER", comment: "")
    }
}
