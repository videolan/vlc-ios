//
//  Coordinator.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 12/1/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

import Foundation

struct Services {

}
/// The Coordinator protocol
protocol Coordinator: class {
    /// The services that the coordinator can use
    var services: Services { get }
    /// The array containing any child Coordinators
    var childCoordinators: [Coordinator] { get set }
}

extension Coordinator {

    /// Add a child coordinator to the parent
    func addChildCoordinator(childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }

    /// Remove a child coordinator from the parent
    func removeChildCoordinator(childCoordinator: Coordinator) {
        self.childCoordinators = self.childCoordinators.filter { $0 !== childCoordinator }
    }
}
