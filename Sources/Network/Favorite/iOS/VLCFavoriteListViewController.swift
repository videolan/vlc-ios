/*****************************************************************************
 * VLCFavoriteListViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Rizky Maulana <mrizky9601@gmail.com>
 *          Eshan Singh <eeeshan789@icloud.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

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
        tableView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)

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
        if favoriteService.numberOfFavoritedServers == 0 {
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
        header.headerView.hostnameLabel.text = favoriteService.nameOfFavoritedServer(at: section)
        header.headerView.delegate = self
        header.headerView.section = section
        return header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteService.numberOfFavoritesOfServer(at: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalNetworkCell", for: indexPath) as! VLCNetworkListCell
        if let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {
            cell.title = favorite.userVisibleName
            cell.isDirectory = true
            cell.thumbnailImage = UIImage(named: "folder")
            cell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {
            var serverBrowser: VLCNetworkServerBrowser? = nil
            let identifier = favorite.protocolIdentifier as NSString

            /* fasttrack UPnP as it does not allow authentication */
            if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierUPnP) {
                serverBrowser = VLCNetworkServerBrowserVLCMedia.uPnPNetworkServerBrowser(with: favorite.url)
            } else {
                if let login = favorite.loginInformation {
                    if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierFTP) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.ftpNetworkServerBrowser(withLogin: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierPlex) {
                        serverBrowser = VLCNetworkServerBrowserPlex.init(login: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierSMB) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.smbNetworkServerBrowser(withLogin: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierNFS) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.nfsNetworkServerBrowser(withLogin: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierSFTP) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.sftpNetworkServerBrowser(withLogin: login)
                    }
                } else {
                    let media = VLCMedia(url: favorite.url)
                    serverBrowser = VLCNetworkServerBrowserVLCMedia(media: media)
                }
            }

            if let serverBrowserVC = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser,
                                                                           medialibraryService: VLCAppCoordinator().mediaLibraryService) {
                self.navigationController?.pushViewController(serverBrowserVC, animated: true)
            }
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
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
