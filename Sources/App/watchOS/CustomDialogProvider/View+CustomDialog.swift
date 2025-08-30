//
//  View+CustomDialog.swift
//  VLC-watchOS
//
//  Created by Fahri Novaldi on 20/08/25.
//  Copyright © 2025 VideoLAN. All rights reserved.
//

import SwiftUI

extension View {
    func customDialogOverlay() -> some View {
        self.modifier(DialogOverlay())
    }
}

// This modifier adds a custom dialog overlay to the view. It listens for dialog changes and displays the dialog content when it is presented.
fileprivate struct DialogOverlay: ViewModifier {
    @ObservedObject private var dialogProvider = CustomSwiftUIDialogProvider.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if dialogProvider.isPresented, let dialog = dialogProvider.currentDialog {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if dialog.dismissible {
                            dialogProvider.dismiss()
                        }
                    }
                
                dialog.content
                    .scaleEffect(dialogProvider.isPresented ? 1.0 : 0.6)
                    .opacity(dialogProvider.isPresented ? 1.0 : 0.0)
                    .transition(.scale)}
        }
    }
}
