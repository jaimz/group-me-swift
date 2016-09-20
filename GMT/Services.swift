//
//  Services.swift
//  GMT
//
//  Created by James O'Brien on 20/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation

/// Singleton to organise app-wide "services"
class Services {
    let navigator = AppStateNavigationController(rootViewController: ConversationsViewController())

    static let instance = Services();
}