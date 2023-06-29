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
        NotificationCenter.default.addObserver(self, selector: #selector(receiveNotification), name: Notification.Name((NSString("AddedToFavorite")) as String), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: NSNotification.Name(kVLCThemeDidChangeNotification), object: nil)
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
    
    var favoriteArray: [VLCNetworkServerBrowserItem] = []
    var titleArray: [String] = []
    var urlArray: [String] = []
    let keyValueStore = NSUbiquitousKeyValueStore.default
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        title = "Favorite"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "VLCNetworkListCell", bundle: nil), forCellReuseIdentifier: "LocalNetworkCell")
        tableView.backgroundColor = PresentationTheme.current.colors.background
        if let titleArray = userDefaults.stringArray(forKey: kVLCRecentFavoriteTitle) {
            self.titleArray = titleArray
        }
        
        if let urlArray = userDefaults.stringArray(forKey: kVLCRecentFavoriteURL) {
            self.urlArray = urlArray
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func setupConstraints() {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalNetworkCell", for: indexPath) as! VLCNetworkListCell
        let title = titleArray[indexPath.row]
        let url = urlArray[indexPath.row]
        
        cell.icon = UIImage(named: "folder")
        cell.title = title
        cell.subtitle = url
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let networkCell = cell as? VLCNetworkListCell {
            networkCell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectItem(stringURL: urlArray[indexPath.row])
    }
}

extension VLCFavoriteListViewController {
    @objc func receiveNotification(notif: NSNotification) {
        var indexToRemove: Int? = nil
        if let folder = notif.userInfo?["Folder"] as? VLCNetworkServerBrowserItem {
            for (index, element) in titleArray.enumerated() {
                if folder.name == element {
                    indexToRemove = index
                    break
                }
            }
            if indexToRemove != nil {
                titleArray.remove(at: indexToRemove!)
                urlArray.remove(at: indexToRemove!)
            } else {
                titleArray.append(folder.name)
                if let url = folder.media?.url { urlArray.append(url.absoluteString) }
            }
        }
        userDefaults.set(titleArray, forKey: kVLCRecentFavoriteTitle)
        userDefaults.set(urlArray, forKey: kVLCRecentFavoriteURL)
    }
    
    func didSelectItem(stringURL: String) {
        guard let url = URL(string: stringURL) else { return }
        let vlcMedia = VLCMedia(url: url)
        let serverBrowser = VLCNetworkServerBrowserVLCMedia(media: vlcMedia)
        if let x = VLCNetworkServerBrowserViewController(serverBrowser: serverBrowser) {
            self.navigationController?.pushViewController(x, animated: true)
        }
    }
    
    @objc func themeDidChange() {
        self.tableView.backgroundColor = PresentationTheme.current.colors.background
        self.setNeedsStatusBarAppearanceUpdate()
    }
}
