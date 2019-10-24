/*****************************************************************************
* CollectionViewCellPreviewController.swift
*
* Copyright © 2019 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

class CollectionViewCellPreviewController: UIViewController {
    var thumbnailView = UIImageView()

    override func loadView() {
        view = thumbnailView
    }

    init(thumbnail: UIImage) {
        super.init(nibName: nil, bundle: nil)

        thumbnailView.clipsToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.image = thumbnail

        let ratio = thumbnail.size.height / thumbnail.size.width
        let width = UIApplication.shared.keyWindow?.frame.width ?? 0
        let height = ratio * width
        preferredContentSize = CGSize(width: width, height: height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
