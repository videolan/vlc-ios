/*****************************************************************************
 * PlayerControlGroupView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

final class PlayerControlGroupView: UIView {
    static let itemSize: CGFloat = 44
    static let dimmedAlpha: CGFloat = 0.45
    private static let horizontalPadding: CGFloat = 4

    private let background = VideoControlBackgroundView()
    private let itemRow: UIStackView

    init(arrangedSubviews: [UIView]) {
        itemRow = UIStackView(arrangedSubviews: arrangedSubviews)
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        background.isUserInteractionEnabled = false
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)

        itemRow.axis = .horizontal
        itemRow.alignment = .center
        itemRow.semanticContentAttribute = .forceLeftToRight
        itemRow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(itemRow)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            itemRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PlayerControlGroupView.horizontalPadding),
            itemRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PlayerControlGroupView.horizontalPadding),
            itemRow.topAnchor.constraint(equalTo: topAnchor),
            itemRow.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: PlayerControlGroupView.itemSize),
        ])
        itemRow.arrangedSubviews.forEach(constrainItem)
    }

    func addArrangedSubview(_ view: UIView) {
        itemRow.addArrangedSubview(view)
        constrainItem(view)
    }

    private func constrainItem(_ item: UIView) {
        item.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = item.widthAnchor.constraint(equalToConstant: PlayerControlGroupView.itemSize)
        widthConstraint.priority = .required - 1
        NSLayoutConstraint.activate([
            widthConstraint,
            item.heightAnchor.constraint(equalToConstant: PlayerControlGroupView.itemSize),
        ])
    }

    /// Call inside an animation block; keep this view and its ancestors at alpha 1.
    func setVisible(_ visible: Bool, dimmed: Bool = false) {
        isUserInteractionEnabled = visible
        accessibilityElementsHidden = !visible
        itemRow.alpha = visible ? (dimmed ? PlayerControlGroupView.dimmedAlpha : 1) : 0
        background.setVisible(visible)
    }
}
