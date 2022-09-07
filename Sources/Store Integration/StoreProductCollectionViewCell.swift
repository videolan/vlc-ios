/*****************************************************************************
 * StoreProductCollectionViewCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 *
 * Authors:  Soomin Lee < bubu@mikan.io >
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


import UIKit

class StoreProductCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "StoreProductsCollectionViewCell"
    @IBOutlet private weak var mainStackView: UIStackView!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    override var isSelected: Bool {
        didSet {
            if isSelected {
                priceLabel.textColor = PresentationTheme.current.colors.orangeUI
                backgroundColor = PresentationTheme.current.colors.cellBackgroundB
            } else {
                priceLabel.textColor = PresentationTheme.current.colors.cellTextColor
                backgroundColor = PresentationTheme.current.colors.background
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        priceLabel.textColor = PresentationTheme.current.colors.cellTextColor
    }
}
