import SwiftUI

/// Full-screen iPod shell. The chrome geometry is OldOS' (60pt bars, 57pt tab
/// bar, 110pt Now Playing controls) laid out against the real device safe
/// areas, so bars extend behind the status bar / Dynamic Island and the
/// home indicator. The skin follows the system Light / Dark appearance.
struct OldMusicRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var library = MusicLibrary()
    @StateObject private var navigator = MusicNavigator()
    @StateObject private var safeArea = OldMusicSafeArea()

    var body: some View {
        GeometryReader { geometry in
            let topInset = max(geometry.safeAreaInsets.top, safeArea.insets.top)
            let bottomInset = max(geometry.safeAreaInsets.bottom, safeArea.insets.bottom)

            ZStack {
                Color.black

                switch navigator.screen {
                case .library:
                    MusicLibraryScreen(topInset: topInset, bottomInset: bottomInset)
                        .transition(screenSlide)
                case .nowPlaying:
                    MusicNowPlayingView(topInset: topInset, bottomInset: bottomInset)
                        .transition(screenSlide)
                case .coverFlow:
                    MusicCoverFlowView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear { safeArea.refresh() }
        }
        .ignoresSafeArea()
        .environment(\.oldMusicTheme, theme)
        .environmentObject(library)
        .environmentObject(navigator)
        .onAppear(perform: updateStatusBar)
        .onChange(of: navigator.screen) { _ in updateStatusBar() }
        .onChange(of: colorScheme) { _ in updateStatusBar() }
    }

    private var theme: OldMusicTheme {
        OldMusicTheme.theme(for: colorScheme)
    }

    private var screenSlide: AnyTransition {
        let forward = navigator.movingForward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }

    private func updateStatusBar() {
        MusicStatusBar.shared.update(screen: navigator.screen, isDark: colorScheme == .dark)
    }
}
