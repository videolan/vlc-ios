/*****************************************************************************
 * SettingsHeaderFooterView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class SettingsHeaderView: UITableViewHeaderFooterView {

    private let notificationCenter = NotificationCenter.default
    private let containerView = UIView()
    let sectionHeaderLabel: UILabel = {
        let sectionHeaderLabel = UILabel()
        sectionHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionHeaderLabel.font = .systemFont(ofSize: 21, weight: .bold)
        sectionHeaderLabel.numberOfLines = 2
        return sectionHeaderLabel
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupObservers()
        setupView()
        themeDidChange()
    }

    private func setupView() {
        addSubview(containerView)
        addSubview(sectionHeaderLabel)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            sectionHeaderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            sectionHeaderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sectionHeaderLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.backgroundColor = .clear //Required to prevent theme mismatch during themeDidChange Notification
    }

    private func setupObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
    }

    @objc private func themeDidChange() {
        let colors = PresentationTheme.current.colors
        containerView.backgroundColor = colors.background
        sectionHeaderLabel.textColor = colors.cellTextColor
        sectionHeaderLabel.backgroundColor = colors.background
    }
}

class SettingsFooterView: UITableViewHeaderFooterView {

    private let notificationCenter = NotificationCenter.default
    private let footerView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupView()
        setupObserver()
    }

    private func setupView() {
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            footerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            footerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            footerView.heightAnchor.constraint(equalToConstant: 1.0),
        ])
    }

    private func setupObserver() {
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
    }

    @objc private func themeDidChange() {
        footerView.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
    }
}
