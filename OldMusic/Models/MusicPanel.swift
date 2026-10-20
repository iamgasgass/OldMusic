import SwiftUI
import MediaPlayer

/// One row of an OldSafari-style drop-down panel (Up Next, Recently Played,
/// Sort, ...).
struct MusicPanelItem: Identifiable {
    let id = UUID()
    let title: String
    var subtitle: String = ""
    /// SF Symbol drawn on the left, like the clock in OldSafari's history panel.
    var icon: String = "music.note"
    /// Shows the iOS 6 blue check instead of the chevron.
    var checked: Bool = false
    var showsChevron: Bool = true
    let action: () -> Void
}

/// A request to show the panel. `edge` tells where the panel hangs from:
/// `.bottom` panels sit above a bar at the bottom and point down at the
/// button that opened them (OldSafari Back / Forward history); `.top` panels
/// hang under the navigation bar and point up (drop-down "tendina").
struct MusicPanelRequest: Identifiable {
    enum Edge {
        case top
        case bottom
    }

    let id = UUID()
    let title: String
    let items: [MusicPanelItem]
    /// Horizontal position, 0…1, of the control that opened the panel.
    let anchor: CGFloat
    let edge: Edge
    /// Distance between that screen edge and the panel's pointer.
    let inset: CGFloat
    var emptyText: String = "Nothing Here"
}

/// Songs tab ordering offered by the "Sort" drop-down.
enum MusicSongSort: String, CaseIterable, Identifiable {
    case title
    case artist
    case album
    case recentlyAdded
    case mostPlayed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .recentlyAdded: return "Recently Added"
        case .mostPlayed: return "Most Played"
        }
    }

    var icon: String {
        switch self {
        case .title: return "textformat"
        case .artist: return "person"
        case .album: return "square.stack"
        case .recentlyAdded: return "clock"
        case .mostPlayed: return "chart.bar"
        }
    }

    /// Only the title order keeps the lettered sections and the A–Z index.
    var usesSections: Bool { self == .title }

    func sorted(_ songs: [MPMediaItem]) -> [MPMediaItem] {
        switch self {
        case .title:
            return songs
        case .artist:
            return songs.sorted {
                let l = ($0.artist ?? "", $0.albumTitle ?? "", $0.albumTrackNumber)
                let r = ($1.artist ?? "", $1.albumTitle ?? "", $1.albumTrackNumber)
                if l.0.localizedCaseInsensitiveCompare(r.0) != .orderedSame {
                    return l.0.localizedCaseInsensitiveCompare(r.0) == .orderedAscending
                }
                if l.1.localizedCaseInsensitiveCompare(r.1) != .orderedSame {
                    return l.1.localizedCaseInsensitiveCompare(r.1) == .orderedAscending
                }
                return l.2 < r.2
            }
        case .album:
            return songs.sorted {
                let l = ($0.albumTitle ?? "", $0.discNumber, $0.albumTrackNumber)
                let r = ($1.albumTitle ?? "", $1.discNumber, $1.albumTrackNumber)
                if l.0.localizedCaseInsensitiveCompare(r.0) != .orderedSame {
                    return l.0.localizedCaseInsensitiveCompare(r.0) == .orderedAscending
                }
                return (l.1, l.2) < (r.1, r.2)
            }
        case .recentlyAdded:
            return songs.sorted { $0.dateAdded > $1.dateAdded }
        case .mostPlayed:
            return songs.sorted { $0.playCount > $1.playCount }
        }
    }
}
