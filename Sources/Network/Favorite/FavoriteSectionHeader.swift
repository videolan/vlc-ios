//
//  FavoriteSectionHeader.swift
//  VLC-iOS
//
//  Created by Rizky Maulana on 14/07/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import UIKit

protocol FavoriteSectionHeaderDelegate {
    func renameSection(with oldTitle: String)
}

class FavoriteSectionHeader: UITableViewHeaderFooterView {
    static let identifier = "FavoriteSectionHeader"
    static let height: CGFloat = 40
    var delegate: FavoriteSectionHeaderDelegate?
    
    lazy var hostnameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = PresentationTheme.current.colors.cellDetailTextColor
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    lazy var renameButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Rename", for: .normal)
        button.setTitleColor(UIColor.orange, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(renameButtonDidPress), for: .touchUpInside)

        return button
    }()
    
    var buttonPadding: CGFloat = 20

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(renameButton)
        addSubview(hostnameLabel)
        var guide: LayoutAnchorContainer = self
        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        
        NSLayoutConstraint.activate([
            hostnameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            hostnameLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: buttonPadding),
            renameButton.firstBaselineAnchor.constraint(equalTo: hostnameLabel.firstBaselineAnchor),
            renameButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -buttonPadding)
        ])
    }
    
    @objc func clickView(_ sender: UIView) {
        print("You clicked on view")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func renameButtonDidPress(_ sender: UIButton) {
        guard let oldTitle = hostnameLabel.text else { return }
        delegate?.renameSection(with: oldTitle)
    }
}
