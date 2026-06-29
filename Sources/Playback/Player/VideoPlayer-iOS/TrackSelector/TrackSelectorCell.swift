/*****************************************************************************
 * TrackSelectorCell.swift
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

protocol TrackSelectorCellDelegate: AnyObject {
    func trackSelectorCellDidTogglePrimary(_ cell: TrackSelectorCell)
    func trackSelectorCellDidToggleSecondary(_ cell: TrackSelectorCell)
}

enum TrackSelectorAssignment {
    case none
    case primary
    case secondary
}

final class TrackSelectorCell: UITableViewCell {
    static let identifier = "TrackSelectorCell"

    weak var delegate: TrackSelectorCellDelegate?

    private let checkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "checkmark"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var primaryPill = makePill(title: "1", action: #selector(didTapPrimaryPill))
    private lazy var secondaryPill = makePill(title: "2", action: #selector(didTapSecondaryPill))

    private let selectionCapsule: UIView = {
        let view = UIView()
        view.roundCorners(radius: 12)
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var labelTrailingToContent: NSLayoutConstraint!
    private var labelTrailingToPills: NSLayoutConstraint!
    private var labelLeadingWithCheck: NSLayoutConstraint!
    private var labelLeadingNoCheck: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        metaLabel.text = nil
        delegate = nil
    }

    private func setupView() {
        backgroundColor = .clear
        selectionStyle = .none

        let labelStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(selectionCapsule)
        contentView.addSubview(checkImageView)
        contentView.addSubview(labelStack)
        contentView.addSubview(primaryPill)
        contentView.addSubview(secondaryPill)

        NSLayoutConstraint.activate([
            selectionCapsule.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            selectionCapsule.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            selectionCapsule.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            selectionCapsule.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),

            checkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkImageView.widthAnchor.constraint(equalToConstant: 22),
            checkImageView.heightAnchor.constraint(equalToConstant: 22),

            labelStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            labelStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            labelStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            secondaryPill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            secondaryPill.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            primaryPill.trailingAnchor.constraint(equalTo: secondaryPill.leadingAnchor, constant: -8),
            primaryPill.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        labelLeadingWithCheck = labelStack.leadingAnchor.constraint(equalTo: checkImageView.trailingAnchor, constant: 12)
        labelLeadingNoCheck = labelStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18)
        labelTrailingToContent = labelStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18)
        labelTrailingToPills = labelStack.trailingAnchor.constraint(equalTo: primaryPill.leadingAnchor, constant: -12)
        labelLeadingWithCheck.isActive = true
        labelTrailingToContent.isActive = true
    }

    private func makePill(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .heavy)
        button.roundCorners(radius: 11)
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34),
        ])
        return button
    }

    func configure(row: TrackSelectorRow, dualMode: Bool, assignment: TrackSelectorAssignment) {
        let colors = PresentationTheme.currentExcludingWhite.colors
        nameLabel.text = row.name
        nameLabel.textColor = row.isDerivedName ? colors.overlaySecondaryTextColor
                                                : colors.overlayPrimaryTextColor
        metaLabel.text = row.meta
        metaLabel.isHidden = (row.meta == nil)

        primaryPill.isHidden = !dualMode
        secondaryPill.isHidden = !dualMode
        labelTrailingToPills.isActive = dualMode
        labelTrailingToContent.isActive = !dualMode
        labelLeadingNoCheck.isActive = dualMode
        labelLeadingWithCheck.isActive = !dualMode

        if dualMode {
            checkImageView.isHidden = true
            stylePill(primaryPill, kind: .primary, active: assignment == .primary, colors: colors)
            stylePill(secondaryPill, kind: .secondary, active: assignment == .secondary, colors: colors)
            selectionCapsule.backgroundColor = .clear
            selectionCapsule.layer.borderWidth = 0
        } else {
            checkImageView.isHidden = !row.isSelected
            if row.isSelected {
                selectionCapsule.backgroundColor = colors.selectionAccent.withAlphaComponent(0.28)
                selectionCapsule.layer.borderWidth = 1
                selectionCapsule.layer.borderColor = colors.orangeUI.withAlphaComponent(0.65).cgColor
            } else {
                selectionCapsule.backgroundColor = .clear
                selectionCapsule.layer.borderWidth = 0
            }
        }
        updateAccessibility(row: row, dualMode: dualMode, assignment: assignment)
    }

    private func stylePill(_ pill: UIButton, kind: TrackSelectorAssignment, active: Bool, colors: ColorPalette) {
        let accent = (kind == .primary) ? colors.orangeUI : colors.secondarySubtitleAccent
        if active {
            pill.backgroundColor = accent
            pill.layer.borderColor = accent.cgColor
            pill.setTitleColor(colors.background, for: .normal)
        } else {
            pill.backgroundColor = colors.overlayControlFillColor
            pill.layer.borderColor = colors.overlayHairlineColor.cgColor
            pill.setTitleColor(colors.overlaySecondaryTextColor, for: .normal)
        }
    }

    private func updateAccessibility(row: TrackSelectorRow, dualMode: Bool, assignment: TrackSelectorAssignment) {
        isAccessibilityElement = true
        accessibilityLabel = [row.name, row.meta].compactMap { $0 }.joined(separator: ", ")
        if dualMode {
            switch assignment {
            case .primary:
                accessibilityValue = NSLocalizedString("SUBTITLE_ASSIGN_PRIMARY", comment: "")
            case .secondary:
                accessibilityValue = NSLocalizedString("SUBTITLE_ASSIGN_SECONDARY", comment: "")
            case .none:
                accessibilityValue = nil
            }
        } else {
            accessibilityValue = row.isSelected ? NSLocalizedString("ACCESSIBILITY_SELECTED", comment: "") : nil
        }
    }

    @objc private func didTapPrimaryPill() {
        delegate?.trackSelectorCellDidTogglePrimary(self)
    }

    @objc private func didTapSecondaryPill() {
        delegate?.trackSelectorCellDidToggleSecondary(self)
    }
}

// MARK: - Row model

enum TrackKind {
    case audio
    case subtitle
}

struct TrackSelectorRow {
    let trackIndex: Int
    let name: String
    let isDerivedName: Bool
    let meta: String?
    var isSelected: Bool
}

extension TrackSelectorRow {
    init(track: VLCMediaPlayer.Track, ordinal: Int, kind: TrackKind) {
        let (name, derived) = track.displayName(ordinal: ordinal)
        trackIndex = ordinal - 1
        self.name = name
        isDerivedName = derived
        meta = track.metaSummary(kind: kind)
        isSelected = false
    }
}

private extension VLCMediaPlayer.Track {
    func displayName(ordinal: Int) -> (String, Bool) {
        if !trackName.trimmingCharacters(in: .whitespaces).isEmpty {
            return (trackName, false)
        }
        if let language = language,
           let localized = Locale.current.localizedString(forLanguageCode: language),
           !localized.isEmpty {
            return (localized, false)
        }
        let fallback = String(format: NSLocalizedString("TRACK_INDEX_FORMAT", comment: ""), ordinal)
        return (fallback, true)
    }

    func metaSummary(kind: TrackKind) -> String? {
        func channelLabel(_ channels: UInt32) -> String {
            switch channels {
            case 1:
                return NSLocalizedString("AUDIO_CHANNELS_MONO", comment: "")
            case 2:
                return NSLocalizedString("AUDIO_CHANNELS_STEREO", comment: "")
            case 6:
                return "5.1"
            case 8:
                return "7.1"
            default:
                return String(format: NSLocalizedString("AUDIO_CHANNELS_FORMAT", comment: ""), channels)
            }
        }

        var components: [String] = []
        let codec = codecName()
        if !codec.isEmpty {
            components.append(codec)
        }
        if kind == .audio, let channels = audio?.channelsNumber, channels > 0 {
            components.append(channelLabel(channels))
        }
        return components.isEmpty ? nil : components.joined(separator: " · ")
    }
}
