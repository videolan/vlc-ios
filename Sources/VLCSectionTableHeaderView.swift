/*****************************************************************************
 * VLCSectionTableHeaderView.m
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

class VLCSectionTableHeaderView: UITableViewHeaderFooterView {

    let separator = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        setupUI()
        updateTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.topAnchor.constraint(equalTo: contentView.topAnchor)
            ])
    }

    @objc func updateTheme() {
        contentView.backgroundColor = PresentationTheme.current.colors.background
        separator.backgroundColor = PresentationTheme.current.colors.separatorColor
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
    }
}
