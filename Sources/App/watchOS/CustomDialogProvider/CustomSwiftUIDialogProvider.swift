//
//  CustomSwiftUIDialogProvider.swift
//  VLC-watchOS
//
//  Created by Fahri Novaldi on 20/08/25.
//  Copyright © 2025 VideoLAN. All rights reserved.
//

import SwiftUI

@MainActor
class CustomSwiftUIDialogProvider: ObservableObject {
    
    static let shared: CustomSwiftUIDialogProvider = CustomSwiftUIDialogProvider(
        animation: Animation.bouncy(duration: 0.1),
        duration: 0.1
    )
    
    @Published var currentDialog: CustomDialogItem?
    @Published var isPresented: Bool = false
    
    let animation: Animation
    let duration: TimeInterval
    
    init(animation: Animation, duration: TimeInterval) {
        self.animation = animation
        self.duration = duration
    }
    
    func show<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        show(dismissible: true, content)
    }
    
    func show<Content: View>(dismissible: Bool, @ViewBuilder _ content: @escaping () -> Content) {
        withAnimation(animation) {
            currentDialog = CustomDialogItem(content, dismissible: dismissible)
            isPresented = true
        }
    }
    
    func dismiss() {
        withAnimation(animation) {
            isPresented = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.currentDialog = nil
        }
    }
}


// MARK: - DialogItem object
struct CustomDialogItem: Identifiable {
    let id = UUID()
    let content: AnyView
    let dismissible: Bool
    
    init<Content: View>(@ViewBuilder _ content: @escaping () -> Content, dismissible: Bool = true) {
        self.content = AnyView(content())
        self.dismissible = dismissible
    }
}
