import SwiftUI
import MediaPlayer

/// More tab root (OldOS `ipod_more`): Albums, Audiobooks, Composers, Genres,
/// iTunes U and Podcasts — each now opens a real library list.
struct MusicMoreView: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator

    private struct Entry: Hashable {
        let title: String
        let icon: String
    }

    private let entries: [Entry] = [
        Entry(title: "Albums", icon: "BarAlbums"),
        Entry(title: "Audiobooks", icon: "BarAudioBooks"),
        Entry(title: "Composers", icon: "BarComposers"),
        Entry(title: "Genres", icon: "BarGenres"),
        Entry(title: "iTunes U", icon: "BarITunesU"),
        Entry(title: "Podcasts", icon: "BarPodcasts")
    ]

    var body: some View {
        List {
            ForEach(entries, id: \.title) { entry in
                Button {
                    open(entry.title)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            Image(entry.icon)
                                .frame(width: 25, height: 44 - 0.95)
                                .opacity(theme.isDark ? 0.9 : 1)
                            Text(entry.title)
                                .font(OldMusicFont.bold(18))
                                .foregroundColor(theme.rowText)
                                .lineLimit(1)
                                .padding(.leading, 6)
                                .padding(.trailing, 40)
                            Spacer()
                            Image("UITableNext").padding(.trailing, 12)
                        }
                        .padding(.leading, 16)
                        MusicSeparator()
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .musicRow()
            }
        }
        .musicListStyle()
    }

    private func open(_ title: String) {
        let route: MusicRoute
        switch title {
        case "Albums":
            route = .collections(title: title, collections: library.albums, kind: .albums)
        case "Audiobooks":
            route = .collections(title: title, collections: library.audiobooks, kind: .grouped)
        case "Composers":
            route = .collections(title: title, collections: library.composers, kind: .composers)
        case "Genres":
            route = .collections(title: title, collections: library.genres, kind: .genres)
        case "iTunes U":
            route = .collections(title: title, collections: library.iTunesU, kind: .grouped)
        case "Podcasts":
            route = .collections(title: title, collections: library.podcasts, kind: .podcasts)
        default:
            return
        }
        navigator.push(route)
    }
}

/// A list of albums, genres, composers, podcasts... from the More tab.
struct MusicCollectionsView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator
    let title: String
    let collections: [MPMediaItemCollection]
    let kind: MusicCollectionKind

    var body: some View {
        if collections.isEmpty {
            MusicEmptyView(title: "No \(title)")
        } else {
            MusicSearchableList {
                ForEach(Array(collections.enumerated()), id: \.offset) { _, collection in
                    Button {
                        open(collection)
                    } label: {
                        if kind.usesArtwork {
                            MusicArtworkRow(
                                image: collection.oldMusicArtwork(120),
                                title: collection.oldMusicName(for: kind),
                                subtitle: collection.oldMusicSubtitle(for: kind)
                            )
                        } else {
                            MusicTextRow(title: collection.oldMusicName(for: kind))
                        }
                    }
                    .musicRow(minHeight: kind.usesArtwork ? 60 : 44)
                }

                MusicListFooter(text: "\(collections.count) \(title)")
                    .musicRow()
            }
        }
    }

    private func open(_ collection: MPMediaItemCollection) {
        let name = collection.oldMusicName(for: kind)
        switch kind {
        case .albums:
            navigator.push(.album(collection))
        case .genres:
            navigator.push(.collections(title: name, collections: library.albums(ofGenre: collection), kind: .albums))
        case .podcasts, .composers:
            navigator.push(.items(title: name, items: collection.items))
        case .grouped:
            navigator.push(.items(title: name, items: MusicLibrary.sortedTracks(collection.items)))
        }
    }
}
