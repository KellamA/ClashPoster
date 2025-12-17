//
//  ClashPosterApp.swift
//  ClashPoster
//
//  Created by Kellam Adams on 12/17/25.
//

import SwiftUI

@main
struct ClashPosterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
