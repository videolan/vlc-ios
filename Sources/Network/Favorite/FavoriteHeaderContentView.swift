/*****************************************************************************
 * FavoriteHeaderContentView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Rizky Maulana <mrizky9601@gmail.com>
 *          Eshan Singh <eeeshan789@icloud.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

protocol FavoriteSectionHeaderDelegate {
    func renameSection(sectionIndex: NSInteger)
    func reloadData()
}

class FavoriteHeaderContentView: UIView {
    var delegate: FavoriteSectionHeaderDelegate?
    var section: Int = -1
    
    lazy var hostnameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let fontSize: CGFloat
        let textColor: UIColor
        #if os(iOS)
        fontSize = 16
        label.textColor = PresentationTheme.current.colors.cellTextColor
        #else
        fontSize = 50
        #endif
        label.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return label
    }()
    
    lazy var renameButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("BUTTON_RENAME", comment: ""), for: .normal)
        #if os(iOS)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(renameButtonAction(_:)), for: .touchUpInside)
        button.setTitleColor(UIColor.orange, for: .normal)
        #else
        button.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        button.addTarget(self, action: #selector(renameButtonAction(_:)), for: .primaryActionTriggered)
        button.setTitleColor(UIColor.orange, for: .focused)
        #endif
        return button
    }()
    
    #if os(tvOS)
    var buttonPadding: CGFloat = 50
    #else
    var buttonPadding: CGFloat = 20
    #endif
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
         renameButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -buttonPadding),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func renameButtonAction(_ sender: UIButton) {
        delegate?.renameSection(sectionIndex: self.section)
    }
}

extension FavoriteSectionHeaderDelegate where Self: UIViewController {
    func renameSection(sectionIndex: NSInteger) {
        let favoriteService = VLCAppCoordinator.sharedInstance().favoriteService
        let previousName = favoriteService.nameOfFavoritedServer(at: sectionIndex)

        let alertController = UIAlertController(title: NSLocalizedString("BUTTON_RENAME", comment: ""),
                                                message: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), previousName),
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = previousName
        }
        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                         style: .cancel)
        let confirmAction = UIAlertAction(title:  NSLocalizedString("BUTTON_RENAME", comment: ""),
                                          style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let alertTextField = alertController.textFields?.first else {
                return
            }
            guard let textfieldValue = alertTextField.text else {
                return
            }
            favoriteService.setName(textfieldValue, ofFavoritedServerAt: sectionIndex)
            self.reloadData()
        }

        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)

        present(alertController, animated: true)
    }
}
