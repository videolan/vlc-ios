/*****************************************************************************
 * GoogleSignInAuthenticator.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import GoogleSignIn

@objc (VLCGoogleSignInAuthenticator)
class GoogleSignInAuthenticator: NSObject {
    @objc class func create() -> GoogleSignInAuthenticator {
        return GoogleSignInAuthenticator()
    }

    @objc class func signIn(_ signIn: GIDSignIn, presentingView: VLCGoogleDriveTableViewController) {
        let configuration = GIDConfiguration(clientID: kVLCGoogleDriveClientID)

        signIn.addScopes([kVLCGoogleDriveScope], presenting: presentingView, callback: nil)

        signIn.signIn(with: configuration, presenting: presentingView, callback: { user, error in
            if error != nil {
                return
            }

            if let user = user,
               let grantedScopes = user.grantedScopes,
               grantedScopes.contains(kVLCGoogleDriveScope) {
                presentingView.setAuthorizerAndUpdate()
            }
        })
    }
}
