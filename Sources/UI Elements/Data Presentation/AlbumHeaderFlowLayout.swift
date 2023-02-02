/*****************************************************************************
 * AlbumHeaderFlowLayout.swift
 *
 * Copyright © 2023 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AlbumHeaderLayout: UICollectionViewFlowLayout {
    // Zoom on the thumbnail when scrolling up
    // Whithout dragging the image down
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)

        layoutAttributes?.forEach({ (attributes) in
            if attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                guard let collectionView = collectionView else { return }

                let contentOffsetY = collectionView.contentOffset.y

                if contentOffsetY > 0 {
                    return
                }

                let width = attributes.frame.width
                let height = attributes.frame.height - contentOffsetY
                attributes.frame = CGRect(x: 0, y: contentOffsetY, width: width, height: height)
            }
        })

        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    func getHeaderSize(with width: CGFloat) -> CGSize {
        let isLandscape: Bool = UIDevice.current.orientation.isLandscape
        let headerHeight: CGFloat = isLandscape ? 250.0 : 350.0

        return CGSize(width: width, height: headerHeight)
    }
}
