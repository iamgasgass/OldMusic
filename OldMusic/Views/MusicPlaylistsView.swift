import SwiftUI
import MediaPlayer

/// Playlists tab root (OldOS `SkeuomorphicList_Playlists`).
struct MusicPlaylistsView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var userData = MusicUserData.shared

    var body: some View {
        MusicSearchableList {
            // iOS 6 smart playlists, generated from play counts and dates.
            smartRow("Recently Added", items: library.recentlyAdded)
            smartRow("Recently Played", items: library.recentlyPlayed)
            smartRow("Top 25 Most Played", items: library.topPlayed)
            // Saved by OldMusic: stars from Now Playing and "Add to Favorites".
            smartRow("My Top Rated", items: userData.topRatedSongs(in: library.songs))
            smartRow("Favorites", items: userData.favoriteSongs(in: library.songs))

            ForEach(library.playlists, id: \.persistentID) { playlist in
                Button {
                    guard playlist.count != 0 else { return }
                    navigator.push(.playlist(playlist))
                } label: {
                    MusicTextRow(title: playlist.oldMusicPlaylistName)
                }
                .musicRow()
            }
        }
    }

    private func smartRow(_ title: String, items: [MPMediaItem]) -> some View {
        Button {
            navigator.push(.items(title: title, items: items))
        } label: {
            MusicSmartPlaylistRow(title: title)
        }
        .musicRow()
    }
}

/// Smart playlist row: the iOS 6 gear in front of the name.
struct MusicSmartPlaylistRow: View {
    @Environment(\.oldMusicTheme) private var theme
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.isDark ? .oldOS(150, 150, 154) : .oldOS(120, 128, 140))
                    .padding(.leading, 11)
                Text(title)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(theme.listRowText)
                    .lineLimit(1)
                Spacer()
                MusicChevron().padding(.trailing, 12)
            }
            Spacer(minLength: 0)
            MusicSeparator()
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

/// A playlist's songs (OldOS `SkeuomorphicList_Playlists_Destination`), with
/// the iOS 6 Edit / Clear / Delete strip and the Shuffle row.
struct MusicPlaylistDetailView: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared
    let playlist: MPMediaItemCollection

    var body: some View {
        let songs = playlist.items
        MusicSearchableList {
            editStrip
                .musicRow()

            MusicShuffleRow {
                MusicPlayer.shared.play(songs, shuffle: true)
                navigator.showNowPlaying()
            }
            .musicRow()

            ForEach(Array(songs.enumerated()), id: \.offset) { _, song in
                Button {
                    navigator.tap {
                        MusicPlayer.shared.play(songs, startingAt: song)
                        navigator.showNowPlaying()
                    }
                } label: {
                    MusicSongRow(song: song, isPlaying: player.isNowPlaying(song))
                }
                .musicSongActions(song, in: songs)
                .musicRow()
            }
        }
    }

    /// Third-party apps cannot edit library playlists, so — exactly like the
    /// original — these buttons are drawn but inert.
    private var editStrip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                editButton("Edit").padding(.leading, 8)
                editButton("Clear")
                editButton("Delete").padding(.trailing, 8)
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
            MusicSeparator()
        }
        .frame(height: 44)
    }

    private func editButton(_ title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(oldOS: theme.editButtonGradient))
            Text(title)
                .font(OldOSFont.bold(18))
                .foregroundColor(theme.editButtonText)
                .shadow(color: theme.editButtonTextShadow, radius: 0, x: 0, y: theme.editButtonTextShadowY)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.editButtonStroke, lineWidth: 1)
        )
    }
}
