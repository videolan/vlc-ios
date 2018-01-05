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

@objc(VLCRemoteNetworkDataSource)
public class RemoteNetworkDataSource:NSObject, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let wifiCell =  tableView.dequeueReusableCell(withIdentifier: VLCWiFiUploadTableViewCell.cellIdentifier()) {
            return wifiCell
        }
        return UITableViewCell()
    }
}
