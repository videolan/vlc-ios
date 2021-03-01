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
    private let closeButton = UIButton()
    private let scrollView = UIScrollView()

    public var delegate: ActionSheetPopupViewDelegate?

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

    // MARK: - Setup

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 20

        setupScrollView()
        setupCloseButton()

        themeDidChange()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.layer.cornerRadius = 12

        let newConstraints = [
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        ]
        NSLayoutConstraint.activate(newConstraints)
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        let newConstraints = [
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
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
}

// MARK: - ActionSheetPopupViewDelegate

protocol ActionSheetPopupViewDelegate {
    func actionSheetPopupViewDidClose(_ actionSheetPopupView: ActionSheetPopupView)
}
