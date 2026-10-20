import SwiftUI
import MediaPlayer

/// Playlists tab root (OldOS `SkeuomorphicList_Playlists`).
struct MusicPlaylistsView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator

    var body: some View {
        MusicSearchableList {
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
                    MusicPlayer.shared.play(songs, startingAt: song)
                    navigator.showNowPlaying()
                } label: {
                    MusicSongRow(song: song, isPlaying: player.isNowPlaying(song))
                }
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
                .font(OldMusicFont.bold(18))
                .foregroundColor(theme.editButtonText)
                .shadow(color: theme.editButtonTextShadow, radius: 0, x: 0, y: theme.editButtonTextShadowY)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.editButtonStroke, lineWidth: 1)
        )
    }
}
