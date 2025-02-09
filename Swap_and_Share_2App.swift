//
//  Swap_and_Share_2App.swift
//  Swap and Share 2
//
//  Created by Carl Hockings on 22/11/24.
//

import SwiftUI
import CoreData

@main
struct Swap_and_Share_2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
