/*****************************************************************************
* AudioCollectionModel.swift
*
* Copyright © 2019 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation

protocol AudioCollectionModel: MLBaseModel { }

extension AudioCollectionModel {

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("AudioCollectionModel: Audio collections can not be deleted, they disappear when their last title got deleted")
    }
}
