/*****************************************************************************
 * EditToolbar.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol EditToolbarDelegate: AnyObject {
    func editToolbarDidDelete(_ editToolbar: EditToolbar)
    func editToolbarDidAddToPlaylist(_ editToolbar: EditToolbar)
    func editToolbarDidAddToMediaGroup(_ editToolbar: EditToolbar)
    func editToolbarDidRemoveFromMediaGroup(_ editToolbar: EditToolbar)
    func editToolbarDidRename(_ editToolbar: EditToolbar)
    func editToolbarDidShare(_ editToolbar: EditToolbar)
}

class EditToolbar: UIView {
    static let height: CGFloat = 60
    weak var delegate: EditToolbarDelegate?

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

    private lazy var addToPlaylistButton: UIButton = {
        let addToPlaylistButton = UIButton(type: .system)
        addToPlaylistButton.setTitle(NSLocalizedString("ADD_TO_PLAYLIST", comment: ""), for: .normal)
        addToPlaylistButton.titleLabel?.font = UIFont.preferredCustomFont(forTextStyle: .headline)
        addToPlaylistButton.contentHorizontalAlignment = .left
        addToPlaylistButton.addTarget(self, action: #selector(addToPlaylist), for: .touchUpInside)
        addToPlaylistButton.tintColor = .orange
        addToPlaylistButton.accessibilityLabel = NSLocalizedString("ADD_TO_PLAYLIST", comment: "")
        addToPlaylistButton.accessibilityHint = NSLocalizedString("ADD_TO_PLAYLIST_HINT", comment: "")
        return addToPlaylistButton
    }()

    private(set) var addToMediaGroupButton: UIButton!
    private var removeFromMediaGroupButton: UIButton!
    private var renameButton: UIButton!
    private var deleteButton: UIButton!
    private(set) var shareButton: UIButton!

    @objc func addToPlaylist() {
        delegate?.editToolbarDidAddToPlaylist(self)
    }

    @objc func addToMediaGroup() {
        delegate?.editToolbarDidAddToMediaGroup(self)
    }

    @objc func removeFromMediaGroup() {
        delegate?.editToolbarDidRemoveFromMediaGroup(self)
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

    func enableEditActions(_ enable: Bool) {
        addToPlaylistButton.isEnabled = enable
        addToMediaGroupButton.isEnabled = enable
        removeFromMediaGroupButton.isEnabled = enable
        renameButton.isEnabled = enable
        deleteButton.isEnabled = enable
        shareButton.isEnabled = enable
    }

    func updateEditToolbar(for model: MediaLibraryBaseModel) {
        var buttonTypeList = EditButtonsFactory.buttonList(for: model)
        // For now we remove the first button which is Add to playlist since it is not in the same group
        if buttonTypeList.contains(.addToPlaylist) {
            if let index = buttonTypeList.firstIndex(of: .addToPlaylist) {
                buttonTypeList.remove(at: index)
            }
        }

        // Hide all buttons and show depending on model
        addToMediaGroupButton.isHidden = true
        removeFromMediaGroupButton.isHidden = true
        renameButton.isHidden = true
        deleteButton.isHidden = true
        shareButton.isHidden = true

        enableEditActions(false)

        for buttonType in buttonTypeList {
            switch buttonType {
            case .addToPlaylist:
                addToPlaylistButton.isHidden = false
            case .addToMediaGroup:
                // Disable button by default, enable it depeding on selected items.
                addToMediaGroupButton.isEnabled = false
                addToMediaGroupButton.isHidden = false
            case .removeFromMediaGroup:
                removeFromMediaGroupButton.isHidden = false
            case .rename:
                renameButton.isHidden = false
            case .delete:
                deleteButton.isHidden = false
            case .share:
                shareButton.isHidden = false
            //Not supported in edit mode
            case .play,
                 .playNextInQueue,
                 .appendToQueue,
                 .playAsAudio:
                break
            }
        }
    }

    private func setupRightStackView() {
        let buttons = EditButtonsFactory.generate(buttons: [.addToMediaGroup, .removeFromMediaGroup,
                                                            .rename, .delete, .share])
        for button in buttons {
            switch button.identifier {
            case .addToPlaylist:
                rightStackView.addArrangedSubview(button.button(#selector(addToPlaylist)))
            case .addToMediaGroup:
                addToMediaGroupButton = button.button(#selector(addToMediaGroup))
                rightStackView.addArrangedSubview(addToMediaGroupButton)
            case .removeFromMediaGroup:
                removeFromMediaGroupButton = button.button(#selector(removeFromMediaGroup))
                rightStackView.addArrangedSubview(removeFromMediaGroupButton)
            case .rename:
                renameButton = button.button(#selector(rename))
                rightStackView.addArrangedSubview(renameButton)
            case .delete:
                deleteButton = button.button(#selector(deleteSelection))
                rightStackView.addArrangedSubview(deleteButton)
            case .share:
                shareButton = button.button(#selector(share))
                rightStackView.addArrangedSubview(shareButton)
            //Not supported in edit mode
            case .play,
                 .playNextInQueue,
                 .appendToQueue,
                 .playAsAudio:
                break
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
        backgroundColor = PresentationTheme.current.colors.background
    }

    init() {
        super.init(frame: .zero)
        setupView()
        setupRightStackView()
        setupStackView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
