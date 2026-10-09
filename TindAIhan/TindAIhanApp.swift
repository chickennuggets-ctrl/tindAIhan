//
//  TindAIhanApp.swift
//  TindAIhan
//
//  Created by Pao's Macbook Pro on 10/10/26.
//

import SwiftUI
import SwiftData

@main
struct TindAIhanApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: LedgerEntry.self)
    }
}
