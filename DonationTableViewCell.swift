/*****************************************************************************
 * DonationTableViewCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
import PassKit

class DonationTableViewCell: UITableViewCell {

    @objc var donationButton: UIButton!
    @objc static let cellIdentifier = "DonationTsbleViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupCell()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        updateTheme()
    }

    @objc func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        selectionStyle = .none
        donationButton = DonationButton()

        donationButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(donationButton)
        NSLayoutConstraint.activate([ donationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                                      donationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                                      donationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                                      donationButton.topAnchor.constraint(equalTo: contentView.topAnchor),
                                      ])
    }
}
