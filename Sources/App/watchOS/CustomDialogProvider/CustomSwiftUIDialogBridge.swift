//
//  CustomSwiftUIDialogObjCBridge.swift
//  VLC-watchOS
//
//  Created by Fahri Novaldi on 20/08/25.
//  Copyright © 2025 VideoLAN. All rights reserved.
//

import Foundation
import SwiftUI

@objc
class CustomSwiftUIDialogObjCBridge: NSObject {

    @objc
    func showErrorDialog(title: String, message: String) {
        DispatchQueue.main.async {
            CustomSwiftUIDialogProvider.shared.show {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title2)

                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    Button("OK") {
                        CustomSwiftUIDialogProvider.shared.dismiss()
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
    }

    @objc
    func showQuestionDialog(
        title: String, message: String, titleAction1: String, titleAction2: String,
        action1: @escaping () -> Void, action2: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            CustomSwiftUIDialogProvider.shared.show {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 8) {
                        Button(titleAction1) {
                            CustomSwiftUIDialogProvider.shared.dismiss()
                            action1()
                        }
                        .foregroundColor(.blue)

                        Button(titleAction2) {
                            CustomSwiftUIDialogProvider.shared.dismiss()
                            action2()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .shadow(radius: 8)
            }
        }
    }

    @objc
    func dismissDialog() {
        DispatchQueue.main.async {
            CustomSwiftUIDialogProvider.shared.dismiss()
        }
    }

    // MARK: - Convenience methods for VLCPlaybackService integration

    @objc
    func showNetworkErrorDialog() {
        showErrorDialog(
            title: "Network Error",
            message: "Unable to connect to the network. Please check your connection."
        )
    }

    @objc
    func showPlaybackStoppedDialog() {
        showErrorDialog(title: "Playback Stopped", message: "Media playback has been interrupted.")
    }

    // MARK: - Continue Playback Dialog
    
    @objc
    func showContinuePlaybackDialog(mediaTitle: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            CustomSwiftUIDialogProvider.shared.show {
                ScrollView {
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text(NSLocalizedString("CONTINUE_PLAYBACK", comment: ""))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text(String(format: NSLocalizedString("CONTINUE_PLAYBACK_LONG", comment: ""), mediaTitle))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Button(NSLocalizedString("BUTTON_CONTINUE", comment: "")) {
                                CustomSwiftUIDialogProvider.shared.dismiss()
                                completion(true)
                            }
                            
                            Button(NSLocalizedString("BUTTON_CANCEL", comment: "")) {
                                CustomSwiftUIDialogProvider.shared.dismiss()
                                completion(false)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.9))
            }
        }
    }
}
