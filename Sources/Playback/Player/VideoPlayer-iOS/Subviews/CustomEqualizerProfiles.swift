/*****************************************************************************
* EqualizerView.swift
*
* Copyright © 2020 VLC authors and VideoLAN
*
* Authors: Diogo Simao Marques <dogo@videolabs.io>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

// MARK: - MoveEventIdentifier

enum MoveEventIdentifier: Int {
    case up = 1
    case down
}

// MARK: - EqualizerEditActionsIdentifier

@objc enum EqualizerEditActionsIdentifier: Int {
    case rename = 1
    case delete
}

// MARK: - CustomEqualizerProfile

class CustomEqualizerProfile: NSObject, NSCoding {
    var name: String
    var preAmpLevel: Float
    var frequencies: [Float]

    init(name: String, preAmpLevel: Float, frequencies: [Float]) {
        self.name = name
        self.preAmpLevel = preAmpLevel
        self.frequencies = frequencies
    }

    required init?(coder: NSCoder) {
        guard let name = coder.decodeObject(forKey: "name") as? String,
              let frequencies = coder.decodeObject(forKey: "frequencies") as? [Float] else {
            self.name = ""
            self.preAmpLevel = 6.0
            self.frequencies = []
            return
        }

        self.name = name
        self.preAmpLevel = coder.decodeFloat(forKey: "preAmpLevel")
        self.frequencies = frequencies
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(preAmpLevel, forKey: "preAmpLevel")
        coder.encode(frequencies, forKey: "frequencies")
    }
}

// MARK: - CustomEqualizerProfiles

class CustomEqualizerProfiles: NSObject, NSCoding {
    var profiles: [CustomEqualizerProfile]

    required init?(coder: NSCoder) {
        guard let customProfiles = coder.decodeObject(forKey: "profiles") as? [CustomEqualizerProfile] else {
            self.profiles = []
            return
        }

        self.profiles = customProfiles
    }

    init(profiles: [CustomEqualizerProfile]) {
        self.profiles = profiles
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.profiles, forKey: "profiles")
    }

    func moveUp(index: Int) {
        guard index - 1 >= 0 else {
            return
        }

        profiles.swapAt(index, index - 1)

        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: kVLCCustomProfileEnabled) {
            let currentProfileIndex = userDefaults.integer(forKey: kVLCSettingEqualizerProfile)

            if currentProfileIndex == index {
                userDefaults.setValue(index - 1, forKeyPath: kVLCSettingEqualizerProfile)
            } else if currentProfileIndex == index - 1 {
                userDefaults.setValue(index, forKey: kVLCSettingEqualizerProfile)
            }
        }
    }

    func moveDown(index: Int) {
        guard index + 1 < profiles.count else {
            return
        }

        profiles.swapAt(index, index + 1)

        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: kVLCCustomProfileEnabled) {
            let currentProfileIndex = userDefaults.integer(forKey: kVLCSettingEqualizerProfile)

            if currentProfileIndex == index {
                userDefaults.setValue(index + 1, forKeyPath: kVLCSettingEqualizerProfile)
            } else if currentProfileIndex == index + 1 {
                userDefaults.setValue(index, forKey: kVLCSettingEqualizerProfile)
            }
        }
    }
}
