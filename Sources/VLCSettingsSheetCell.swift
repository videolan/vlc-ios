/*****************************************************************************
 * VLCSettingSheetCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCSettingsSheetCell: ActionSheetCell {

    override var isSelected: Bool {
        didSet {
            let colors = PresentationTheme.current.colors
            name.textColor = isSelected ? colors.orangeUI : colors.cellTextColor
            tintColor = isSelected ? colors.orangeUI : colors.cellDetailTextColor
            checkmark.isHidden = !isSelected
        }
    }
    
    let checkmark: UILabel = {
        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.systemFont(ofSize: 18)
        checkmark.textColor = PresentationTheme.current.colors.orangeUI
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.isHidden = true
        return checkmark
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.removeArrangedSubview(icon)
        stackView.addArrangedSubview(checkmark)
    }
}
