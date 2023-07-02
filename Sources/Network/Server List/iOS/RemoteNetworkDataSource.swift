/*****************************************************************************
 * RemoteNetworkDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

enum RemoteNetworkCellType: Int {
    @available(iOS 11.0, *)
    case local
    case cloud
    case streaming
    case download
    case wifi
    case favorite
    static let first: Int = {
        if let _ = RemoteNetworkCellType(rawValue: 0) {
            return 0
        } else {
            return 1
        }
    }()
    static let count: Int = {
        var max: Int = first
        while let _ = RemoteNetworkCellType(rawValue: max) { max += 1 }
        return max - first
    }()
}

@objc(VLCRemoteNetworkDataSourceDelegate)
protocol RemoteNetworkDataSourceDelegate {
    func showViewController(_ viewController: UIViewController)
    func showDocumentPickerViewController(_ viewController: UIDocumentPickerViewController)
    func reloadRemoteTableView()
}

@objc(VLCRemoteNetworkDataSourceAndDelegate)
class RemoteNetworkDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let localVC = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
    let cloudVC = VLCCloudServicesTableViewController(nibName: "VLCCloudServicesTableViewController", bundle: Bundle.main)
    let streamingVC = VLCOpenNetworkStreamViewController(nibName: "VLCOpenNetworkStreamViewController", bundle: Bundle.main)
    let downloadVC = VLCDownloadViewController(nibName: "VLCDownloadViewController", bundle: Bundle.main)
    let favoriteVC = VLCFavoriteListViewController()

    @objc weak var delegate: RemoteNetworkDataSourceDelegate?

    // MARK: - DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RemoteNetworkCellType.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = RemoteNetworkCellType(rawValue: indexPath.row + RemoteNetworkCellType.first) else {
            assertionFailure("We're having more rows than types of cells that should never happen")
            return UITableViewCell()
        }
        switch cellType {
        case .local:
            if let localFilesCell = tableView.dequeueReusableCell(withIdentifier: ExternalMediaProviderCell.cellIdentifier) {
                localFilesCell.textLabel?.text = NSLocalizedString("FILES_APP_CELL_TITLE", comment: "")
                localFilesCell.detailTextLabel?.text = NSLocalizedString("FILES_APP_CELL_SUBTITLE", comment: "")
                localFilesCell.imageView?.image = UIImage(named: "homeLocalFiles")?.withRenderingMode(.alwaysTemplate)
                localFilesCell.accessibilityIdentifier = VLCAccessibilityIdentifier.local
                return localFilesCell
            }
        case .cloud:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = cloudVC.title
                networkCell.detailTextLabel?.text = cloudVC.detailText
                networkCell.imageView?.image = cloudVC.cellImage
                networkCell.accessibilityIdentifier = VLCAccessibilityIdentifier.cloud
                return networkCell
            }
        case .streaming:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = streamingVC.title
                networkCell.detailTextLabel?.text = streamingVC.detailText
                networkCell.imageView?.image = streamingVC.cellImage
                networkCell.accessibilityIdentifier = VLCAccessibilityIdentifier.stream
                return networkCell
            }
        case .download:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = downloadVC.title
                networkCell.detailTextLabel?.text = downloadVC.detailText
                networkCell.imageView?.image = downloadVC.cellImage
                networkCell.accessibilityIdentifier = VLCAccessibilityIdentifier.downloads
                return networkCell
            }
        case .wifi:
            if let wifiCell = tableView.dequeueReusableCell(withIdentifier: VLCWiFiUploadTableViewCell.cellIdentifier()) as? VLCWiFiUploadTableViewCell {
                wifiCell.delegate = self
                return wifiCell
            }
        case .favorite:
            if let favoriteCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                favoriteCell.textLabel?.text = favoriteVC.title
                favoriteCell.detailTextLabel?.text = favoriteVC.detailText
                favoriteCell.imageView?.image = favoriteVC.cellImage
                favoriteCell.accessibilityIdentifier = VLCAccessibilityIdentifier.favorite
                return favoriteCell
            }
        }
        assertionFailure("Cell is nil, did you forget to register the identifier?")
        return UITableViewCell()
    }

    // MARK: - Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let vc = viewController(indexPath: indexPath) {
            if let vc = vc as? UIDocumentPickerViewController {
                delegate?.showDocumentPickerViewController(vc)
            } else {
                delegate?.showViewController(vc)
            }
        } else if RemoteNetworkCellType(rawValue: indexPath.row + RemoteNetworkCellType.first) == .wifi {
            if tableView.cellForRow(at: indexPath)?.selectionStyle == .default {
                UIPasteboard.general.string = VLCHTTPUploaderController.sharedInstance().addressToCopy()
                UIAlertController.autoDismissable(title: NSLocalizedString("WEBINTF_TITLE", comment: ""),
                                                  message: NSLocalizedString("WEBINTF_ADDRESS_COPIED", comment: ""))
            }
        }
    }

    @objc func viewController(indexPath: IndexPath) -> UIViewController? {
        guard let cellType = RemoteNetworkCellType(rawValue: indexPath.row + RemoteNetworkCellType.first) else {
            assertionFailure("We're having more rows than types of cells that should never happen")
            return nil
        }
        switch cellType {
        case .local:
            return localVC
        case .cloud:
            return cloudVC
        case .streaming:
            return streamingVC
        case .download:
            return downloadVC
        case .wifi:
            return nil
        case .favorite:
            return favoriteVC
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellType = RemoteNetworkCellType(rawValue: indexPath.row + RemoteNetworkCellType.first) else {
            assertionFailure("We're having more rows than types of cells that should never happen")
            return UITableView.automaticDimension
        }

        if cellType == .wifi && !UIDevice.current.systemVersion.hasPrefix("9.") {
            return UITableView.automaticDimension
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExternalMediaProviderCell.cellIdentifier) as? ExternalMediaProviderCell else {
            return UITableView.automaticDimension
        }

        let textLabelHeight = cell.textLabel?.font.lineHeight
        let detailLabelHeight = cell.detailTextLabel?.font.lineHeight
        var size = 0.0

        if let textLabelHeight = textLabelHeight {
            size += textLabelHeight
        }

        if let detailLabelHeight = detailLabelHeight {
            size += detailLabelHeight
        }

        return size + ExternalMediaProviderCell.edgePadding + (ExternalMediaProviderCell.interItemPadding * 2)
    }

    @objc func numberOfRemoteNetworkCellTypes() -> Int {
        return RemoteNetworkCellType.count
    }
}

extension RemoteNetworkDataSource: VLCWiFiUploadTableViewCellDelegate {
    func updateTableViewHeight() {
        delegate?.reloadRemoteTableView()
    }
}
