/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objcMembers
class PlaybackSettings: NSObject, Codable {
    var repeatMode: VLCRepeatMode
    var shuffleMode: Bool
    var playbackSpeed: Float
    var aspectRatio: VLCAspectRatio

    private enum CodingKeys: String, CodingKey {
        case repeatMode
        case shuffleMode
        case playbackSpeed
        case aspectRatio
    }
    
    override init() {
        repeatMode = .doNotRepeat
        shuffleMode = false
        aspectRatio = .default
        let defaults = UserDefaults.standard
        if defaults.float(forKey: "playback-speed") != 0 {
            playbackSpeed = Float(defaults.float(forKey:"playback-speed"))
        } else {
            playbackSpeed = 1.0
        }
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        repeatMode = VLCRepeatMode(rawValue: try values.decode(NSInteger.self, forKey: .repeatMode)) ?? .doNotRepeat
        shuffleMode = try values.decode(Bool.self, forKey: .shuffleMode)
        playbackSpeed = try values.decode(Float.self, forKey: .playbackSpeed)
        aspectRatio = VLCAspectRatio(rawValue: VLCAspectRatio.RawValue(try values.decode(NSInteger.self, forKey: .aspectRatio))) ?? .default
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repeatMode.rawValue, forKey: .repeatMode)
        try container.encode(shuffleMode, forKey: .shuffleMode)
        try container.encode(playbackSpeed, forKey: .playbackSpeed)
        try container.encode(aspectRatio.rawValue, forKey: .aspectRatio)
    }

    func saveSettings() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: "savedPlaybackSettings")
        }
    }

    class func restoreSettings() -> PlaybackSettings? {
        if let savedSettings = UserDefaults.standard.object(forKey: "savedPlaybackSettings") as? Data {
            let decoder = JSONDecoder()
            if let loadedSettings = try? decoder.decode(PlaybackSettings.self, from: savedSettings) {
                return loadedSettings
            }
        }
        return nil
    }
}
