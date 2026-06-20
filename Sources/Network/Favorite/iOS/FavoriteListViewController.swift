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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = VLCNetworkListCell.heightOfCell()
        return tableView
    }()

    let favoriteService: VLCFavoriteService = VLCAppCoordinator.sharedInstance().favoriteService

    // MARK: Search

    private var allFavorites = [VLCFavorite]()
    private var filteredFavorites = [VLCFavorite]()
    private var isSearching: Bool = false
    private var searchBar = UISearchBar(frame: .zero)
    private let searchBarSize: CGFloat = 50.0
    private var searchBarConstraint: NSLayoutConstraint?
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        return searchController
    }()

    private lazy var editButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("BUTTON_EDIT", comment: ""),
                                     style: .plain,
                                     target: self,
                                     action: #selector(toggleEdit))
        button.tintColor = PresentationTheme.current.colors.orangeUI
        return button
    }()

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
        setupSearch()
        showEmptyViewIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.setEditing(false, animated: false)
        updateEditButton()
        rebuildFavoritesList()
        tableView.reloadData()
        showEmptyViewIfNeeded()
    }

    // MARK: - Setup

    private func setupSearch() {
        navigationItem.largeTitleDisplayMode = .never
        if #available(iOS 26.0, visionOS 26.0, *) {
            navigationItem.preferredSearchBarPlacement = .integrated
        } else {
            searchBar.delegate = self
            searchBar.searchBarStyle = .minimal
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")

            searchBarConstraint = searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: -searchBarSize)
            view.addSubview(searchBar)
            NSLayoutConstraint.activate([
                searchBarConstraint!,
                searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                searchBar.heightAnchor.constraint(equalToConstant: searchBarSize)
            ])
        }
        applySearchBarTheme()
    }

    private func applySearchBarTheme() {
        if #available(iOS 26.0, visionOS 26.0, *) {
            return
        }

        let backgroundColor = PresentationTheme.current.colors.background
        searchBar.backgroundColor = backgroundColor
        if let textField = searchBar.value(forKey: "searchField") as? UITextField,
           let backgroundView = textField.subviews.first {
            backgroundView.backgroundColor = backgroundColor
            backgroundView.layer.cornerRadius = 10
            backgroundView.clipsToBounds = true
        }
    }

    private func rebuildFavoritesList() {
        allFavorites.removeAll()
        for section in 0..<favoriteService.numberOfFavoritedServers {
            for row in 0..<favoriteService.numberOfFavoritesOfServer(at: section) {
                if let fav = favoriteService.favoriteOfServer(with: section, at: row) {
                    allFavorites.append(fav)
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
        tableView.separatorColor = PresentationTheme.current.colors.separatorColor
        tableView.tableFooterView = UIView(frame: .zero)
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

    // MARK: - Handlers

    @objc func themeDidChange() {
        let colors = PresentationTheme.current.colors
        tableView.backgroundColor = colors.background
        tableView.separatorColor = colors.separatorColor
        applySearchBarTheme()
        editButton.tintColor = colors.orangeUI
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
#if os(iOS)
        setNeedsStatusBarAppearanceUpdate()
#endif
    }

    @objc private func toggleEdit() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        updateEditButton()
    }

    private func updateEditButton() {
        let editing = tableView.isEditing
        editButton.title = editing ? NSLocalizedString("BUTTON_DONE", comment: "")
                                    : NSLocalizedString("BUTTON_EDIT", comment: "")
        editButton.style = editing ? .done : .plain
    }

    private func showEmptyViewIfNeeded() {
        let hasFavorites = favoriteService.numberOfFavoritedServers != 0
        emptyView.isHidden = hasFavorites
        tableView.isHidden = !hasFavorites
        if !hasFavorites {
            tableView.isEditing = false
        }
        navigationItem.rightBarButtonItem = hasFavorites ? editButton : nil
        if #available(iOS 26.0, visionOS 26.0, *) {
            navigationItem.searchController = hasFavorites ? searchController : nil
        } else {
            searchBar.isHidden = !hasFavorites
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
        if let favorite = isSearching ? filteredFavorites.objectAtIndex(index: indexPath.row) : favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {

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
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierWebDAV) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.webDAVNetworkServerBrowser(withLogin: login)
                    }
                } else {
                    if let media = VLCMedia(url: favorite.url) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia(media: media)
                    }
                }
            }

            if let serverBrowserVC = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser,
                                                                           medialibraryService: VLCAppCoordinator.sharedInstance().mediaLibraryService) {
                self.navigationController?.pushViewController(serverBrowserVC, animated: true)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if #available(iOS 26.0, visionOS 26.0, *) {
            return
        }

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
        return isSearching ? filteredFavorites.count : favoriteService.numberOfFavoritesOfServer(at: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalNetworkCell", for: indexPath) as! VLCNetworkListCell
        if let favorite = isSearching ? filteredFavorites.objectAtIndex(index: indexPath.row) : favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {
            cell.title = favorite.userVisibleName
            cell.isDirectory = true
            cell.thumbnailImage = UIImage(named: "folder")
            cell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if isSearching {
                guard let favorite = filteredFavorites.objectAtIndex(index: indexPath.row) else { return }
                favoriteService.remove(favorite)
                filteredFavorites.remove(at: indexPath.row)
                allFavorites.removeAll { $0 === favorite }
            } else {
                favoriteService.removeFavoriteOfServer(with: indexPath.section, at: indexPath.row)
                rebuildFavoritesList()
            }
            tableView.reloadData()
            showEmptyViewIfNeeded()
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

extension FavoriteListViewController: UISearchBarDelegate, UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        if isSearching {
            searchBarCancelButtonClicked(searchController.searchBar)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredFavorites = allFavorites
        } else {
            filteredFavorites = allFavorites.filter { favorite in
                return favorite.userVisibleName.range(of: searchText, options: .caseInsensitive) != nil
            }
        }

        isSearching = !searchText.isEmpty
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        isSearching = false
        tableView.reloadData()
    }
}
