/*****************************************************************************
 * RemoteNetworkDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
import Foundation

enum RemoteNetworkCellType: Int {
    case cloud = 0, wifi
    static let count: Int = 2
}

@objc(VLCRemoteNetworkDataSourceDelegate)
protocol RemoteNetworkDataSourceDelegate {
    func showViewController(_ viewController: UIViewController)
}
@objc(VLCRemoteNetworkDataSourceAndDelegate)
public class RemoteNetworkDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let cloudVC = VLCCloudServicesTableViewController(nibName: "VLCCloudServicesTableViewController", bundle: Bundle.main)
    @objc weak var delegate: RemoteNetworkDataSourceDelegate?

    @objc public let height = RemoteNetworkCellType.count * 55

    // MARK: - DataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RemoteNetworkCellType.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = RemoteNetworkCellType(rawValue: indexPath.row) else {
            assertionFailure("We're having more rows than types of cells that should never happen")
            return UITableViewCell()
        }
        switch cellType {
        case .cloud:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: VLCRemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = cloudVC.title
                networkCell.detailTextLabel?.text = cloudVC.detailText
                networkCell.imageView?.image = cloudVC.cellImage
                return networkCell
            }

        case .wifi:
            if let wifiCell = tableView.dequeueReusableCell(withIdentifier: VLCWiFiUploadTableViewCell.cellIdentifier()) {
                return wifiCell
            }
        }
        assertionFailure("Cell is nil, did you forget to register the identifier?")
        return UITableViewCell()
    }

    // MARK: - Delegate
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return RemoteNetworkCellType(rawValue: indexPath.row) == .wifi ? nil : indexPath
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let vc = viewController(indexPath: indexPath) {
            delegate?.showViewController(vc)
        }
    }
    
    @objc func viewController(indexPath: IndexPath) -> UIViewController? {
        guard let cellType = RemoteNetworkCellType(rawValue: indexPath.row) else {
            assertionFailure("We're having more rows than types of cells that should never happen")
            return nil
        }
        switch cellType {
        case .cloud:
            return cloudVC
        case .wifi:
            assertionFailure("We shouldn't get in here since we return nil in willSelect")
            return nil
        }
    }
}
