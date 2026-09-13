/*****************************************************************************
 * ValueStepperView.swift
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

protocol ValueStepperViewDelegate: AnyObject {
    func valueStepperViewDidDecrement(_ stepperView: ValueStepperView)
    func valueStepperViewDidIncrement(_ stepperView: ValueStepperView)
    func valueStepperViewDidTapValue(_ stepperView: ValueStepperView)
}

final class ValueStepperView: UIView {
    weak var delegate: ValueStepperViewDelegate?

    private let decreaseButton = AutoRepeatButton(type: .custom)
    private let increaseButton = AutoRepeatButton(type: .custom)
    private let valueButton = UIButton(type: .custom)
    private let buttonSize: CGFloat

    init(buttonSize: CGFloat, valuePointSize: CGFloat) {
        self.buttonSize = buttonSize
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        if let titleLabel = valueButton.titleLabel {
            let font = UIFont.monospacedDigitSystemFont(ofSize: valuePointSize, weight: .semibold)
            titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
            titleLabel.adjustsFontForContentSizeCategory = true
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.5
        }
        valueButton.addTarget(self, action: #selector(didTapValue), for: .touchUpInside)
        decreaseButton.addTarget(self, action: #selector(didDecrement), for: .valueChanged)
        increaseButton.addTarget(self, action: #selector(didIncrement), for: .valueChanged)

        for subview in [decreaseButton, valueButton, increaseButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            decreaseButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            decreaseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            decreaseButton.widthAnchor.constraint(equalToConstant: buttonSize),
            decreaseButton.heightAnchor.constraint(equalToConstant: buttonSize),

            increaseButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            increaseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            increaseButton.widthAnchor.constraint(equalToConstant: buttonSize),
            increaseButton.heightAnchor.constraint(equalToConstant: buttonSize),

            valueButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueButton.topAnchor.constraint(equalTo: topAnchor),
            valueButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            valueButton.heightAnchor.constraint(greaterThanOrEqualToConstant: buttonSize),
            valueButton.leadingAnchor.constraint(greaterThanOrEqualTo: decreaseButton.trailingAnchor, constant: 8),
            valueButton.trailingAnchor.constraint(lessThanOrEqualTo: increaseButton.leadingAnchor, constant: -8),
        ])

        styleButtons()

        isAccessibilityElement = true
        accessibilityTraits = .adjustable

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(accessibilityDisplayOptionsChanged),
                                       name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(accessibilityDisplayOptionsChanged),
                                       name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
                                       object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(valueText: String, isModified: Bool) {
        let colors = PresentationTheme.currentExcludingWhite.colors
        let textColor = isModified ? colors.orangeUI : colors.overlayPrimaryTextColor
        UIView.performWithoutAnimation {
            valueButton.setTitle(valueText, for: .normal)
            valueButton.layoutIfNeeded()
        }
        valueButton.setTitleColor(textColor, for: .normal)
        valueButton.setTitleColor(textColor.withAlphaComponent(0.5), for: .highlighted)
        accessibilityValue = valueText
    }

    func pulseValue() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        valueButton.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction],
                       animations: {
            self.valueButton.transform = .identity
        })
    }

    override func accessibilityIncrement() {
        delegate?.valueStepperViewDidIncrement(self)
    }

    override func accessibilityDecrement() {
        delegate?.valueStepperViewDidDecrement(self)
    }

    private func styleButtons() {
        applyStyle(to: decreaseButton, systemName: "minus", fallbackTitle: "−")
        applyStyle(to: increaseButton, systemName: "plus", fallbackTitle: "+")
    }

    private func applyStyle(to button: UIButton, systemName: String, fallbackTitle: String) {
        if #available(iOS 13.0, *) {
            let symbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title3)
                .applying(UIImage.SymbolConfiguration(weight: .semibold))
            let image = UIImage(systemName: systemName, withConfiguration: symbolConfiguration)
            button.applyOverlayControlStyle(title: nil, image: image, isActive: false, cornerRadius: buttonSize / 2)
        } else {
            button.applyOverlayControlStyle(title: fallbackTitle, image: nil, isActive: false, cornerRadius: buttonSize / 2)
        }
    }

    @objc private func didDecrement() {
        delegate?.valueStepperViewDidDecrement(self)
    }

    @objc private func didIncrement() {
        delegate?.valueStepperViewDidIncrement(self)
    }

    @objc private func didTapValue() {
        delegate?.valueStepperViewDidTapValue(self)
    }

    @objc private func accessibilityDisplayOptionsChanged() {
        styleButtons()
    }
}
