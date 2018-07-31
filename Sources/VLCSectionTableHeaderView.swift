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
    
    @objc let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = PresentationTheme.current.font.tableHeaderFont
        return label
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

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
        stackView.addArrangedSubview(separator)
        stackView.addArrangedSubview(label)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9),
            
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @objc func updateTheme() {
        contentView.backgroundColor = PresentationTheme.current.colors.background
        separator.backgroundColor = PresentationTheme.current.colors.separatorColor
        label.textColor = PresentationTheme.current.colors.cellTextColor
    }
}
