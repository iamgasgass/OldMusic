import SwiftUI
import MediaPlayer

/// Full-screen iPod shell. The chrome geometry is OldOS' (60pt bars, 57pt tab
/// bar, 110pt Now Playing controls) laid out against the real device safe
/// areas, so bars extend behind the status bar / Dynamic Island and the
/// home indicator. The skin follows More › Aspect UI (Sistema / Chiaro / Scuro).
struct OldMusicRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var library = MusicLibrary()
    @StateObject private var navigator = MusicNavigator()
    @StateObject private var safeArea = OldOSSafeArea()
    @ObservedObject private var settings = MusicSettings.shared

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

                if let song = navigator.actionSong, navigator.screen != .coverFlow {
                    OldOSActionSheet(
                        theme: theme,
                        buttons: actionButtons(for: song),
                        bottomInset: bottomInset,
                        onCancel: { navigator.dismissActions() }
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear { safeArea.refresh() }
        }
        .ignoresSafeArea()
        // Never force a SwiftUI appearance: Aspect UI sets the window style,
        // so system chrome (keyboard, share sheet, alerts) switches with it.
        .preferredColorScheme(nil)
        .environment(\.oldMusicTheme, theme)
        .environmentObject(library)
        .environmentObject(navigator)
        .sheet(item: $navigator.shareContent) { content in
            MusicShareSheet(items: content.items)
        }
        .onAppear {
            settings.apply()
            updateStatusBar()
        }
        .onChange(of: navigator.screen) { _ in updateStatusBar() }
        .onChange(of: colorScheme) { _ in updateStatusBar() }
        .onReceive(NotificationCenter.default.publisher(for: .oldMusicDeviceShaken)) { _ in
            shakeToShuffle()
        }
    }

    private var theme: OldMusicTheme {
        OldMusicTheme.theme(isDark: colorScheme == .dark)
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

    /// iOS 6: shaking the device shuffles the whole library.
    private func shakeToShuffle() {
        guard settings.shakeToShuffle, !library.songs.isEmpty, navigator.actionSong == nil else { return }
        OldMusicHaptics.press()
        MusicPlayer.shared.play(library.songs, shuffle: true)
        navigator.showNowPlaying()
    }

    // MARK: Song action sheet

    private func actionButtons(for song: MPMediaItem) -> [OldOSSheetButton] {
        var buttons: [OldOSSheetButton] = [
            OldOSSheetButton(title: "Play Next") {
                navigator.dismissActions()
                MusicPlayer.shared.playNext([song])
            },
            OldOSSheetButton(title: "Add to Up Next") {
                navigator.dismissActions()
                MusicPlayer.shared.addToUpNext([song])
            }
        ]

        if song.albumPersistentID != 0 {
            buttons.append(OldOSSheetButton(title: "Go to Album") {
                navigator.dismissActions()
                goToAlbum(of: song)
            })
        }
        if song.artistPersistentID != 0 {
            buttons.append(OldOSSheetButton(title: "Go to Artist") {
                navigator.dismissActions()
                goToArtist(of: song)
            })
        }
        buttons.append(OldOSSheetButton(title: "Share Song") {
            navigator.dismissActions()
            share(song)
        })
        return buttons
    }

    private func goToAlbum(of song: MPMediaItem) {
        let albums = library.albums(ofArtistOf: song)
        let query = MPMediaQuery.albums()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: NSNumber(value: song.albumPersistentID),
            forProperty: MPMediaItemPropertyAlbumPersistentID
        ))
        guard let album = query.collections?.first else { return }
        navigator.showLibrary()
        navigator.open(tab: .artists, stack: [
            .artist(name: song.artist ?? "", albums: albums.isEmpty ? [album] : albums),
            .album(album)
        ])
    }

    private func goToArtist(of song: MPMediaItem) {
        let albums = library.albums(ofArtistOf: song)
        guard !albums.isEmpty else { return }
        navigator.showLibrary()
        navigator.open(tab: .artists, stack: [
            .artist(name: song.artist ?? "", albums: albums)
        ])
    }

    private func share(_ song: MPMediaItem) {
        var text = "♫ \(song.title ?? "Unknown Song")"
        if let artist = song.artist, !artist.isEmpty {
            text += " – \(artist)"
        }
        if let album = song.albumTitle, !album.isEmpty {
            text += " (\(album))"
        }
        var items: [Any] = [text]
        if let artwork = song.artwork?.image(at: CGSize(width: 600, height: 600)) {
            items.append(artwork)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigator.shareContent = MusicShareContent(items: items)
        }
    }
}
