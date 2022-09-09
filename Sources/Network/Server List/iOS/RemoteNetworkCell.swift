/*****************************************************************************
 * RemoteNetworkCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc(VLCRemoteNetworkCell)
class RemoteNetworkCell: ExternalMediaProviderCell {
    override func commonInit() {
        accessoryType = .disclosureIndicator
        super.commonInit()
    }
}
