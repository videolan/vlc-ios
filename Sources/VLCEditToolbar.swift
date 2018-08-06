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

// Decided to use a UIView instead of UIToolbar because we have more freedom
class VLCEditToolbar: UIView {

    private let fixedSpaceWidth: CGFloat = 150

    var mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.spacing = 20.0
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    var createFolderButton: UIButton = {
        let createFolderButton = UIButton()
        createFolderButton.addTarget(self,
                                     action: #selector(createFolder),
                                     for: .touchUpInside)
        createFolderButton.titleLabel?.text = "Create Folder"
        createFolderButton.tintColor = PresentationTheme.current.colors.orangeUI
        createFolderButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        createFolderButton.translatesAutoresizingMaskIntoConstraints = false
        createFolderButton.backgroundColor = .magenta
        return createFolderButton
    }()

    var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.addTarget(self,
                               action: #selector(deleteSelection),
                               for: .touchUpInside)
        deleteButton.imageView?.image = UIImage(named: "delete")
        deleteButton.tintColor = PresentationTheme.current.colors.orangeUI
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.backgroundColor = .blue
        return deleteButton
    }()

//    var deleteBarButtonItem: UIBarButtonItem = {
//        // target should be vc
//        let deleteBarButtonItem = UIBarButtonItem(image: UIImage(named: "delete"),
//                                                  style: .plain,
//                                                  target: self,
//                                                  action: #selector(deleteSelection))
//        deleteBarButtonItem.tintColor = PresentationTheme.current.colors.orangeUI
//        return deleteBarButtonItem
//    }()
//
//    var folderBarButtonItem: UIBarButtonItem = {
//        let folderBarButtonItem = UIBarButtonItem(title: "Create Folder",
//                                                  style: .plain,
//                                                  target: self,
//                                                  action: #selector(createFolder))
//
//        folderBarButtonItem.tintColor = PresentationTheme.current.colors.orangeUI
//
//        let attributes = [
//            NSAttributedStringKey.foregroundColor: PresentationTheme.current.colors.orangeUI,
//            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .medium)
//        ]
//        folderBarButtonItem.setTitleTextAttributes(attributes, for: .normal)
//        return folderBarButtonItem
//    }()

    @objc func deleteSelection() {
        print("delete!")
    }

    @objc func createFolder() {
        print("create folder!")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
//        fixedSpace.width = fixedSpaceWidth
//        setItems([folderBarButtonItem, fixedSpace, deleteBarButtonItem], animated: true)
//        isTranslucent = false
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        mainStackView.addArrangedSubview(createFolderButton)
        mainStackView.addArrangedSubview(deleteButton)
        addSubview(mainStackView)
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        self.backgroundColor = .red
        NSLayoutConstraint.activate([
//            createFolderButton.heightAnchor.constraint(equalToConstant: 20),
//            deleteButton.leadingAnchor.constraint(equalTo: createFolderButton.trailingAnchor, constant: 100),
//            heightAnchor.constraint(equalToConstant: 50),
//            bottomAnchor.constraint(equalTo: guide.centerYAnchor)
            // need to adjust y for iphone x
            createFolderButton.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            createFolderButton.heightAnchor.constraint(equalToConstant: 25),
//            createFolderButton.widthAnchor.constraint(equalToConstant: 90),
            createFolderButton.centerYAnchor.constraint(equalTo: mainStackView.centerYAnchor),

            deleteButton.widthAnchor.constraint(equalToConstant: 25),
            deleteButton.heightAnchor.constraint(equalToConstant: 25),
            deleteButton.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),

            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            mainStackView.heightAnchor.constraint(equalTo: heightAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}
