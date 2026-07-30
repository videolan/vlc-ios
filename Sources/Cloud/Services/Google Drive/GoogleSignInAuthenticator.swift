/*****************************************************************************
 * GoogleSignInAuthenticator.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import GoogleSignIn

@objc(VLCGoogleSignInAuthenticator)
class GoogleSignInAuthenticator: NSObject {
    @objc class func create() -> GoogleSignInAuthenticator {
        return GoogleSignInAuthenticator()
    }

    @objc class func signIn(_ signIn: GIDSignIn, presentingView: VLCGoogleDriveTableViewController) {
        signIn.configuration = GIDConfiguration(clientID: kVLCGoogleDriveClientID)

        signIn.signIn(withPresenting: presentingView,
                      hint: nil,
                      additionalScopes: [kGTLRAuthScopeDriveReadonly]) { signInResult, error in
            guard error == nil, let result = signInResult else {
                return
            }

            guard result.user.grantedScopes?.contains(kGTLRAuthScopeDriveReadonly) == true else {
                return
            }

            presentingView.setAuthorizerAndUpdate()
        }
    }
}
