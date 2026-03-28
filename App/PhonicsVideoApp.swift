import SwiftUI

@main
struct PhonicsVideoApp: App {
    @StateObject private var libraryStore = LibraryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(libraryStore)
        }
    }
}

