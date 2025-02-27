//
//  BowlingStatsApp.swift
//  BowlingStats
//
//  Created by David on 2/26/25.
//

import SwiftUI

@main
struct BowlingStatsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
