import SwiftUI
import SwiftData

/// Two tabs: write today's strip, and browse the Recueil. Comic-book chrome.
@available(iOS 26.0, *)
struct RootView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView {
            Tab("Aujourd'hui", systemImage: "pencil.and.scribble") {
                CaptureView()
            }
            Tab("Recueil", systemImage: "books.vertical.fill") {
                RecueilView()
            }
        }
        .tint(Theme.pop)
    }
}
