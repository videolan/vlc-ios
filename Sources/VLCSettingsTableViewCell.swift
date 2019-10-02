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
    
    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        selectedBackgroundView?.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        textLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        detailTextLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    @objc init(reuseIdentifier: String, target: IASKAppSettingsViewController) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
        
        switch reuseIdentifier {
        case kIASKPSToggleSwitchSpecifier:
            let toggle = IASKSwitch(frame: .zero)
            toggle.addTarget(target, action: #selector(target.toggledValue(_:)), for: .valueChanged)
            accessoryView = toggle
        case kIASKOpenURLSpecifier:
            accessoryType = .disclosureIndicator
        case kIASKPSMultiValueSpecifier:
            accessoryType = .none
        case kIASKButtonSpecifier:
            accessoryType = .none
        default:
            assertionFailure("\(reuseIdentifier) has not been defined for VLCSettingsTableViewCell")
        }
    }

    @available(*, unavailable, message: "use init(reuseIdentifier: String)")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

     @objc func configure(specifier: IASKSpecifier, settingsValue: Any?) {
        textLabel?.text = specifier.title()
        textLabel?.numberOfLines = 0
        detailTextLabel?.text = specifier.subtitle()

        switch specifier.type() {
        case kIASKPSToggleSwitchSpecifier:
            configureToggle(specifier, settingsValue)
        case kIASKPSMultiValueSpecifier:
            configureMultiValue(specifier, settingsValue)
        case kIASKOpenURLSpecifier:
            break
        case kIASKButtonSpecifier:
            break
        default:
            assertionFailure("\(specifier.type() ?? "nil") has not been defined for VLCSettingsTableViewCell")
        }
    }
    
    fileprivate func configureToggle(_ specifier: IASKSpecifier, _ settingsValue: Any?) {
        assert(specifier.type() == kIASKPSToggleSwitchSpecifier, "configureToggle should only be called for kIASKPSToggleSwitchSpecifier")
        assert(settingsValue is Bool?, "settingsValue should be Bool?")
        assert(accessoryView is IASKSwitch, "the accessory should be a switch")

        var state = specifier.defaultBoolValue()
        if let currentValue = settingsValue as? Bool {
            switch currentValue {
            case specifier.trueValue() as? Bool:
                state = true
            case specifier.falseValue() as? Bool:
                state = false
            default:
                state = currentValue
            }
        }

        if let toggle = accessoryView as? IASKSwitch {
            toggle.isOn = state
            toggle.key = specifier.key()
        }

        selectionStyle = .none
    }
    
    fileprivate func configureMultiValue(_ specifier: IASKSpecifier, _ value: Any?) {
        assert(specifier.type() == kIASKPSMultiValueSpecifier, "configureMultiValue should only be called for kIASKPSMultiValueSpecifier")

        detailTextLabel?.text = specifier.title(forCurrentValue: value ?? specifier.defaultValue())
    }
}
