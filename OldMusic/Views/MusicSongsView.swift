import SwiftUI
import MediaPlayer

/// Songs tab (OldOS `SkeuomorphicList_Songs`): Shuffle row, lettered sections,
/// A–Z index and the song count footer. Tapping a song queues the whole list.
struct MusicSongsView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared

    var body: some View {
        MusicSearchableList(indexLetters: library.songSections.map(\.letter)) {
            MusicShuffleRow {
                guard !library.songs.isEmpty else { return }
                MusicPlayer.shared.play(library.songs, shuffle: true)
                navigator.showNowPlaying()
            }
            .musicRow()

            ForEach(library.songSections, id: \.letter) { section in
                Section {
                    ForEach(section.items, id: \.persistentID) { song in
                        Button {
                            MusicPlayer.shared.play(library.songs, startingAt: song)
                            navigator.showNowPlaying()
                        } label: {
                            MusicSongRow(song: song, isPlaying: player.isNowPlaying(song))
                        }
                        .musicRow()
                    }
                } header: {
                    MusicSectionHeader(text: section.letter)
                        .id(section.letter)
                }
            }

            MusicListFooter(text: "\(library.songs.count) Songs")
                .musicRow()
        }
    }
}

/// A plain list of items with a Shuffle row (composer, podcast episodes,
/// audiobook chapters, iTunes U lessons).
struct MusicItemsView: View {
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared
    let title: String
    let items: [MPMediaItem]

    var body: some View {
        if items.isEmpty {
            MusicEmptyView(title: "No \(title)")
        } else {
            MusicSearchableList {
                MusicShuffleRow {
                    MusicPlayer.shared.play(items, shuffle: true)
                    navigator.showNowPlaying()
                }
                .musicRow()

                ForEach(Array(items.enumerated()), id: \.offset) { _, song in
                    Button {
                        MusicPlayer.shared.play(items, startingAt: song)
                        navigator.showNowPlaying()
                    } label: {
                        MusicSongRow(song: song, isPlaying: player.isNowPlaying(song))
                    }
                    .musicRow()
                }
            }
        }
    }
}
