//
//  VLCWatchOSApp.swift
//  VLC-watchOS
//
//  Created by Fahri Novaldi on 10/06/25.
//  Copyright © 2025 VideoLAN. All rights reserved.
//

import SwiftUI

@main
struct VLCWatchOSApp: App {
    private let appCoordinator = VLCAppCoordinator.sharedInstance()
    @StateObject private var dialogProvider = CustomSwiftUIDialogProvider.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dialogProvider)
                .customDialogOverlay()
        }
    }
}
