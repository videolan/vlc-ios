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
        title = NSLocalizedString("FAVORITE", comment: "")
        let notificationCenter = NotificationCenter.default
        setupData()
        notificationCenter.addObserver(self, selector: #selector(receiveNotification), name: Notification.Name(kVLCNetworkServerFavoritesUpdated), object: nil)
        notificationCenter.addObserver(self, selector: #selector(themeDidChange), name: NSNotification.Name(kVLCThemeDidChangeNotification), object: nil)
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
    var urlArray: [String] = []
    var layoutArray: [String: [String]] = [:]
    var aliasArray: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupData() {
        urlArray = userDefaults.stringArray(forKey: kVLCRecentFavoriteURL) ?? []
        aliasArray = userDefaults.value(forKey: kVLCFavoriteGroupAlias) as? [String: String] ?? [:]
        
        for urlItem in urlArray {
            let component = URLComponents(string: urlItem)
            guard let hostname = component?.host else { return }
            guard let alias = aliasArray.first(where: { $0.value == hostname })?.key else {
                if layoutArray[hostname] == nil {
                    layoutArray[hostname] = [urlItem]
                } else {
                    layoutArray[hostname]?.append(urlItem)
                }
                return
            }
            
            if layoutArray[alias] == nil {
                layoutArray[alias] = [urlItem]
            } else {
                layoutArray[alias]?.append(urlItem)
            }
        }
    }
    
    private func setupTableView() {
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = PresentationTheme.current.colors.background
        tableView.register(UINib(nibName: "VLCNetworkListCell", bundle: nil), forCellReuseIdentifier: "LocalNetworkCell")
        tableView.register(FavoriteSectionHeader.self, forHeaderFooterViewReuseIdentifier: FavoriteSectionHeader.identifier)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension VLCFavoriteListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return layoutArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return FavoriteSectionHeader.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FavoriteSectionHeader.identifier) as! FavoriteSectionHeader
        header.hostnameLabel.text = fetchHostnameFromSection(folderList: layoutArray, for: section)
        header.delegate = self
        return header
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let hostname = fetchHostnameFromSection(folderList: layoutArray, for: section)
        guard let folderCount = layoutArray[hostname]?.count else { return 0 }
        return folderCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalNetworkCell", for: indexPath) as! VLCNetworkListCell
        let hostname = fetchHostnameFromSection(folderList: layoutArray, for: indexPath.section)
        
        let folderURL = layoutArray[hostname]![indexPath.row]
        let url = URL(string: folderURL)
        
        if let cellTitle = url?.lastPathComponent { cell.title = cellTitle }
        cell.isDirectory = true
        cell.thumbnailImage = UIImage(named: "folder")
        cell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hostname = fetchHostnameFromSection(folderList: layoutArray, for: indexPath.section)
        let hostnameContent = layoutArray[hostname]![indexPath.row]
        didSelectItem(stringURL: hostnameContent)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let hostname = fetchHostnameFromSection(folderList: layoutArray, for: indexPath.section)
            guard let hostnameContent = layoutArray[hostname]?[indexPath.row] else { return }
            guard let newItemHostname = URLComponents(string: hostnameContent)?.host else { return }
            
            urlArray = urlArray.filter { $0 != hostnameContent }
            if let layoutKey = aliasArray.first(where: { $0.value == newItemHostname })?.key {
                layoutArray[layoutKey] = urlArray.filter {$0.contains(newItemHostname)}
            } else {
                layoutArray[newItemHostname] = urlArray.filter {$0.contains(newItemHostname)}
            }
            checkForEmptyHostname()
            
            userDefaults.set(urlArray, forKey: kVLCRecentFavoriteURL)
            if layoutArray[hostname] == nil {
                let sectionToDelete = IndexSet(arrayLiteral: indexPath.section)
                tableView.deleteSections(sectionToDelete, with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
}

extension VLCFavoriteListViewController: FavoriteSectionHeaderDelegate {
    @objc func receiveNotification(notif: NSNotification) {
        if let folder = notif.userInfo?["Folder"] as? VLCNetworkServerBrowserItem {
            guard let newItemURL = folder.url?.absoluteString else { return }
            guard let newItemHostname = URLComponents(string: newItemURL)?.host else { return }
            
            if let indexToRemove = urlArray.firstIndex(of: newItemURL) {
                urlArray.remove(at: indexToRemove)
            }
            else {
                urlArray.append(newItemURL)
            }
            if let layoutKey = aliasArray.first(where: { $0.value == newItemHostname })?.key {
                layoutArray[layoutKey] = urlArray.filter {$0.contains(newItemHostname)}
            } else {
                layoutArray[newItemHostname] = urlArray.filter {$0.contains(newItemHostname)}
            }
        }
        
        userDefaults.set(urlArray, forKey: kVLCRecentFavoriteURL)
        checkForEmptyHostname()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func fetchHostnameFromSection(folderList dict: [String: [String]], for section: Int) -> String {
        let keys = dict.index(dict.startIndex, offsetBy: section)
        let hostname = dict.keys[keys]
        return hostname
    }
    
    func checkForEmptyHostname() {
        for (key, _) in layoutArray {
            if layoutArray[key]?.isEmpty == true {
                layoutArray.removeValue(forKey: key)
            }
        }
    }
    
    func didSelectItem(stringURL: String) {
        guard let url = URL(string: stringURL) else { return }
        let vlcMedia = VLCMedia(url: url)
        let serverBrowser = VLCNetworkServerBrowserVLCMedia(media: vlcMedia)
        if let serverBrowserVC = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser, medialibraryService: VLCAppCoordinator().mediaLibraryService) {
            self.navigationController?.pushViewController(serverBrowserVC, animated: true)
        }
    }
    
    @objc func themeDidChange() {
        self.tableView.backgroundColor = PresentationTheme.current.colors.background
        DispatchQueue.main.async { self.tableView.reloadData() }
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func renameSection(with oldTitle: String) {
        let alertController = UIAlertController(title:  NSLocalizedString("BUTTON_RENAME", comment: ""), message: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), oldTitle), preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = oldTitle
            textField.text = oldTitle
        }
        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                          style: .cancel)
        let confirmAction = UIAlertAction(title:  NSLocalizedString("BUTTON_RENAME", comment: ""),
                                          style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let alertTextField = alertController.textFields?.first else { return }
            guard let textfieldValue = alertTextField.text else { return }
            
            let folderFromHostname = self.layoutArray[oldTitle]
            self.layoutArray.removeValue(forKey: oldTitle)
            self.layoutArray[textfieldValue] = folderFromHostname
            
            if self.aliasArray[oldTitle] != nil {
                let originalHostname = self.aliasArray[oldTitle]
                self.aliasArray.removeValue(forKey: oldTitle)
                self.aliasArray[textfieldValue] = originalHostname
            } else {
                self.aliasArray[textfieldValue] = oldTitle
            }
            self.userDefaults.setValue(self.aliasArray, forKey: kVLCFavoriteGroupAlias)
            
            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(0...self.layoutArray.count-1), with: .automatic)
            }
        }
        
        let resetButton = UIAlertAction(title: "Reset", style: .default) { _ in
            guard let favoredFolder = self.layoutArray[oldTitle] else { return }
            
            let component = URLComponents(string: favoredFolder[0])
            guard let originalName = component?.host else { return }
            self.layoutArray[originalName] = self.layoutArray[oldTitle]
            self.layoutArray.removeValue(forKey: oldTitle)
            self.aliasArray.removeValue(forKey: oldTitle)
            self.userDefaults.setValue(self.aliasArray, forKey: kVLCFavoriteGroupAlias)
            
            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(0...self.layoutArray.count-1), with: .automatic)
            }
        }
        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)
        alertController.addAction(resetButton)
        
        present(alertController, animated: true)
    }
}
