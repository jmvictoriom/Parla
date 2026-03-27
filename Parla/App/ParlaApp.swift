import SwiftUI

@main
struct ParlaApp: App {

    @State private var showSplash = true

    init() {
        UIWindow.appearance().backgroundColor = .systemGroupedBackground
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                TranslatorView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView {
                        withAnimation {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
