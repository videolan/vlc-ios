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
import MobileCoreServices

enum RemoteNetworkCellType: Int {
    @available(iOS 11.0, *)
    case local
#if os(iOS)
    case cloud
#endif
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
#if os(iOS)
        case .cloud:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = NSLocalizedString("CLOUD_SERVICES", comment: "")
                networkCell.detailTextLabel?.text = NSLocalizedString("CLOUDVC_DETAILTEXT", comment: "")
                networkCell.imageView?.image = UIImage(named: "iCloudIcon")
                networkCell.accessibilityIdentifier = VLCAccessibilityIdentifier.cloud
                return networkCell
            }
#endif
        case .streaming:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = NSLocalizedString("OPEN_NETWORK", comment: "")
                networkCell.detailTextLabel?.text = NSLocalizedString("STREAMVC_DETAILTEXT", comment: "")
                networkCell.imageView?.image = UIImage(named: "OpenNetStream")
                networkCell.accessibilityIdentifier = VLCAccessibilityIdentifier.stream
                return networkCell
            }
        case .download:
            if let networkCell = tableView.dequeueReusableCell(withIdentifier: RemoteNetworkCell.cellIdentifier) {
                networkCell.textLabel?.text = NSLocalizedString("DOWNLOAD_FROM_HTTP", comment: "")
                networkCell.detailTextLabel?.text = NSLocalizedString("DOWNLOADVC_DETAILTEXT", comment: "")
                networkCell.imageView?.image = UIImage(named: "Downloads")
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
                favoriteCell.textLabel?.text = NSLocalizedString("FAVORITES", comment: "")
                favoriteCell.detailTextLabel?.text = NSLocalizedString("FAVORITEVC_DETAILTEXT", comment: "")
                favoriteCell.imageView?.image = UIImage(named: "heart")
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
        ParentalControlCoordinator.shared.authorizeIfParentalControlIsEnabled {
            if let vc = self.viewController(indexPath: indexPath) {
                if let vc = vc as? UIDocumentPickerViewController {
                    self.delegate?.showDocumentPickerViewController(vc)
                } else {
                    self.delegate?.showViewController(vc)
                }
            } else if RemoteNetworkCellType(rawValue: indexPath.row + RemoteNetworkCellType.first) == .wifi {
                if tableView.cellForRow(at: indexPath)?.selectionStyle == .default {
                    UIPasteboard.general.string = VLCAppCoordinator.sharedInstance().httpUploaderController.addressToCopy()
                    UIAlertController.autoDismissable(title: NSLocalizedString("WEBINTF_TITLE", comment: ""),
                                                      message: NSLocalizedString("WEBINTF_ADDRESS_COPIED", comment: ""))
                }
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
            if #available(iOS 14.0, *) {
                return UIDocumentPickerViewController(forOpeningContentTypes: [.item, .folder], asCopy: false)
            } else {
                return UIDocumentPickerViewController(documentTypes: ["public.item", "public.folder"], in: .open)
            }
#if os(iOS)
        case .cloud:
            return VLCCloudServicesTableViewController(nibName: "VLCCloudServicesTableViewController", bundle: Bundle.main)
#endif
        case .streaming:
            return VLCOpenNetworkStreamViewController(nibName: "VLCOpenNetworkStreamViewController", bundle: Bundle.main)
        case .download:
            return VLCDownloadViewController(nibName: "VLCDownloadViewController", bundle: Bundle.main)
        case .wifi:
            return nil
        case .favorite:
            return FavoriteListViewController()
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
