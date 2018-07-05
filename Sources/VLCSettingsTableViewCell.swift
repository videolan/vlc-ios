/*****************************************************************************
 * VLCSettingsTableViewCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class VLCSettingsTableViewCell: UITableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()
        setupCell()
    }
    
    fileprivate func setupCell() {
        backgroundColor = PresentationTheme.current.colors.background
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        detailTextLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }
    
    @objc static func cell(identifier: String, target: IASKAppSettingsViewController) -> VLCSettingsTableViewCell? {
        let cell = VLCSettingsTableViewCell(style: .subtitle, reuseIdentifier: identifier)
        cell.setupCell()
        
        switch identifier {
        case kIASKPSToggleSwitchSpecifier:
            let toggle = IASKSwitch(frame: .zero)
            toggle.addTarget(target, action: #selector(target.toggledValue(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        case kIASKOpenURLSpecifier, kIASKPSMultiValueSpecifier:
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        default:
            assertionFailure("\(identifier) has not been defined for VLCSettingsTableViewCell")
        }
        
        return cell
    }
    
    @objc func configure(specifier: IASKSpecifier, value: Any?) {
        textLabel?.text = specifier.title()
        
        switch specifier.type() {
        case kIASKPSToggleSwitchSpecifier:
            configureToggle(specifier, value)
        case kIASKPSMultiValueSpecifier:
            configureMultiValue(specifier, value)
        case kIASKOpenURLSpecifier:
            configureOpenURL(specifier)
        default:
            assertionFailure("\(specifier.type()) has not been defined for VLCSettingsTableViewCell")
        }
    }
    
    fileprivate func configureToggle(_ specifier: IASKSpecifier, _ value: Any?) {
        detailTextLabel?.text = specifier.subtitle()
        
        var state: Bool
        if let currentValue = value as? Bool {
            switch currentValue {
            case specifier.trueValue() as? Bool:
                state = true
            case specifier.falseValue() as? Bool:
                state = false
            default:
                state = currentValue
            }
        } else {
            state = specifier.defaultBoolValue()
        }
        
        if let toggle = accessoryView as? IASKSwitch {
            toggle.isOn = state
            toggle.key = specifier.key()
        }
    }
    
    fileprivate func configureMultiValue(_ specifier: IASKSpecifier, _ value: Any?) {
        if let currentValue = value {
            detailTextLabel?.text = specifier.title(forCurrentValue: currentValue)
        } else {
            detailTextLabel?.text = specifier.title(forCurrentValue: specifier.defaultValue())
        }
    }
    
    fileprivate func configureOpenURL(_ specifier: IASKSpecifier) {
        detailTextLabel?.text = specifier.subtitle()
    }
}
