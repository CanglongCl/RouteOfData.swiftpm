import SwiftUI
import SwiftData

@available(iOS 17, *)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if DEBUG
        .modelContainer(previewContainer)
        #else
        .modelContainer(for: [
            Route.self,
            Node.self
        ])
        #endif
    }
}
