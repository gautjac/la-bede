import SwiftUI
import SwiftData

@main
struct LaBedeApp: App {
    /// One SwiftData container for the Recueil of strips.
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Strip.self)
        } catch {
            // A diary that can't persist is useless — fail loudly in dev.
            fatalError("Impossible de créer le stockage SwiftData : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, *) {
                RootView()
                    .tint(Theme.pop)
            } else {
                // The whole app targets iOS 26; this branch never ships but keeps
                // the availability checker happy and degrades gracefully.
                UnsupportedOSView()
            }
        }
        .modelContainer(container)
    }
}

/// Shown only on the impossible sub-26 path. Honest, not a crash.
struct UnsupportedOSView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("La Bédé").font(.system(size: 34, weight: .black, design: .rounded))
            Text("La Bédé a besoin d'iOS 26 ou plus récent.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.99, green: 0.93, blue: 0.78))
    }
}
