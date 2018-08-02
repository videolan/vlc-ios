/*****************************************************************************
 * VLCEditToolbar.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol VLCEditToolbarDelegate: class {
    func delete()
    func createPlaylist()
    func rename()
}

// Decided to use a UIView instead of UIToolbar because we have more freedom
// FIXME: Basic structure without UI
class VLCEditToolbar: UIView {
    weak var delegate: VLCEditToolbarDelegate?

    @objc func createFolder() {
        delegate?.createPlaylist()
    }

    @objc func deleteSelection() {
        delegate?.delete()
    }

    @objc func renameSelection() {
        delegate?.rename()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
