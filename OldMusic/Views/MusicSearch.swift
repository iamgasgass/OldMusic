import SwiftUI
import MediaPlayer

enum MusicSearchState {
    case idle
    /// Field focused but empty: the list is dimmed (tap to cancel).
    case activeEmpty
    /// Typing: results replace the list.
    case active
}

// MARK: - Search bar

/// OldOS `ipod_search`: the glossy search bar heading every list, with the
/// recessed capsule field and the iOS 6 Cancel button.
struct MusicSearchBar: View {
    @Environment(\.oldMusicTheme) private var theme
    @Binding var text: String
    @Binding var state: MusicSearchState
    /// Leaves room for the A–Z index bar, like the original.
    var reserveIndexSpace: Bool = false

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(oldOS: theme.searchGradient))
                .oldOSBorder(width: 0.75, edges: [.top], color: theme.searchHairline)

            HStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image("search_icon")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .padding(.leading, 10)

                    TextField("Search", text: $text)
                        .focused($focused)
                        .submitLabel(.search)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(theme.fieldTextActive)
                        .onSubmit { focused = false }

                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image("UITextFieldClearButton")
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }
                }
                .padding(.vertical, 5)
                .padding(.trailing, 8)
                .background(
                    OldOSInnerShadow(
                        shape: Capsule(),
                        fill: theme.fieldFill,
                        radius: 1.6,
                        offset: CGPoint(x: 0, y: 1),
                        intensity: 0.7
                    )
                )
                .oldOSStrokeCapsule(theme.searchFieldStroke, lineWidth: 0.33)
                .padding(.leading, 5.5)
                .padding(.trailing, state != .idle ? 5.5 : (reserveIndexSpace ? 35 : 5.5))

                if state != .idle {
                    Button(action: cancel) {
                        Text("Cancel")
                            .font(OldOSFont.bold(13.25))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                            .frame(width: 59, height: 32)
                            .background(
                                OldOSInnerShadow(
                                    shape: RoundedRectangle(cornerRadius: 5.5),
                                    fill: oldOSButtonGradient(theme.neutralButton),
                                    radius: 0.8,
                                    offset: CGPoint(x: 0, y: 0.6),
                                    intensity: 0.7
                                )
                            )
                            .shadow(color: Color.white.opacity(theme.isDark ? 0.12 : 0.28), radius: 0, x: 0, y: 0.8)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 5)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .frame(height: 44)
        .onChange(of: focused) { isFocused in
            withAnimation(.easeOut(duration: 0.2)) {
                if isFocused {
                    state = text.isEmpty ? .activeEmpty : .active
                } else if text.isEmpty {
                    state = .idle
                }
            }
        }
        .onChange(of: text) { newText in
            if !newText.isEmpty {
                state = .active
            } else if state != .idle {
                state = focused ? .activeEmpty : .idle
            }
        }
    }

    private func cancel() {
        text = ""
        focused = false
        oldOSHideKeyboard()
        withAnimation(.easeOut(duration: 0.2)) {
            state = .idle
        }
    }
}

// MARK: - Searchable list

/// A list headed by the search bar, with the dim / results overlay and the
/// optional A–Z index — the structure shared by every iPod list.
struct MusicSearchableList<Content: View>: View {
    var indexLetters: [String]? = nil
    @ViewBuilder var content: () -> Content

    @State private var query = ""
    @State private var state: MusicSearchState = .idle

    var body: some View {
        ZStack(alignment: .top) {
            List {
                MusicSearchBar(text: $query, state: $state, reserveIndexSpace: indexLetters != nil)
                    .id(MusicIndex.search)
                    .musicRow(minHeight: 44)
                content()
            }
            .musicListStyle()
            .musicIndexBar(available: indexLetters ?? [], hidden: indexLetters == nil || state != .idle)

            MusicSearchOverlay(state: $state, query: query)
        }
    }
}

struct MusicSearchOverlay: View {
    @Environment(\.oldMusicTheme) private var theme
    @Binding var state: MusicSearchState
    let query: String

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .activeEmpty:
            theme.scrim
                .contentShape(Rectangle())
                .onTapGesture {
                    oldOSHideKeyboard()
                    withAnimation(.easeOut(duration: 0.2)) { state = .idle }
                }
                .padding(.top, 44)
                .transition(.opacity)
        case .active:
            MusicSearchResults(query: query)
                .padding(.top, 44)
        }
    }
}

// MARK: - Results

/// iOS 6 search results: Artists, Albums and Songs sections.
struct MusicSearchResults: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator
    let query: String

    var body: some View {
        let artists = library.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(query) }
        let albums = library.albums.filter { ($0.representativeItem?.albumTitle ?? "").localizedCaseInsensitiveContains(query) }
        let songs = library.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(query) }

        List {
            if !artists.isEmpty {
                Section {
                    ForEach(artists, id: \.persistentID) { artist in
                        Button {
                            openArtist(artist)
                        } label: {
                            MusicArtworkRow(
                                image: artist.oldMusicArtwork(120),
                                title: artist.representativeItem?.artist ?? "---"
                            )
                        }
                        .musicRow(minHeight: 60)
                    }
                } header: {
                    MusicSectionHeader(text: "Artists (\(artists.count) \(resultWord(artists.count)))")
                }
            }

            if !albums.isEmpty {
                Section {
                    ForEach(albums, id: \.persistentID) { album in
                        Button {
                            openAlbum(album)
                        } label: {
                            MusicArtworkRow(
                                image: album.oldMusicArtwork(120),
                                title: album.representativeItem?.albumTitle ?? "---",
                                subtitle: album.representativeItem?.albumArtist ?? album.representativeItem?.artist
                            )
                        }
                        .musicRow(minHeight: 60)
                    }
                } header: {
                    MusicSectionHeader(text: "Albums (\(albums.count) \(resultWord(albums.count)))")
                }
            }

            if !songs.isEmpty {
                Section {
                    ForEach(songs, id: \.persistentID) { song in
                        Button {
                            navigator.tap {
                                MusicPlayer.shared.play(songs, startingAt: song)
                                navigator.showNowPlaying()
                            }
                        } label: {
                            MusicArtworkRow(
                                image: song.oldMusicArtwork(120),
                                title: song.title ?? "---",
                                subtitle: "\(song.albumTitle ?? "---") - \(song.artist ?? "---")"
                            )
                        }
                        .musicSongActions(song, in: songs)
                        .musicRow(minHeight: 60)
                    }
                } header: {
                    MusicSectionHeader(text: "Songs (\(songs.count) \(resultWord(songs.count)))")
                }
            }

            if artists.isEmpty && albums.isEmpty && songs.isEmpty {
                MusicListFooter(text: "No Results")
                    .musicRow(minHeight: 88)
            }
        }
        .musicListStyle()
    }

    private func resultWord(_ count: Int) -> String {
        count == 1 ? "Result" : "Results"
    }

    private func openArtist(_ artist: MPMediaItemCollection) {
        let albums = library.albums(of: artist)
        guard !albums.isEmpty else { return }
        navigator.open(tab: .artists, stack: [
            .artist(name: artist.representativeItem?.artist ?? "", albums: albums)
        ])
    }

    private func openAlbum(_ album: MPMediaItemCollection) {
        var albums = library.albums(ofArtistOf: album.representativeItem)
        if albums.isEmpty { albums = [album] }
        navigator.open(tab: .artists, stack: [
            .artist(name: album.representativeItem?.artist ?? "", albums: albums),
            .album(album)
        ])
    }
}
