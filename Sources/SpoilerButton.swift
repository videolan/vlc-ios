/*****************************************************************************
* SpoilerButton.swift
*
* Copyright © 2021 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

class SpoilerButton: UIStackView {
    // MARK: - Properties
    private let buttonStackView = UIStackView()
    private let openButton = UIButton()
    private let chevronImage = UIButton()
    private var hiddenView: UIView? {
        didSet {
            setupViews()
        }
    }
    private var hiddenHeightConstraint: NSLayoutConstraint?
    private var shownHeightConstraint: NSLayoutConstraint?
    private var isOpened = false
    private var needsUpdateHiddenView = true
    var parent: UIView?

    private lazy var isRightToLeft: Bool = {
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Setup
    private func setupOpenButton() {
        openButton.addTarget(self, action: #selector(openButtonPressed), for: .touchUpInside)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setContentHuggingPriority(.required, for: .vertical)
        openButton.setContentHuggingPriority(.required, for: .horizontal)
        openButton.setTitleColor(PresentationTheme.current.colors.orangeUI, for: .normal)
        openButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        openButton.titleLabel?.lineBreakMode = .byWordWrapping
        openButton.titleLabel?.textAlignment = isRightToLeft ? .left : .right
        openButton.titleLabel?.numberOfLines = 0
        chevronImage.addTarget(self, action: #selector(openButtonPressed), for: .touchUpInside)
        chevronImage.translatesAutoresizingMaskIntoConstraints = false
        chevronImage.setContentHuggingPriority(.required, for: .vertical)
        chevronImage.setContentHuggingPriority(.required, for: .horizontal)
        chevronImage.tintColor = PresentationTheme.current.colors.orangeUI
        chevronImage.setImage(UIImage(named: "iconChevron")?.withRenderingMode(.alwaysTemplate), for: .normal)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.alignment = .fill
        buttonStackView.spacing = 5
        buttonStackView.addArrangedSubview(openButton)
        buttonStackView.addArrangedSubview(chevronImage)
    }

    private func setupViews() {
        if let hiddenView = hiddenView {
            setupOpenButton()
            hiddenView.translatesAutoresizingMaskIntoConstraints = false

            clipsToBounds = true
            translatesAutoresizingMaskIntoConstraints = false
            setContentHuggingPriority(.required, for: .vertical)
            axis = .vertical
            alignment = .center
            spacing = 10

            addArrangedSubview(buttonStackView)

            NSLayoutConstraint.activate([
                chevronImage.heightAnchor.constraint(equalTo: openButton.heightAnchor),
                chevronImage.widthAnchor.constraint(equalTo: chevronImage.heightAnchor),
                openButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            openButton.titleLabel?.trailingAnchor.constraint(equalTo: openButton.trailingAnchor).isActive = true

            hiddenHeightConstraint = heightAnchor.constraint(equalTo: buttonStackView.heightAnchor)
            hiddenHeightConstraint?.isActive = true

            hiddenView.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let hiddenView = hiddenView, hiddenView.superview == nil, needsUpdateHiddenView {
            addArrangedSubview(hiddenView)
            layoutIfNeeded()
            hiddenView.removeFromSuperview()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            needsUpdateHiddenView = true
        }
    }

    // MARK: - Handlers
    @objc private func openButtonPressed() {
        toggleHiddenView()
    }

    // MARK: - Public
    func setTitle(_ title: String) {
        openButton.setTitle(title, for: .normal)
    }

    func setHiddenView(with view: UIView) {
        hiddenView = view
    }

    func setHeightConstraint(equalTo anchor: NSLayoutDimension, multiplier: CGFloat = 1.0) {
        shownHeightConstraint = heightAnchor.constraint(equalTo: anchor, multiplier: multiplier)
    }

    func toggleHiddenView() {
        if let hiddenView = hiddenView {
            isOpened = !isOpened

            if isOpened {
                addArrangedSubview(hiddenView)
                NSLayoutConstraint.activate([
                    hiddenView.widthAnchor.constraint(equalTo: widthAnchor)
                ])
            } else {
                hiddenView.removeFromSuperview()
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.hiddenHeightConstraint?.isActive = !self.isOpened
                self.shownHeightConstraint?.isActive = self.isOpened
                hiddenView.isHidden = !self.isOpened
                self.chevronImage.transform = CGAffineTransform(rotationAngle: self.isOpened ? .pi : 0)
                self.parent?.layoutIfNeeded()
                self.layoutIfNeeded()
            })
            needsUpdateHiddenView = false
        }
    }
}
