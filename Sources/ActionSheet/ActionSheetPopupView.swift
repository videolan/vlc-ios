/*****************************************************************************
* ActionSheetPopupView.swift
*
* Copyright © 2021 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

// MARK: - Class

class ActionSheetPopupView: UIView {
    private let titleStackView = UIStackView()
    private let closeButton = UIButton()
    let titleLabel = UILabel()
    private let scrollView = UIScrollView()

    private lazy var titleStackViewTopConstraint: NSLayoutConstraint = {
        return titleStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20)
    }()

    private lazy var scrollViewTopConstraint: NSLayoutConstraint = {
        scrollView.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 10)
    }()

    private lazy var scrollViewBottomConstraint: NSLayoutConstraint = {
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    }()

    public var delegate: ActionSheetPopupViewDelegate?
    public var accessoryViewsDelegate: ActionSheetPopupViewAccessoryViewsDelegate? {
        didSet {
            addAccessoryViews()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Override methods

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.flashScrollIndicatorsIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.verticalSizeClass == .compact {
            titleStackViewTopConstraint.constant = 15
            scrollViewTopConstraint.constant = 5
            scrollViewBottomConstraint.constant = -5
        } else {
            titleStackViewTopConstraint.constant = 20
            scrollViewTopConstraint.constant = 10
            scrollViewBottomConstraint.constant = -10
        }
        layoutSubviews()
    }

    // MARK: - Setup

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 20

        setupTitleStackView()
        setupScrollView()
        setupConstraints()

        themeDidChange()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func setupTitleStackView() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.layer.cornerRadius = 12
        closeButton.setContentHuggingPriority(.required, for: .vertical)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: titleLabel.font.pointSize)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.distribution = .fill
        titleStackView.spacing = 20
        titleStackView.addArrangedSubview(closeButton)
        titleStackView.addArrangedSubview(titleLabel)
        addSubview(titleStackView)
    }

    private func addAccessoryViews() {
        if let accessoryViews = accessoryViewsDelegate?.actionSheetPopupViewAccessoryView(self) {
            for accessoryView in accessoryViews {
                titleStackView.addArrangedSubview(accessoryView)
            }
        }
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
    }

    private func setupConstraints() {
        let newConstraints = [
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),

            titleStackViewTopConstraint,
            titleStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            scrollViewTopConstraint,
            scrollViewBottomConstraint,
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(newConstraints)
    }

    // MARK: - Event handlers

    @objc private func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        closeButton.tintColor = PresentationTheme.current.colors.cellTextColor
        closeButton.backgroundColor = PresentationTheme.current.colors.background
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
    }

    @objc private func close() {
        removeFromSuperview()
        delegate?.actionSheetPopupViewDidClose(self)
    }
}

// MARK: - Public methods

extension ActionSheetPopupView {
    func addContentView(_ contentView: UIView, constraintWidth: Bool = false, constraintHeight: Bool = false) {
        scrollView.addSubview(contentView)

        var newConstraints = [
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        ]
        if constraintWidth {
            newConstraints.append(contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor))
            scrollView.showsHorizontalScrollIndicator = false
        }
        if constraintHeight {
            newConstraints.append(contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor))
            scrollView.showsVerticalScrollIndicator = false
        }
        newConstraints.append(contentsOf: [
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        ])
        NSLayoutConstraint.activate(newConstraints)
    }

    func updateAccessoryViews() {
        while titleStackView.arrangedSubviews.count > 2 {
            if let subview = titleStackView.arrangedSubviews.last {
                titleStackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
        }
        addAccessoryViews()
        titleStackView.layoutSubviews()
    }
}

// MARK: - ActionSheetPopupViewDelegate

protocol ActionSheetPopupViewDelegate {
    func actionSheetPopupViewDidClose(_ actionSheetPopupView: ActionSheetPopupView)
}

protocol ActionSheetPopupViewAccessoryViewsDelegate {
    func actionSheetPopupViewAccessoryView(_ actionSheetPopupView: ActionSheetPopupView) -> [UIView]
}
