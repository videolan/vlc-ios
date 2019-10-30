/*****************************************************************************
 * EditToolbar.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol EditToolbarDelegate: class {
    func editToolbarDidDelete(_ editToolbar: EditToolbar)
    func editToolbarDidAddToPlaylist(_ editToolbar: EditToolbar)
    func editToolbarDidRename(_ editToolbar: EditToolbar)
    func editToolbarDidShare(_ editToolbar: EditToolbar)
}

class EditToolbar: UIView {
    static let height: CGFloat = 60
    weak var delegate: EditToolbarDelegate?
    private var model: MediaLibraryBaseModel

    private var stackView: UIStackView = {
        let stackView = UIStackView()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalSpacing

        return stackView
    }()

    private var rightStackView: UIStackView = {
        let rightStackView = UIStackView()

        rightStackView.translatesAutoresizingMaskIntoConstraints = false

        return rightStackView
    }()

    private var addToPlaylistButton: UIButton = {
        let addToPlaylistButton = UIButton(type: .system)
        addToPlaylistButton.setTitle(NSLocalizedString("ADD_TO_PLAYLIST", comment: ""), for: .normal)
        addToPlaylistButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        addToPlaylistButton.contentHorizontalAlignment = .left
        addToPlaylistButton.addTarget(self, action: #selector(addToPlaylist), for: .touchUpInside)
        addToPlaylistButton.tintColor = .orange
        addToPlaylistButton.accessibilityLabel = NSLocalizedString("ADD_TO_PLAYLIST", comment: "")
        addToPlaylistButton.accessibilityHint = NSLocalizedString("ADD_TO_PLAYLIST_HINT", comment: "")
        return addToPlaylistButton
    }()

    @objc func addToPlaylist() {
        delegate?.editToolbarDidAddToPlaylist(self)
    }

    @objc func deleteSelection() {
        delegate?.editToolbarDidDelete(self)
    }

    @objc func rename() {
        delegate?.editToolbarDidRename(self)
    }

    @objc func share() {
        delegate?.editToolbarDidShare(self)
    }

    private func setupRightStackView() {
        var buttonList = EditButtonsFactory.buttonList(for: model.anyfiles.first)
        // For now we remove the first button which is Add to playlist since it is not in the same group
        if buttonList.contains(.addToPlaylist) {
            if let index = buttonList.firstIndex(of: .addToPlaylist) {
                buttonList.remove(at: index)
            }
        }
        let buttons = EditButtonsFactory.generate(buttons: buttonList)
        for button in buttons {
            switch button.identifier {
                case .addToPlaylist:
                    rightStackView.addArrangedSubview(button.button(#selector(addToPlaylist)))
                case .rename:
                    rightStackView.addArrangedSubview(button.button(#selector(rename)))
                case .delete:
                    rightStackView.addArrangedSubview(button.button(#selector(deleteSelection)))
                case .share:
                    rightStackView.addArrangedSubview(button.button(#selector(share)))
            }
        }
    }

    private func setupStackView() {
        stackView.addArrangedSubview(addToPlaylistButton)
        stackView.addArrangedSubview(rightStackView)

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupView() {
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -1)
        backgroundColor = PresentationTheme.current.colors.background
    }

    init(model: MediaLibraryBaseModel) {
        self.model = model
        super.init(frame: .zero)
        setupView()
        setupRightStackView()
        setupStackView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
