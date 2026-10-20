import SwiftUI
import MediaPlayer

/// Builders for the drop-down panels used across the app.
enum MusicPanels {
    private static let maxRows = 30

    /// "Up Next": songs after the current one (mini player long press,
    /// Now Playing Next long press). Tapping a row jumps to it.
    static func upNext(navigator: MusicNavigator, anchor: CGFloat, edge: MusicPanelRequest.Edge, inset: CGFloat) -> MusicPanelRequest {
        let player = MusicPlayer.shared
        let songs = Array(player.upNext.prefix(maxRows))
        let items = songs.map { song in
            MusicPanelItem(
                title: song.title ?? "Unknown Song",
                subtitle: subtitle(for: song),
                icon: "music.note"
            ) {
                navigator.dismissPanel()
                player.jump(to: song)
            }
        }
        return MusicPanelRequest(
            title: player.shuffleOn ? "Up Next · Shuffle" : "Up Next",
            items: items,
            anchor: anchor,
            edge: edge,
            inset: inset,
            emptyText: "No Songs Up Next"
        )
    }

    /// "Recently Played": OldMusic's own listening history (Now Playing
    /// Previous long press), most recent first, current song excluded.
    static func recentlyPlayed(navigator: MusicNavigator, library: MusicLibrary, anchor: CGFloat, edge: MusicPanelRequest.Edge, inset: CGFloat) -> MusicPanelRequest {
        let player = MusicPlayer.shared
        let current = player.nowPlayingItem?.persistentID
        let songs = MusicUserData.shared.historySongs(in: library.songs)
            .filter { $0.persistentID != current }
            .prefix(maxRows)
        var items = songs.map { song in
            MusicPanelItem(
                title: song.title ?? "Unknown Song",
                subtitle: subtitle(for: song),
                icon: "clock"
            ) {
                navigator.dismissPanel()
                player.jump(to: song)
            }
        }
        if !items.isEmpty {
            items.append(MusicPanelItem(title: "Clear History", icon: "trash", showsChevron: false) {
                navigator.dismissPanel()
                MusicUserData.shared.clearHistory()
            })
        }
        return MusicPanelRequest(
            title: "Recently Played",
            items: items,
            anchor: anchor,
            edge: edge,
            inset: inset,
            emptyText: "No Recently Played Songs"
        )
    }

    /// Songs tab "Sort" drop-down, hanging from the navigation bar.
    static func songSort(navigator: MusicNavigator, inset: CGFloat) -> MusicPanelRequest {
        let items = MusicSongSort.allCases.map { sort in
            MusicPanelItem(
                title: sort.title,
                icon: sort.icon,
                checked: navigator.songSort == sort,
                showsChevron: false
            ) {
                navigator.dismissPanel()
                withAnimation(.linear(duration: 0.2)) {
                    navigator.songSort = sort
                }
            }
        }
        return MusicPanelRequest(title: "Sort Songs By", items: items, anchor: 0.92, edge: .top, inset: inset)
    }

    private static func subtitle(for song: MPMediaItem) -> String {
        [song.artist, song.albumTitle].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
    }
}
