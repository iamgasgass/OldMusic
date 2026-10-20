import SwiftUI
import MediaPlayer

/// Songs tab (OldOS `SkeuomorphicList_Songs`): Shuffle row, lettered sections,
/// A–Z index and the song count footer. Tapping a song queues the whole list.
struct MusicSongsView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared

    var body: some View {
        let sort = navigator.songSort
        MusicSearchableList(indexLetters: sort.usesSections ? library.songSections.map(\.letter) : nil) {
            MusicShuffleRow {
                guard !library.songs.isEmpty else { return }
                MusicPlayer.shared.play(library.songs, shuffle: true)
                navigator.showNowPlaying()
            }
            .musicRow()

            if sort.usesSections {
                ForEach(library.songSections, id: \.letter) { section in
                    Section {
                        ForEach(section.items, id: \.persistentID) { song in
                            songButton(song, in: library.songs)
                        }
                    } header: {
                        MusicSectionHeader(text: section.letter)
                            .id(section.letter)
                    }
                }
            } else {
                // Sorted by artist / album / date added / play count: a flat
                // list, queued in the same order it is shown.
                let sorted = sort.sorted(library.songs)
                Section {
                    ForEach(sorted, id: \.persistentID) { song in
                        songButton(song, in: sorted)
                    }
                } header: {
                    MusicSectionHeader(text: sort.title)
                }
            }

            MusicListFooter(text: "\(library.songs.count) Songs")
                .musicRow()
        }
    }

    private func songButton(_ song: MPMediaItem, in list: [MPMediaItem]) -> some View {
        Button {
            navigator.tap {
                MusicPlayer.shared.play(list, startingAt: song)
                navigator.showNowPlaying()
            }
        } label: {
            MusicSongRow(song: song, isPlaying: player.isNowPlaying(song))
        }
        .musicSongActions(song, in: list)
        .musicRow()
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
                        navigator.tap {
                            MusicPlayer.shared.play(items, startingAt: song)
                            navigator.showNowPlaying()
                        }
                    } label: {
                        MusicSongRow(song: song, isPlaying: player.isNowPlaying(song))
                    }
                    .musicSongActions(song, in: items)
                    .musicRow()
                }
            }
        }
    }
}
