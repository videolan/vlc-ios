/*****************************************************************************
 * ActionSheetSectionHeader.swift
 *
 * Copyright © 2018-2026 VLC authors and VideoLAN
 * Copyright © 2018-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ActionSheetSectionHeader: UIView {
    var cellHeight: CGFloat {
        return 50
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let title: UILabel = {
        let title = UILabel()
        let colors = PresentationTheme.current.colors
        title.font = UIFont.preferredCustomFont(forTextStyle: .headline).bolded
        title.textColor = colors.cellTextColor
        title.backgroundColor = colors.background
        title.setContentHuggingPriority(.required, for: .vertical)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
        setupSeparator()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStackView()
        setupSeparator()
    }

    fileprivate func setupStackView() {
        stackView.addArrangedSubview(title)

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    fileprivate func setupSeparator() {
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.topAnchor.constraint(equalTo: bottomAnchor, constant: -1)
        ])
    }
}
