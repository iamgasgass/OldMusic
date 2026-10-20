import Foundation
import MediaPlayer

/// The five tabs of the iOS 6 iPod app.
enum MusicTab: String, CaseIterable, Identifiable {
    case playlists = "Playlists"
    case artists = "Artists"
    case songs = "Songs"
    case videos = "Videos"
    case more = "More"

    var id: String { rawValue }
    var title: String { rawValue }
    var iconName: String { "Tab\(rawValue)" }

    /// Glyph sizes used by OldOS for each tab icon.
    var iconWidth: CGFloat {
        switch self {
        case .songs: return 20
        case .artists: return 37.5
        default: return 30
        }
    }
}

/// What a collection list in the More tab contains, which decides how its
/// rows look and what tapping them opens.
enum MusicCollectionKind {
    case albums
    case genres
    case composers
    case podcasts
    case grouped

    var usesArtwork: Bool {
        switch self {
        case .genres, .composers: return false
        default: return true
        }
    }
}

/// A screen pushed on top of a tab's root list.
enum MusicRoute {
    case playlist(MPMediaItemCollection)
    case artist(name: String, albums: [MPMediaItemCollection])
    case album(MPMediaItemCollection)
    case collections(title: String, collections: [MPMediaItemCollection], kind: MusicCollectionKind)
    case items(title: String, items: [MPMediaItem])

    var title: String {
        switch self {
        case .playlist(let playlist):
            return playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "---"
        case .artist(let name, _):
            return name.isEmpty ? "Unknown Artist" : name
        case .album(let album):
            return album.representativeItem?.albumTitle ?? "---"
        case .collections(let title, _, _):
            return title
        case .items(let title, _):
            return title
        }
    }
}

// MARK: - Display names

extension MPMediaItemCollection {
    func oldMusicName(for kind: MusicCollectionKind) -> String {
        let item = representativeItem
        switch kind {
        case .albums, .grouped:
            return item?.albumTitle ?? item?.title ?? "---"
        case .genres:
            return item?.genre ?? "---"
        case .composers:
            return item?.composer ?? "---"
        case .podcasts:
            return item?.podcastTitle ?? item?.albumTitle ?? "---"
        }
    }

    func oldMusicSubtitle(for kind: MusicCollectionKind) -> String {
        let item = representativeItem
        switch kind {
        case .albums, .grouped:
            return item?.albumArtist ?? item?.artist ?? ""
        case .podcasts:
            return item?.artist ?? ""
        case .genres, .composers:
            return "\(count) \(count == 1 ? "Song" : "Songs")"
        }
    }

    var oldMusicPlaylistName: String {
        value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "---"
    }
}
