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
    @EnvironmentObject var dialogProvider: CustomSwiftUIDialogProvider
    
    let dialogBridge: CustomSwiftUIDialogObjCBridge = CustomSwiftUIDialogObjCBridge()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "cone")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                // Test shared-localizable strings
                Text(NSLocalizedString("CHOOSE_CHAPTER", comment: ""))
                    .onAppear {
                        // This is a simple test to ensure that VLCKit is properly linked and can be used in the watchOS app.
                        let sampleObjectFromVLCKit = VLCMedia()
                        
                        print("Sample object from VLCKit: \(sampleObjectFromVLCKit)")
                        // This is just to ensure that VLCKit is properly linked and can be used.
                    }
                
                VStack(spacing: 12) {
                    Button("Show play-pause dialog") {
                        dialogBridge.showContinuePlaybackDialog(mediaTitle: "Sample song") { shouldContinue in
                            print("User chose to \(shouldContinue ? "continue" : "not continue") playback.")
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Show Dialog") {
                        dialogProvider.show {
                            VStack(spacing: 12) {
                                Text("This is a custom dialog")
                                    .font(.headline)
                                
                                Button("Dismiss") {
                                    dialogProvider.dismiss()
                                }
                            }
                            .ignoresSafeArea()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Test Error Dialog (objc)") {
                        dialogBridge.showErrorDialog(title: "Error", message: "This is a test error dialog from Objective-C bridge.")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
