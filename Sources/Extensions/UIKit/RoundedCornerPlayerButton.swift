/*****************************************************************************
 * RoundedCornerPlayerButton.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

final class RoundedCornerPlayerButton: UIControl {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
        return label
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let chevronLabel: UILabel = {
        let label = UILabel()
        label.text = "›"
        label.font = .systemFont(ofSize: 22, weight: .regular)
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayTertiaryTextColor
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(showsChevron: Bool) {
        super.init(frame: .zero)
        setup(showsChevron: showsChevron)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(showsChevron: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        styleAsNeutralOverlayControl(cornerRadius: 16)

        iconView.isUserInteractionEnabled = false
        summaryLabel.isHidden = true

        addSubview(iconView)
        addSubview(textStack)

        var constraints: [NSLayoutConstraint] = [
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10),
        ]

        if showsChevron {
            chevronLabel.isUserInteractionEnabled = false
            addSubview(chevronLabel)
            constraints += [
                chevronLabel.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 8),
                chevronLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
                chevronLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            ]
        } else {
            constraints.append(textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14))
        }

        NSLayoutConstraint.activate(constraints)

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    func setIcon(systemName: String) {
        if #available(iOS 13.0, *) {
            iconView.image = UIImage(systemName: systemName)
        }
    }

    func update(title: String, summary: String? = nil) {
        titleLabel.text = title
        summaryLabel.text = summary
        summaryLabel.isHidden = (summary?.isEmpty ?? true)
        accessibilityLabel = title
        accessibilityValue = summary
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.6 : 1.0
        }
    }
}
