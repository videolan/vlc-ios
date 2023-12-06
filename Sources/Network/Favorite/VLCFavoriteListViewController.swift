//
//  VLCFavoriteListViewController.swift
//  VLC-iOS
//
//  Created by Rizky Maulana on 16/06/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import UIKit

class VLCFavoriteListViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("FAVORITES", comment: "")
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: NSNotification.Name(kVLCThemeDidChangeNotification),
                                       object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = VLCNetworkListCell.heightOfCell()
        return tableView
    }()

    let userDefaults: UserDefaults = UserDefaults.standard
    let detailText = NSLocalizedString("FAVORITEVC_DETAILTEXT", comment: "")
    let cellImage = UIImage(named: "heart")
    let favoriteService: VLCFavoriteService = VLCAppCoordinator.sharedInstance().favoriteService

    private lazy var emptyView: VLCEmptyLibraryView = {
        let name = String(describing: VLCEmptyLibraryView.self)
        let nib = Bundle.main.loadNibNamed(name, owner: self, options: nil)
        guard let emptyView = nib?.first as? VLCEmptyLibraryView else { fatalError("Can't find nib for \(name)") }
        emptyView.contentType = .noFavorites
        return emptyView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupBarButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.setEditing(false, animated: false)
        self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("BUTTON_EDIT", comment: "")
        self.navigationItem.rightBarButtonItem?.style = .plain
        self.tableView.reloadData()
        showEmptyViewIfNeeded()
    }

    @objc func themeDidChange() {
        self.tableView.backgroundColor = PresentationTheme.current.colors.background
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    private func setupTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = PresentationTheme.current.colors.background
        tableView.register(UINib(nibName: "VLCNetworkListCell", bundle: nil),
                           forCellReuseIdentifier: "LocalNetworkCell")
        tableView.register(FavoriteSectionHeader.self,
                           forHeaderFooterViewReuseIdentifier: FavoriteSectionHeader.identifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBarButton() {
        let editBarButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_EDIT", comment: ""),
                                             style: .plain,
                                             target: self,
                                             action: #selector(toggleEdit))
        editBarButton.tintColor = PresentationTheme.current.colors.orangeUI
        navigationItem.rightBarButtonItem = editBarButton
    }

    @objc private func toggleEdit() {
        let editing = self.tableView.isEditing
        self.tableView.setEditing(!editing, animated: true)

        if editing {
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("BUTTON_EDIT", comment: "")
            self.navigationItem.rightBarButtonItem?.style = .plain
        } else {
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("BUTTON_DONE", comment: "")
            self.navigationItem.rightBarButtonItem?.style = .done
        }
    }

    private func showEmptyViewIfNeeded() {
        if numberOfSections(in: self.tableView) == 0 {
            self.tableView.backgroundView = self.emptyView
            self.tableView.isEditing = false
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.tableView.backgroundView = nil
            if self.navigationItem.rightBarButtonItem == nil {
                self.setupBarButton()
            }
        }
    }
}

extension VLCFavoriteListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return favoriteService.numberOfFavoritedServers
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return FavoriteSectionHeader.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FavoriteSectionHeader.identifier) as! FavoriteSectionHeader
        header.hostnameLabel.text = favoriteService.nameOfFavoritedServer(at: section)
        header.delegate = self
        header.section = section
        return header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteService.numberOfFavoritesOfServer(at: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalNetworkCell", for: indexPath) as! VLCNetworkListCell
        let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row)
        cell.title = favorite.userVisibleName
        cell.isDirectory = true
        cell.thumbnailImage = UIImage(named: "folder")
        cell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row)
        let media = VLCMedia(url: favorite.url)
        let serverBrowser = VLCNetworkServerBrowserVLCMedia(media: media)
        if let serverBrowserVC = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser,
                                                                       medialibraryService: VLCAppCoordinator().mediaLibraryService) {
            self.navigationController?.pushViewController(serverBrowserVC, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            favoriteService.removeFavoriteOfServer(with: indexPath.section, at: indexPath.row)
            self.tableView.reloadData()
            self.showEmptyViewIfNeeded()
        }
    }
}

extension VLCFavoriteListViewController: FavoriteSectionHeaderDelegate {
    func renameSection(sectionIndex: NSInteger) {
        let previousName = favoriteService.nameOfFavoritedServer(at: sectionIndex)

        let alertController = UIAlertController(title: NSLocalizedString("BUTTON_RENAME", comment: ""),
                                                message: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), previousName),
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = previousName
        }
        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                         style: .cancel)
        let confirmAction = UIAlertAction(title:  NSLocalizedString("BUTTON_RENAME", comment: ""),
                                          style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let alertTextField = alertController.textFields?.first else {
                return
            }
            guard let textfieldValue = alertTextField.text else {
                return
            }
            self.favoriteService.setName(textfieldValue, ofFavoritedServerAt: sectionIndex)
            self.tableView.reloadData()
        }

        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)

        present(alertController, animated: true)
    }
}
