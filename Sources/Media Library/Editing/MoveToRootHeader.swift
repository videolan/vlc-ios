/*****************************************************************************
 * MoveToRootHeader.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol MoveToRootHeaderDelegate: AnyObject {
    func moveToRootHeader(didTapHeader header: MoveToRootHeader)
}

class MoveToRootHeader: UICollectionReusableView {

    static var headerID = "moveToRootHeaderID"

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "removeFromMediaGroup"))
        imageView.contentMode = .center
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("MEDIA_GROUP_MOVE_TO_ROOT", comment: "")
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        return label
    }()

    private lazy var container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.spacing = 8
        return stackView
    }()

    weak var delegate: MoveToRootHeaderDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = NSLocalizedString("MEDIA_GROUP_MOVE_TO_ROOT_HINT", comment: "")

        let tap = UITapGestureRecognizer(target: self, action:#selector(self.didTapHeader(_:)))
        self.addGestureRecognizer(tap)

        addSubview(container)

        container.addArrangedSubview(imageView)
        container.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            imageView.widthAnchor.constraint(equalToConstant: MediaCollectionViewCell.getDefaultConstant()),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTapHeader(_ sender: UITapGestureRecognizer) {
        delegate?.moveToRootHeader(didTapHeader: self)
    }
}
