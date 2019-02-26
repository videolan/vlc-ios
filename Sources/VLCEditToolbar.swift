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
    func delete()
    func createPlaylist()
    func rename()
    func share()
}

class VLCEditToolbar: UIView {
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
    private var addtoPlaylist: UIButton = {
        let addtoPlaylist = UIButton(type: .system)
        addtoPlaylist.setTitle(NSLocalizedString("ADD_TO_PLAYLIST", comment: ""), for: .normal)
        addtoPlaylist.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        addtoPlaylist.contentHorizontalAlignment = .left
        addtoPlaylist.addTarget(self, action: #selector(addToPlaylist), for: .touchUpInside)
        addtoPlaylist.tintColor = .orange
        return addtoPlaylist
    }()

    @objc func addToPlaylist() {
        delegate?.createPlaylist()
    }

    @objc func deleteSelection() {
        delegate?.delete()
    }

    @objc func rename() {
        delegate?.rename()
    }

    @objc func share() {
        delegate?.share()
    }

    private func setupStackView() {
        let stackView = UIStackView(arrangedSubviews: [addtoPlaylist, deleteButton, shareButton])
        let file = category.anyfiles.first
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

    init(category: MediaLibraryBaseModel) {
        self.category = category
        super.init(frame: .zero)
        setupStackView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
