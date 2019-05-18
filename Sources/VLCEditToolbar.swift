/*****************************************************************************
 * VLCEditToolbar.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol VLCEditToolbarDelegate: class {
    func editToolbarDidDelete(_ editToolbar: VLCEditToolbar)
    func editToolbarDidAddToPlaylist(_ editToolbar: VLCEditToolbar)
    func editToolbarDidRename(_ editToolbar: VLCEditToolbar)
    func editToolbarDidShare(_ editToolbar: VLCEditToolbar, presentFrom button: UIButton)
}

class VLCEditToolbar: UIView {
    static let height: CGFloat = 60
    weak var delegate: VLCEditToolbarDelegate?
    private var category: MediaLibraryBaseModel
    private var stackView = UIStackView()
    private var shareButton: UIButton = {
        let shareButton = UIButton(type: .system)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        shareButton.setImage(UIImage(named: "share"), for: .normal)
        shareButton.tintColor = .orange
        shareButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return shareButton
    }()
    private var renameButton: UIButton = {
        let renameButton = UIButton(type: .system)
        renameButton.addTarget(self, action: #selector(rename), for: .touchUpInside)
        renameButton.setImage(UIImage(named: "rename"), for: .normal)
        renameButton.tintColor = .orange
        renameButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return renameButton
    }()
    private var deleteButton: UIButton = {
        let deleteButton = UIButton(type: .system)
        deleteButton.addTarget(self, action: #selector(deleteSelection), for: .touchUpInside)
        deleteButton.setImage(UIImage(named: "delete"), for: .normal)
        deleteButton.tintColor = .orange
        deleteButton.widthAnchor.constraint(equalToConstant: 44).isActive = true

        return deleteButton
    }()
    private var addToPlaylistButton: UIButton = {
        let addToPlaylistButton = UIButton(type: .system)
        addToPlaylistButton.setTitle(NSLocalizedString("ADD_TO_PLAYLIST", comment: ""), for: .normal)
        addToPlaylistButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        addToPlaylistButton.contentHorizontalAlignment = .left
        addToPlaylistButton.addTarget(self, action: #selector(addToPlaylist), for: .touchUpInside)
        addToPlaylistButton.tintColor = .orange
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
        }
        stackView.addArrangedSubview(shareButton)
        if !(file is VLCMLAlbum) && !(file is VLCMLArtist) && !(file is VLCMLGenre) {
            stackView.addArrangedSubview(renameButton)
        }

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
