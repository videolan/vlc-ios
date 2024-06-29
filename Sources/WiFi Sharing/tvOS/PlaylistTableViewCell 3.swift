//
//  PlaylistTableViewCell.swift
//  VLC-tvOS
//
//  Created by Eshan Singh on 07/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var playlistDuration: UILabel!
    @IBOutlet weak var playlistThumbnail: UIImageView!
    @IBOutlet weak var playlistTracks: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .disclosureIndicator
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
    var playlist: VLCMLPlaylist? {
        didSet {
            if let playlist = playlist {
                let duration = formattedDuration(from: playlist.duration())
                playlistDuration.text = duration
                playlistTitle.text = playlist.title()
                playlistTitle.textColor = .systemOrange
                playlistThumbnail.image = playlist.thumbnailImage()
                playlistTracks.text = playlist.numberOfTracksString()
            }
        }
    }
    
    override func prepareForReuse() {
        playlistTitle.text = ""
        playlistDuration.text = ""
        playlistThumbnail.image = nil
    }
    
    func formattedDuration(from seconds: Int64) -> String {
        let duration = VLCTime(number: NSNumber(value: seconds))
        return String(format: "%@", duration)
    }
}
