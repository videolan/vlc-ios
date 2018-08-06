/*****************************************************************************
 * VLCEditController.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// datasource to fill the cells
// delegate to handle selection
protocol VLCEditControllerDataSource {
    func updateData(data: [AnyObject])
}

class VLCEditController: NSObject {

    private var dataSet = [AnyObject]()
    private let collectionView: UICollectionView

    private lazy var editToolbar: VLCEditToolbar = {
        //        let editToolbar = VLCEditToolbar(frame: CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 50))
        // Y needs to be auto generated maybe by data.count
        let editToolbar = VLCEditToolbar(frame: CGRect(x: 0, y: 550,
                                                       width: collectionView.frame.width, height: 50))
        editToolbar.isHidden = true
        return editToolbar
    }()

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView

        super.init()

        collectionView.addSubview(editToolbar)
        collectionView.bringSubview(toFront: editToolbar)
    }
}

extension VLCEditController: VLCEditControllerDataSource {
    func updateData(data: [AnyObject]) {
        dataSet = data
    }
}

extension VLCEditController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSet.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCMediaViewEditCell.identifier,
                                                         for: indexPath) as? VLCMediaViewEditCell {
            cell.titleLabel.text = "( ｀ー´)ノ"
            cell.subInfoLabel.text = "(-ω-、)"
            cell.sizeLabel.text = "|ω°•)"
            cell.thumbnailImageView.image = UIImage(named: "vlc-xmas")
            return cell
        }
        return UICollectionViewCell()
    }
}

extension VLCEditController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VLCMediaViewEditCell {
            cell.checkView.isEnabled = !cell.checkView.isEnabled
        }
    }
}

extension VLCEditController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentInset = collectionView.contentInset
        // FIXME: 5 should be cell padding, but not usable maybe static?
        let insetToRemove = contentInset.left + contentInset.right + (5 * 2)
        return CGSize(width: collectionView.frame.width - insetToRemove, height: VLCMediaViewEditCell.height)
    }
}
