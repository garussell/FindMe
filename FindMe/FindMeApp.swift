//
//  FindMeApp.swift
//  FindMe
//
//  Created by Allen Russell on 3/17/26.
//

import SwiftUI
import SwiftData

@main
struct FindMeApp: App {
    @State private var container = AppContainer.makeLive()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedJob.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
        }
        .modelContainer(sharedModelContainer)
    }
}
