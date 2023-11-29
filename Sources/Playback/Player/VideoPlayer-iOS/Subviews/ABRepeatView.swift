/*****************************************************************************
 * ABRepeatView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2023 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol ABRepeatViewDelegate: AnyObject {
    func abRepeatViewDidSelectAMark()
    func abRepeatViewDidSelectBMark()
    func abRepeatViewShowIcon(_ option: OptionsNavigationBarIdentifier)
    func abRepeatViewHideIcon(_ option: OptionsNavigationBarIdentifier)
}

@objc class ABRepeatMarkView: UIView {
    private let imageView: UIImageView
    private var position: Float = 0.0

    var isEnabled: Bool = false

    init(icon: UIImage?) {
        imageView = UIImageView(image: icon)
        imageView.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        super.init(frame: .zero)
        setupIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupIcon() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func setPosition(at position: Float) {
        self.position = position
    }

    func getPosition() -> Float {
        return position
    }
}

class ABRepeatView: UIView {
    lazy var aMarkView: UIView = {
        let aMarkView = UIView(frame: frame)
        aMarkView.layer.cornerRadius = 5.0
        aMarkView.translatesAutoresizingMaskIntoConstraints = false
        return aMarkView
    }()

    private lazy var aMarkButton: UIButton = {
        let aMarkButton = UIButton(type: .custom)
        aMarkButton.setTitle("Select your A mark", for: .normal)
        aMarkButton.addTarget(self, action: #selector(handleAMarkSelection(_:)), for: .touchUpInside)
        aMarkButton.translatesAutoresizingMaskIntoConstraints = false
        return aMarkButton
    }()

    lazy var bMarkView: UIView = {
        let bMarkView = UIView(frame: frame)
        bMarkView.isHidden = true
        bMarkView.layer.cornerRadius = 5.0
        bMarkView.translatesAutoresizingMaskIntoConstraints = false
        return bMarkView
    }()

    private lazy var bMarkButton: UIButton = {
        let bMarkButton = UIButton(type: .custom)
        bMarkButton.setTitle("Select your B mark", for: .normal)
        bMarkButton.addTarget(self, action: #selector(handleBMarkSelection(_:)), for: .touchUpInside)
        bMarkButton.translatesAutoresizingMaskIntoConstraints = false
        return bMarkButton
    }()

    weak var delegate: ABRepeatViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupButtons()
        setupTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        layer.cornerRadius = 5.0

        addSubview(aMarkView)
        addSubview(bMarkView)

        NSLayoutConstraint.activate([
            aMarkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            aMarkView.topAnchor.constraint(equalTo: topAnchor),
            aMarkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            aMarkView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bMarkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bMarkView.topAnchor.constraint(equalTo: topAnchor),
            bMarkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bMarkView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupButtons() {
        aMarkView.addSubview(aMarkButton)
        bMarkView.addSubview(bMarkButton)

        let padding: CGFloat = 10.0
        NSLayoutConstraint.activate([
            aMarkButton.leadingAnchor.constraint(equalTo: aMarkView.leadingAnchor, constant: padding),
            aMarkButton.topAnchor.constraint(equalTo: aMarkView.topAnchor),
            aMarkButton.trailingAnchor.constraint(equalTo: aMarkView.trailingAnchor, constant: -padding),
            aMarkButton.bottomAnchor.constraint(equalTo: aMarkView.bottomAnchor),

            bMarkButton.leadingAnchor.constraint(equalTo: bMarkView.leadingAnchor, constant: padding),
            bMarkButton.topAnchor.constraint(equalTo: bMarkView.topAnchor),
            bMarkButton.trailingAnchor.constraint(equalTo: bMarkView.trailingAnchor, constant: -padding),
            bMarkView.bottomAnchor.constraint(equalTo: bMarkView.bottomAnchor)
        ])
    }

    private func setupTheme() {
        backgroundColor = .black

        let colors = PresentationTheme.currentExcludingWhite.colors
        aMarkView.backgroundColor = .clear
        aMarkButton.setTitleColor(colors.orangeUI, for: .normal)

        bMarkView.backgroundColor = .clear
        bMarkButton.setTitleColor(colors.orangeUI, for: .normal)
    }

    @objc func handleAMarkSelection(_ sender: Any) {
        aMarkView.isHidden = true
        bMarkView.isHidden = false
        delegate?.abRepeatViewDidSelectAMark()
    }

    @objc func handleBMarkSelection(_ sender: Any) {
        bMarkView.isHidden = true
        delegate?.abRepeatViewDidSelectBMark()
        delegate?.abRepeatViewShowIcon(.abRepeat)
        delegate?.abRepeatViewShowIcon(.abRepeatMarks)
    }
}
