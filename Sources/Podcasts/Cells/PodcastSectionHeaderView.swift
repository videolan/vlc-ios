/*****************************************************************************
 * PodcastSectionHeaderView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class PodcastSectionHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "PodcastSectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .title3).semibolded
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private let sortButton = PodcastSectionHeaderView.makeButton()
    private let actionButton = PodcastSectionHeaderView.makeButton()

    private static func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredCustomFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.isHidden = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func setupUI() {
        let background = UIView()
        backgroundView = background

        contentView.addSubview(titleLabel)
        contentView.addSubview(sortButton)
        contentView.addSubview(actionButton)

        let bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        bottomConstraint.priority = .init(999)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: sortButton.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            bottomConstraint,

            sortButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sortButton.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionButton.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    func configure(title: String) {
        titleLabel.text = title
        sortButton.isHidden = true
        actionButton.isHidden = true
    }

    func configure(title: String, actionTitle: String, tag: Int, target: Any, action: Selector) {
        titleLabel.text = title
        sortButton.isHidden = true
        actionButton.isHidden = false
        actionButton.tag = tag
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.removeTarget(nil, action: nil, for: .touchUpInside)
        actionButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func configure(title: String, sortTitle: String, sortMenu: UIMenu) {
        titleLabel.text = title
        actionButton.isHidden = true
        sortButton.isHidden = false
        sortButton.setTitle(sortTitle, for: .normal)
        sortButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        sortButton.semanticContentAttribute = .forceRightToLeft
        sortButton.accessibilityHint = NSLocalizedString("PODCAST_SORT_EPISODES_HINT", comment: "")
        sortButton.showsMenuAsPrimaryAction = true
        sortButton.menu = sortMenu
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        backgroundView?.backgroundColor = colors.background
        titleLabel.textColor = colors.cellTextColor
        sortButton.tintColor = colors.orangeUI
        actionButton.tintColor = colors.orangeUI
    }
}
