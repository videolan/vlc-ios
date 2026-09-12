/*****************************************************************************
 * CollectionArtworkHeaderFlowLayout.swift
 *
 * Copyright © 2023 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class CollectionArtworkHeaderLayout: UICollectionViewFlowLayout {
    // Zoom on the thumbnail when scrolling up
    // Whithout dragging the image down
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)

        layoutAttributes?.forEach({ (attributes) in
            guard attributes.representedElementKind == UICollectionView.elementKindSectionHeader,
                  let collectionView = collectionView else {
                return
            }

            // The artwork spans the display, the horizontal content inset only applies to the items.
            var frame = attributes.frame
            frame.origin.x = -collectionView.adjustedContentInset.left
            frame.size.width = collectionView.bounds.width

            let contentOffsetY = collectionView.contentOffset.y
            if contentOffsetY <= 0 {
                frame.origin.y = contentOffsetY
                frame.size.height -= contentOffsetY
            }

            attributes.frame = frame
        })

        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    func getHeaderSize(with width: CGFloat) -> CGSize {
#if os(iOS)
        let bounds: CGRect = collectionView?.bounds ?? .zero
        let isWide: Bool = bounds.height > 0 && bounds.width > bounds.height
        let headerHeight: CGFloat = isWide ? 160.0 : 260.0
#else
        let headerHeight: CGFloat = 260.0
#endif

        return CGSize(width: width, height: headerHeight)
    }
}
