/*****************************************************************************
 * ContinueListeningSectionCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class ContinueListeningSectionCell: UITableViewCell {
    static let reuseIdentifier = "ContinueListeningSectionCell"

    private static let textAreaHeight: CGFloat = 8 + 16 + 15
    private static let verticalPadding: CGFloat = 4

    static func height(forWidth width: CGFloat) -> CGFloat {
        return tileWidth(forWidth: width) + textAreaHeight + 2 * verticalPadding
    }

    private static func tileWidth(forWidth width: CGFloat) -> CGFloat {
        let columns = VLCRadioFavoritesGridCell.columns(forWidth: width)
        return VLCRadioFavoritesGridCell.tileWidth(forWidth: width, columns: columns)
    }

    var episodes: [PodcastEpisode] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var onSelectEpisode: ((PodcastEpisode) -> Void)?

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ContinueListeningCarouselCell.self,
                                 forCellWithReuseIdentifier: ContinueListeningCarouselCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.verticalPadding),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalPadding),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
}

extension ContinueListeningSectionCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContinueListeningCarouselCell.reuseIdentifier,
                                                             for: indexPath) as? ContinueListeningCarouselCell else {
            return UICollectionViewCell()
        }
        let episode = episodes[indexPath.item]
        cell.configure(episode: episode, show: PodcastStore.shared.show(withId: episode.showId))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tileWidth = Self.tileWidth(forWidth: collectionView.bounds.width)
        return CGSize(width: tileWidth, height: tileWidth + Self.textAreaHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectEpisode?(episodes[indexPath.item])
    }
}
