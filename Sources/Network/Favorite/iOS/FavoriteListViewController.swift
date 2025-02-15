/*****************************************************************************
 * FavoriteListViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Rizky Maulana <mrizky9601@gmail.com>
 *          Eshan Singh <eeeshan789@icloud.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class FavoriteListViewController: UIViewController {
    // MARK: - Properties

    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = VLCNetworkListCell.heightOfCell()
        return tableView
    }()

    let detailText = NSLocalizedString("FAVORITEVC_DETAILTEXT", comment: "")
    let cellImage = UIImage(named: "heart")
    let favoriteService: VLCFavoriteService = VLCAppCoordinator.sharedInstance().favoriteService

    // Search properties
    var searchResults = [VLCFavorite]()
    var searchDataSource = [VLCFavorite]()
    var searchBar = UISearchBar(frame: .zero)
    private let searchBarSize: CGFloat = 50.0
    private var searchBarConstraint: NSLayoutConstraint?
    private var isSearching: Bool = false

    private lazy var emptyView: VLCEmptyLibraryView = {
        let name = String(describing: VLCEmptyLibraryView.self)
        let nib = Bundle.main.loadNibNamed(name, owner: self, options: nil)
        guard let emptyView = nib?.first as? VLCEmptyLibraryView else {
            fatalError("Can't find nib for \(name)")
        }

        emptyView.contentType = .noFavorites
        emptyView.backgroundColor = PresentationTheme.current.colors.background
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        return emptyView
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("FAVORITES", comment: "")
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: NSNotification.Name(kVLCThemeDidChangeNotification),
                                       object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmptyView()
        setupTableView()
        setupBarButton()
        setupSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.setEditing(false, animated: false)
        self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("BUTTON_EDIT", comment: "")
        self.navigationItem.rightBarButtonItem?.style = .plain
        self.tableView.reloadData()
        showEmptyViewIfNeeded()
        setupSearchDataSource()
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        searchBar.backgroundColor = PresentationTheme.current.colors.background
        navigationItem.largeTitleDisplayMode = .never

        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }

        searchBarConstraint = searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: -searchBarSize)
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBarConstraint!,
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: searchBarSize)
        ])
    }

    private func setupSearchDataSource() {
        if !searchDataSource.isEmpty {
            searchDataSource.removeAll()
        }
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                if let fav = favoriteService.favoriteOfServer(with: section, at: row) {
                    searchDataSource.append(fav)
                }
            }
        }
    }

    private func setupEmptyView() {
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

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

    // MARK: - Handlers

    @objc func themeDidChange() {
        self.tableView.backgroundColor = PresentationTheme.current.colors.background
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
#if os(iOS)
        self.setNeedsStatusBarAppearanceUpdate()
#endif
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
            emptyView.isHidden = false
            tableView.isEditing = false
            tableView.isHidden = true
            self.navigationItem.rightBarButtonItem = nil
        } else {
            emptyView.isHidden = true
            tableView.isHidden = false
            if self.navigationItem.rightBarButtonItem == nil {
                setupBarButton()
            }
        }
    }

#if os(iOS)
    private func showCloudFavVC(fav: VLCFavorite) {
        let favURL = fav.url
        var cloudVC: VLCCloudStorageTableViewController?

        if let favoritetype = favURL.host {
            switch favoritetype {
            case "DropBox":
                cloudVC = VLCDropboxTableViewController(nibName: "VLCCloudStorageTableViewController", bundle: nil)
                break
            case "Drive":
                cloudVC = VLCGoogleDriveTableViewController(nibName: "VLCCloudStorageTableViewController", bundle: nil)
            case "OneDrive":
                break
            case "Box":
                cloudVC = VLCBoxTableViewController(nibName: "VLCCloudStorageTableViewController", bundle: nil)
                break
            case "PCloud":
                cloudVC = VLCPCloudViewController(nibName: "VLCCloudStorageTableViewController", bundle: nil)
            default:
                break
            }
        }

        if let viewController = cloudVC {
            let basePath = favURL.path
            let filePath = basePath.hasPrefix("/") ? String(basePath.dropFirst()) : basePath
            viewController.currentPath = filePath
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
#endif
}

// MARK: - UITableViewDelegate

extension FavoriteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isSearching ? 0 : FavoriteSectionHeader.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isSearching {
            return nil
        }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FavoriteSectionHeader.identifier) as! FavoriteSectionHeader
        header.headerView.hostnameLabel.text = favoriteService.nameOfFavoritedServer(at: section)
        header.headerView.delegate = self
        header.headerView.section = section
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let favorite = isSearching ? searchResults.objectAtIndex(index: indexPath.row) : favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {

#if os(iOS)
            if favorite.protocolIdentifier == "FILE" {
                showCloudFavVC(fav: favorite)
                return
            }
#endif

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
                    if let media = VLCMedia(url: favorite.url) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia(media: media)
                    }
                }
            }

            if let serverBrowserVC = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser,
                                                                           medialibraryService: VLCAppCoordinator().mediaLibraryService) {
                self.navigationController?.pushViewController(serverBrowserVC, animated: true)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // This ensures that the search bar is always visible like a sticky while searching
        if isSearching {
            searchBar.endEditing(true)
            if let searchBarText = searchBar.text,
               searchBarText.isEmpty {
                searchBarCancelButtonClicked(searchBar)
            }
            return
        }

        searchBarConstraint?.constant = -min(scrollView.contentOffset.y, searchBarSize) - searchBarSize
        if scrollView.contentOffset.y < -searchBarSize && scrollView.contentInset.top != searchBarSize {
            tableView.contentInset.top = searchBarSize
        }

        if scrollView.contentOffset.y >= 0 && scrollView.contentInset.top != 0 {
            tableView.contentInset.top = 0
        }
    }
}

// MARK: - UITableViewDataSource

extension FavoriteListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : favoriteService.numberOfFavoritedServers
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : favoriteService.numberOfFavoritesOfServer(at: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalNetworkCell", for: indexPath) as! VLCNetworkListCell
        if let favorite = isSearching ? searchResults[indexPath.row] : favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {
            cell.title = favorite.userVisibleName
            cell.isDirectory = true
            cell.thumbnailImage = UIImage(named: "folder")
            cell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            favoriteService.removeFavoriteOfServer(with: indexPath.section, at: indexPath.row)
            setupSearchDataSource()
            self.tableView.reloadData()
            self.showEmptyViewIfNeeded()
        }
    }
}

// MARK: - FavoriteSectionHeaderDelegate

extension FavoriteListViewController: FavoriteSectionHeaderDelegate {
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: - UISearchBarDelegate

extension FavoriteListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = searchDataSource
        } else {
            searchResults = searchDataSource.filter { favorite in
                return favorite.userVisibleName.range(of: searchText, options: .caseInsensitive) != nil
            }
        }

        searchBar.setShowsCancelButton(true, animated: true)
        isSearching = !searchText.isEmpty
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        searchBar.text = ""
        isSearching = false
        tableView.reloadData()
    }
}
