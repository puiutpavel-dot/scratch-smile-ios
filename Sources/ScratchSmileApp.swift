import SwiftUI

@main
struct ScratchSmileApp: App {
    var body: some Scene {
        WindowGroup {
            LobbyScreen()
                .preferredColorScheme(.dark)     // aplicația are propriul fundal întunecat
        }
    }
}
