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

    private static let itemWidth: CGFloat = 148
    private static let itemHeight: CGFloat = 148 + 8 + 16 + 15

    var episodes: [PodcastEpisode] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var onSelectEpisode: ((PodcastEpisode) -> Void)?

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Self.itemWidth, height: Self.itemHeight)
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
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: Self.itemHeight)
        ])
    }
}

extension ContinueListeningSectionCell: UICollectionViewDataSource, UICollectionViewDelegate {
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectEpisode?(episodes[indexPath.item])
    }
}
