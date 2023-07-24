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
        let notificationCenter = NotificationCenter.default
        urlArray = userDefaults.stringArray(forKey: kVLCRecentFavoriteURL) ?? []
        hostnameArray = []
        layoutArray = [:]
        
        for urlItem in urlArray {
            let component = URLComponents(string: urlItem)
            if let hostNameValue = component?.host { hostnameArray.insert(hostNameValue) }
        }
        
        for hostname in hostnameArray {
            layoutArray[hostname] = urlArray.filter { $0.contains(hostname) }
        }

        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("FAVORITE", comment: "")
        
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
    var urlArray: [String]
    var hostnameArray: Set<String>
    var layoutArray: [String: [String]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = PresentationTheme.current.colors.background
        tableView.register(UINib(nibName: "VLCNetworkListCell", bundle: nil), forCellReuseIdentifier: "LocalNetworkCell")
        tableView.register(FavoriteSectionHeader.self, forHeaderFooterViewReuseIdentifier: FavoriteSectionHeader.identifier)
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
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
            
            urlArray = urlArray.filter { $0 != hostnameContent }
            layoutArray[hostname] = urlArray.filter { $0.contains(hostname) }
            
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
                hostnameArray.insert(newItemHostname)
            }
            layoutArray[newItemHostname] = urlArray.filter {$0.contains(newItemHostname)}
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
        var deletedHostname: [String] = []
        hostnameArray.forEach { hostname in
            if let favoredArray = layoutArray[hostname] {
                if favoredArray.isEmpty { deletedHostname.append(hostname) }
            }
        }
        deletedHostname.forEach { hostname in
            hostnameArray.remove(hostname)
            layoutArray.removeValue(forKey: hostname)
        }
    }
        
    func didSelectItem(stringURL: String) {
        guard let url = URL(string: stringURL) else { return }
        let vlcMedia = VLCMedia(url: url)
        let serverBrowser = VLCNetworkServerBrowserVLCMedia(media: vlcMedia)
        if let serverBrowserVC = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser) {
            self.navigationController?.pushViewController(serverBrowserVC, animated: true)
        }
    }
    
    @objc func themeDidChange() {
        self.tableView.backgroundColor = PresentationTheme.current.colors.background
        DispatchQueue.main.async { self.tableView.reloadData() }
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func renameSection(with oldTitle: String) {
        let alertController = UIAlertController(title: "Rename", message: "Rename Hostname", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = oldTitle
            textField.text = oldTitle
        }
        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                          style: .cancel)
        let confirmAction = UIAlertAction(title: "Rename",
                                          style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let alertTextField = alertController.textFields?.first else { return }
            print(alertTextField.text ?? "")
            self.hostnameArray.remove(oldTitle)
            self.hostnameArray.insert(alertTextField.text ?? "")
            let folderFromHostname = self.layoutArray[oldTitle]
            self.layoutArray.removeValue(forKey: oldTitle)
            self.layoutArray[alertTextField.text!] = folderFromHostname
            
            self.tableView.reloadSections([0,1], with: .automatic)
        }
        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true)
    }
}
