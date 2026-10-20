import SwiftUI
import MediaPlayer

/// Navigation and sharing actions shared by the action sheets, the Now
/// Playing options drop-down and the mini player.
enum MusicActions {
    static func goToAlbum(of song: MPMediaItem, library: MusicLibrary, navigator: MusicNavigator) {
        let albums = library.albums(ofArtistOf: song)
        let query = MPMediaQuery.albums()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: NSNumber(value: song.albumPersistentID),
            forProperty: MPMediaItemPropertyAlbumPersistentID
        ))
        guard let album = query.collections?.first else { return }
        navigator.showLibrary()
        navigator.open(tab: .artists, stack: [
            .artist(name: song.artist ?? "", albums: albums.isEmpty ? [album] : albums),
            .album(album)
        ])
    }

    static func goToArtist(of song: MPMediaItem, library: MusicLibrary, navigator: MusicNavigator) {
        let albums = library.albums(ofArtistOf: song)
        guard !albums.isEmpty else { return }
        navigator.showLibrary()
        navigator.open(tab: .artists, stack: [
            .artist(name: song.artist ?? "", albums: albums)
        ])
    }

    static func share(_ song: MPMediaItem, navigator: MusicNavigator) {
        var text = "♫ \(song.title ?? "Unknown Song")"
        if let artist = song.artist, !artist.isEmpty {
            text += " – \(artist)"
        }
        if let album = song.albumTitle, !album.isEmpty {
            text += " (\(album))"
        }
        var items: [Any] = [text]
        if let artwork = song.artwork?.image(at: CGSize(width: 600, height: 600)) {
            items.append(artwork)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigator.shareContent = MusicShareContent(items: items)
        }
    }
}
