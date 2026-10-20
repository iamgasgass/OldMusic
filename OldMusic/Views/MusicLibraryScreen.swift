import SwiftUI
import MediaPlayer

/// The library side of the app: blue (or graphite) navigation bar extended
/// behind the status bar / Dynamic Island, the current list, and the black
/// iOS 6 tab bar extended behind the home indicator.
struct MusicLibraryScreen: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var navigator: MusicNavigator
    @EnvironmentObject private var library: MusicLibrary
    @ObservedObject private var player = MusicPlayer.shared
    let topInset: CGFloat
    let bottomInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            MusicNavigationBar(topInset: topInset)
                .zIndex(2)

            ZStack {
                // OldOS paints the bounce area above the first row in the search-bar blue-grey.
                VStack(spacing: 0) {
                    theme.listTopBounce
                    theme.listBackground
                }

                screen(for: navigator.currentRoute)
                    .id("\(navigator.tab.rawValue)-\(navigator.depth)")
                    .transition(slide)

                if library.isLoaded && !library.authorized {
                    MusicEmptyView(
                        title: "No Access to Music",
                        message: "Allow OldMusic to use Media & Apple Music in Settings › Privacy & Security."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .zIndex(1)

            // Bottom sheet, collapsed: the mini player above the tab bar.
            MusicMiniPlayer(
                onOpen: { navigator.showNowPlaying() },
                onLongPress: {
                    navigator.presentPanel(MusicPanels.upNext(
                        navigator: navigator,
                        anchor: 0.5,
                        edge: .bottom,
                        inset: bottomInset + 57 + MusicMiniPlayer.height
                    ))
                }
            )
            .zIndex(3)

            MusicTabBar(bottomInset: bottomInset)
                .zIndex(2)
        }
        .animation(.easeOut(duration: 0.25), value: player.nowPlayingItem == nil)
    }

    private var slide: AnyTransition {
        let forward = navigator.movingForward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }

    @ViewBuilder
    private func screen(for route: MusicRoute?) -> some View {
        switch route {
        case .none:
            root(for: navigator.tab)
        case .some(.playlist(let playlist)):
            MusicPlaylistDetailView(playlist: playlist)
        case .some(.artist(_, let albums)):
            MusicArtistAlbumsView(albums: albums)
        case .some(.album(let album)):
            MusicAlbumView(album: album)
        case .some(.collections(let title, let collections, let kind)):
            MusicCollectionsView(title: title, collections: collections, kind: kind)
        case .some(.items(let title, let items)):
            MusicItemsView(title: title, items: items)
        case .some(.aspect):
            MusicAspectView()
        }
    }

    @ViewBuilder
    private func root(for tab: MusicTab) -> some View {
        switch tab {
        case .playlists: MusicPlaylistsView()
        case .artists: MusicArtistsView()
        case .songs: MusicSongsView()
        case .videos: MusicVideosView()
        case .more: MusicMoreView()
        }
    }
}

// MARK: - Navigation bar

/// OldOS `ipod_title_bar`.
struct MusicNavigationBar: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared
    let topInset: CGFloat

    private let barHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)

            ZStack {
                HStack {
                    Spacer()
                    Text(navigator.title)
                        .font(OldOSFont.bold(22))
                        .foregroundColor(theme.titleBarTitle)
                        .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
                        .lineLimit(1)
                        .frame(maxWidth: 180)
                        .id(navigator.title)
                        .transition(
                            AnyTransition.asymmetric(
                                insertion: .move(edge: navigator.movingForward ? .trailing : .leading),
                                removal: .move(edge: navigator.movingForward ? .leading : .trailing)
                            ).combined(with: .opacity)
                        )
                    Spacer()
                }

                if let back = navigator.backTitle {
                    HStack {
                        MusicBarBackButton(
                            title: back,
                            image: (navigator.tab == .artists && navigator.depth == 1) ? "Button2" : "Button_wp4"
                        ) {
                            navigator.pop()
                        }
                        .padding(.leading, 5.5)
                        Spacer()
                    }
                    .offset(y: -0.5)
                    .transition(.opacity)
                }

                // Right side: the "Sort" drop-down on the Songs list. Now Playing
                // is reached from the mini player (bottom sheet).
                if navigator.tab == .songs && navigator.depth == 0 {
                    HStack {
                        Spacer()
                        OldOSRectangleButton(
                            title: "Sort",
                            type: theme.secondaryButton
                        ) {
                            navigator.presentPanel(MusicPanels.songSort(navigator: navigator, inset: topInset + barHeight))
                        }
                        .padding(.trailing, 5)
                    }
                    .transition(.opacity)
                }
            }
            .frame(height: barHeight)
        }
        // Same as the OldSafari chrome: one gradient from the top of the
        // screen (behind the status bar / Dynamic Island) to the hairline.
        .background(
            VStack(spacing: 0) {
                Color.clear.frame(height: topInset)
                Color.clear
                    .frame(height: barHeight)
                    .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)
            }
            .background(LinearGradient(oldOS: theme.barGradient))
        )
        .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
    }
}

/// The pointed iOS 6 back button (artwork from OldOS, text drawn on top).
struct MusicBarBackButton: View {
    @Environment(\.oldMusicTheme) private var theme
    let title: String
    var image: String = "Button_wp4"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84 * (33 / 34.33783783783784), height: 33)
                    .saturation(theme.barButtonSaturation)
                    .brightness(theme.barButtonBrightness)
                Text(title)
                    .font(OldOSFont.bold(13))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6)
                    .lineLimit(1)
                    .frame(maxWidth: 70)
                    .padding(.leading, 6)
                    .offset(y: -1.1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab bar

/// OldOS `iPodTabView` bottom bar: 57pt of black glass, extended down to the
/// bottom of the screen on devices with a home indicator.
struct MusicTabBar: View {
    @EnvironmentObject private var navigator: MusicNavigator
    let bottomInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(MusicTab.allCases) { tab in
                        MusicTabButton(
                            tab: tab,
                            selected: navigator.tab == tab,
                            width: geometry.size.width / 5
                        ) {
                            navigator.select(tab)
                        }
                        if tab != MusicTab.allCases.last {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(height: 55)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 57)

            Color.clear.frame(height: bottomInset)
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(oldOS: OldMusicBlackChrome.barGradient).frame(height: 57)
                OldMusicBlackChrome.bottomFill
            }
        )
    }
}

/// OldOS `TabButton`: grey glyph, or the blue glossy glyph on a lit tile when selected.
struct MusicTabButton: View {
    let tab: MusicTab
    let selected: Bool
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: max(width - 5, 0), height: 51)
                        .blendMode(.screen)
                    VStack(spacing: 2) {
                        ZStack {
                            glyph(width: tab.iconWidth + 0.5, height: 30.5)
                                .overlay(LinearGradient(oldOS: [.oldOS(205, 233, 249), .oldOS(75, 220, 251)]))
                                .mask(glyph(width: tab.iconWidth + 0.5, height: 30.5))
                                .offset(y: -0.5)

                            glyph(width: tab.iconWidth, height: 30)
                                .overlay(selectedFill)
                                .mask(glyph(width: tab.iconWidth, height: 30))
                                .shadow(color: Color.black.opacity(0.6), radius: 2.5, x: 0, y: 2.5)
                        }
                        Text(tab.title)
                            .font(OldOSFont.bold(11))
                            .foregroundColor(.white)
                    }
                } else {
                    VStack(spacing: 2) {
                        glyph(width: tab.iconWidth, height: 30)
                            .overlay(LinearGradient(oldOS: [.oldOS(157, 157, 157), .oldOS(89, 89, 89)]))
                            .mask(glyph(width: tab.iconWidth, height: 30))
                            .shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        Text(tab.title)
                            .font(OldOSFont.bold(11))
                            .foregroundColor(.oldOS(168, 168, 168))
                    }
                }
            }
            .frame(width: width, height: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func glyph(width: CGFloat, height: CGFloat) -> some View {
        Image(tab.iconName)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
    }

    @ViewBuilder
    private var selectedFill: some View {
        if tab == .more {
            LinearGradient(oldOS: [
                OldOSStop(.oldOS(0, 145, 230), 0),
                OldOSStop(.oldOS(21, 197, 252), 1)
            ])
            .frame(width: 40, height: 10)
            .brightness(0.095)
        } else {
            LinearGradient(oldOS: [
                OldOSStop(.oldOS(197, 210, 229), 0),
                OldOSStop(.oldOS(99, 162, 216), 0.47),
                OldOSStop(.oldOS(0, 145, 230), 0.49),
                OldOSStop(.oldOS(21, 197, 252), 1)
            ])
            .rotationEffect(.degrees(-15))
            .frame(width: 40, height: tab == .artists ? 34 : 30)
            .brightness(0.095)
            .offset(y: tab == .artists ? 2 : 0)
        }
    }
}
