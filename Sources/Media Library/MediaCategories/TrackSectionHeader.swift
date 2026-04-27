/*****************************************************************************
 * TrackSeciton Header.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com.>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class TrackSectionHeader: UICollectionReusableView {

    static var headerID = "trackSectionHeaderID"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = PresentationTheme.current.colors.orangeUI
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var dividerView: UIView = {
        let dividerView = UIView(frame: .zero)
        dividerView.backgroundColor = PresentationTheme.current.colors.separatorColor
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        return dividerView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(dividerView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)

        updateTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(sectionTitle: String) {
        titleLabel.text = sectionTitle
    }

    @objc private func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        dividerView.backgroundColor = PresentationTheme.current.colors.separatorColor
    }
}

public enum SectionType: Int {
    case special = 0
    case latin = 1
    case nonlatin = 2
}
