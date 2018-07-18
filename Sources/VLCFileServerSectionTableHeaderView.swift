/*****************************************************************************
 * VLCFileServerSectionTableHeaderView.swift
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
    var layoutConstraints: [NSLayoutConstraint]?
    lazy var connectButton: UIButton = {
        let connectButton = UIButton(type: .system)
        connectButton.setTitle(NSLocalizedString("BUTTON_CONNECT", comment: ""), for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        connectButton.titleLabel?.textColor = PresentationTheme.current.colors.orangeUI
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.addTarget(self, action: #selector(connectButtonDidPress), for: .touchUpInside)
        contentView.addSubview(connectButton)
        return connectButton
    }()

    override func setupUI() {
        super.setupUI()
        textLabel?.text = NSLocalizedString("FILE_SERVER", comment: "")
    }

    //Before layoutSubviews textlabel doesn't have a superview
    override func layoutSubviews() {
        super.layoutSubviews()
        if layoutConstraints == nil {
            layoutConstraints = [
                connectButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                connectButton.firstBaselineAnchor.constraint(equalTo: textLabel!.firstBaselineAnchor)
                ]
            NSLayoutConstraint.activate(layoutConstraints!)
        }
    }
    @objc func connectButtonDidPress() {
        delegate?.connectToServer()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        //Text gets set to nil in prepareForReuse so we set it again
        textLabel?.text = NSLocalizedString("FILE_SERVER", comment: "")
    }
}
