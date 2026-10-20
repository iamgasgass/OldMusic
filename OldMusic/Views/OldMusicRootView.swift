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
    @ObservedObject private var userData = MusicUserData.shared
    @State private var nowPlayingDrag: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let topInset = max(geometry.safeAreaInsets.top, safeArea.insets.top)
            let bottomInset = max(geometry.safeAreaInsets.bottom, safeArea.insets.bottom)

            ZStack {
                Color.black

                if navigator.screen != .coverFlow {
                    MusicLibraryScreen(topInset: topInset, bottomInset: bottomInset)
                        // Like a card under a sheet: the library dims slightly
                        // while Now Playing is up.
                        .overlay(
                            Color.black
                                .opacity(navigator.screen == .nowPlaying ? 0.45 * (1 - min(nowPlayingDrag / 500, 1)) : 0)
                                .allowsHitTesting(false)
                        )
                        .transition(.opacity)
                }

                // Bottom sheet, expanded: Now Playing slides up from the mini
                // player and follows the finger when dragged down.
                if navigator.screen == .nowPlaying {
                    MusicNowPlayingView(topInset: topInset, bottomInset: bottomInset, dragOffset: $nowPlayingDrag)
                        .offset(y: nowPlayingDrag)
                        .shadow(color: Color.black.opacity(nowPlayingDrag > 0 ? 0.6 : 0), radius: 12, x: 0, y: -2)
                        .transition(.move(edge: .bottom))
                        .zIndex(10)
                }

                if navigator.screen == .coverFlow {
                    MusicCoverFlowView()
                        .transition(.opacity)
                        .zIndex(20)
                }

                if let panel = navigator.panel, navigator.screen != .coverFlow {
                    OldOSPopoverPanel(theme: theme, request: panel) {
                        navigator.dismissPanel()
                    }
                    .transition(.opacity)
                    .zIndex(25)
                }

                if let album = navigator.actionAlbum, navigator.screen != .coverFlow {
                    OldOSActionSheet(
                        theme: theme,
                        buttons: albumButtons(for: album),
                        bottomInset: bottomInset,
                        onCancel: { navigator.dismissActions() }
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(30)
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
        buttons.append(OldOSSheetButton(title: userData.isFavorite(song) ? "Remove from Favorites" : "Add to Favorites") {
            navigator.dismissActions()
            OldMusicHaptics.tap()
            userData.toggleFavorite(song)
        })
        buttons.append(OldOSSheetButton(title: "Share Song") {
            navigator.dismissActions()
            share(song)
        })
        return buttons
    }

    private func goToAlbum(of song: MPMediaItem) {
        MusicActions.goToAlbum(of: song, library: library, navigator: navigator)
    }

    private func goToArtist(of song: MPMediaItem) {
        MusicActions.goToArtist(of: song, library: library, navigator: navigator)
    }

    private func share(_ song: MPMediaItem) {
        MusicActions.share(song, navigator: navigator)
    }

    // MARK: Album action sheet

    private func albumButtons(for album: MPMediaItemCollection) -> [OldOSSheetButton] {
        let tracks = MusicLibrary.sortedTracks(album.items)
        var buttons: [OldOSSheetButton] = [
            OldOSSheetButton(title: "Play") {
                navigator.dismissActions()
                MusicPlayer.shared.play(tracks)
                navigator.showNowPlaying()
            },
            OldOSSheetButton(title: "Shuffle") {
                navigator.dismissActions()
                MusicPlayer.shared.play(tracks, shuffle: true)
                navigator.showNowPlaying()
            },
            OldOSSheetButton(title: "Play Next") {
                navigator.dismissActions()
                MusicPlayer.shared.playNext(tracks)
            },
            OldOSSheetButton(title: "Add to Up Next") {
                navigator.dismissActions()
                MusicPlayer.shared.addToUpNext(tracks)
            }
        ]
        if let first = album.representativeItem, first.artistPersistentID != 0 {
            buttons.append(OldOSSheetButton(title: "Go to Artist") {
                navigator.dismissActions()
                goToArtist(of: first)
            })
        }
        return buttons
    }
}
