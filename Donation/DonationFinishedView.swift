/*****************************************************************************
 * DonationFinishedView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class DonationFinishedView: UIStackView {

    let titleLabel = UILabel(frame: .zero)
    let descriptionLabel = UILabel(frame: .zero)
    let coneImageView = UIImageView(image: UIImage(named: "coneImage"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        updateTheme()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addArrangedSubview(coneImageView)
        addArrangedSubview(titleLabel)
        addArrangedSubview(descriptionLabel)
        axis = .vertical
        translatesAutoresizingMaskIntoConstraints = false
        spacing = 10.0
        contentMode = .scaleAspectFit
        layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        layoutIfNeeded()
        coneImageView.contentMode = .scaleAspectFit

        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.text = NSLocalizedString("THANKS", comment: "")

        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .systemFont(ofSize: 17)
        descriptionLabel.text = NSLocalizedString("THANKS_DESCRIPTION", comment: "")
    }

    @objc func updateTheme() {
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel.textColor = PresentationTheme.current.colors.cellTextColor
    }
}
