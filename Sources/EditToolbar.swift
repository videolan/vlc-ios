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
    func editToolbarDidShare(_ editToolbar: EditToolbar, presentFrom button: UIButton)
}

class EditToolbar: UIView {
    static let height: CGFloat = 60
    weak var delegate: EditToolbarDelegate?
    private var category: MediaLibraryBaseModel
    private var stackView = UIStackView()
    private var shareButton: UIButton = {
        let shareButton = UIButton(type: .system)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        shareButton.setImage(UIImage(named: "share"), for: .normal)
        shareButton.tintColor = .orange
        shareButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shareButton.accessibilityLabel = NSLocalizedString("SHARE_LABEL", comment: "")
        shareButton.accessibilityHint = NSLocalizedString("SHARE_HINT", comment: "")
        return shareButton
    }()
    private var renameButton: UIButton = {
        let renameButton = UIButton(type: .system)
        renameButton.addTarget(self, action: #selector(rename), for: .touchUpInside)
        renameButton.setImage(UIImage(named: "rename"), for: .normal)
        renameButton.tintColor = .orange
        renameButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        renameButton.accessibilityLabel = NSLocalizedString("BUTTON_RENAME", comment: "")
        renameButton.accessibilityHint = NSLocalizedString("RENAME_HINT", comment: "")
        return renameButton
    }()
    private var deleteButton: UIButton = {
        let deleteButton = UIButton(type: .system)
        deleteButton.addTarget(self, action: #selector(deleteSelection), for: .touchUpInside)
        deleteButton.setImage(UIImage(named: "delete"), for: .normal)
        deleteButton.tintColor = .orange
        deleteButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        deleteButton.accessibilityLabel = NSLocalizedString("BUTTON_DELETE", comment: "")
        deleteButton.accessibilityHint = NSLocalizedString("DELETE_HINT", comment: "")
        return deleteButton
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
        delegate?.editToolbarDidShare(self, presentFrom: shareButton)
    }

    private func setupStackView() {
        let stackView = UIStackView(arrangedSubviews: [addToPlaylistButton])
        let file = category.anyfiles.first

        if !(file is VLCMLArtist) && !(file is VLCMLGenre) && !(file is VLCMLAlbum) {
            stackView.addArrangedSubview(deleteButton)
            stackView.addArrangedSubview(renameButton)
        }

        stackView.addArrangedSubview(shareButton)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
    }

    private func setupView() {
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -1)
        backgroundColor = PresentationTheme.current.colors.background
    }

    init(category: MediaLibraryBaseModel) {
        self.category = category
        super.init(frame: .zero)
        setupView()
        setupStackView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
