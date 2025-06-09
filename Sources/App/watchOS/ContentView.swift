//
//  ContentView.swift
//  VLC-watchOS
//
//  Created by Fahri Novaldi on 10/06/25.
//  Copyright © 2025 VideoLAN. All rights reserved.
//

import SwiftUI
import VLCKit

struct ContentView: View {
    let vlcObject = VLCMediaPlayer()
    
    var body: some View {
        VStack {
            Image(systemName: "cone")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world! from VLC WatchOS")
                .onAppear {
                    // This is a simple test to ensure that VLCKit is properly linked and can be used in the watchOS app.
                    let sampleObjectFromVLCKit = VLCMedia()

                    print("Sample object from VLCKit: \(sampleObjectFromVLCKit)")
                    // This is just to ensure that VLCKit is properly linked and can be used.
                }
            Text("media player: \(vlcObject)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
