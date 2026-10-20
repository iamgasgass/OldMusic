import SwiftUI
import MediaPlayer

/// Loads the device music library (in the background) and keeps it up to
/// date when it changes. Sections come from MPMediaQuery's own
/// itemSections / collectionSections, i.e. the ones the Music app uses.
final class MusicLibrary: ObservableObject {
    @Published private(set) var authorized: Bool = false
    @Published private(set) var isLoaded: Bool = false

    @Published private(set) var songs: [MPMediaItem] = []
    @Published private(set) var songSections: [MusicSection<MPMediaItem>] = []
    @Published private(set) var artists: [MPMediaItemCollection] = []
    @Published private(set) var artistSections: [MusicSection<MPMediaItemCollection>] = []
    @Published private(set) var albums: [MPMediaItemCollection] = []
    @Published private(set) var playlists: [MPMediaItemCollection] = []
    @Published private(set) var genres: [MPMediaItemCollection] = []
    @Published private(set) var composers: [MPMediaItemCollection] = []
    @Published private(set) var audiobooks: [MPMediaItemCollection] = []
    @Published private(set) var podcasts: [MPMediaItemCollection] = []
    @Published private(set) var iTunesU: [MPMediaItemCollection] = []
    @Published private(set) var videos: [MPMediaItem] = []

    private var libraryObserver: NSObjectProtocol?
    private var pendingReload: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.iamgasgass.oldmusic.library", qos: .userInitiated)

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            self?.requestAccess()
        }
    }

    deinit {
        if let libraryObserver {
            NotificationCenter.default.removeObserver(libraryObserver)
        }
    }

    // MARK: Access

    private func requestAccess() {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorized = status == .authorized
                guard self.authorized else {
                    self.isLoaded = true
                    return
                }
                self.observeLibrary()
                self.reload()
            }
        }
    }

    private func observeLibrary() {
        guard libraryObserver == nil else { return }
        MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
        libraryObserver = NotificationCenter.default.addObserver(
            forName: .MPMediaLibraryDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.scheduleReload()
        }
    }

    private func scheduleReload() {
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
    }

    // MARK: Loading

    func reload() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
        queue.async { [weak self] in
            let albums = MPMediaQuery.albums().collections ?? []
            let playlists = MPMediaQuery.playlists().collections ?? []

            let artistQuery = MPMediaQuery.artists()
            let artists = artistQuery.collections ?? []
            let artistSections = MusicSection.build(artists, querySections: artistQuery.collectionSections) {
                $0.representativeItem?.artist
            }

            let songQuery = MPMediaQuery.songs()
            let songs = songQuery.items ?? []
            let songSections = MusicSection.build(songs, querySections: songQuery.itemSections) {
                $0.title
            }

            let genres = MPMediaQuery.genres().collections ?? []
            let composers = MPMediaQuery.composers().collections ?? []

            let audiobookQuery = MPMediaQuery.audiobooks()
            audiobookQuery.groupingType = .album
            let audiobooks = audiobookQuery.collections ?? []

            let podcasts = MPMediaQuery.podcasts().collections ?? []

            let iTunesUQuery = MPMediaQuery(filterPredicates: [
                MPMediaPropertyPredicate(
                    value: NSNumber(value: MPMediaType.audioITunesU.rawValue),
                    forProperty: MPMediaItemPropertyMediaType
                )
            ])
            iTunesUQuery.groupingType = .album
            let iTunesU = iTunesUQuery.collections ?? []

            let videoQuery = MPMediaQuery(filterPredicates: [
                MPMediaPropertyPredicate(
                    value: NSNumber(value: MPMediaType.anyVideo.rawValue),
                    forProperty: MPMediaItemPropertyMediaType
                )
            ])
            let videos = videoQuery.items ?? []

            DispatchQueue.main.async {
                guard let self else { return }
                self.albums = albums
                self.playlists = playlists
                self.artists = artists
                self.artistSections = artistSections
                self.songs = songs
                self.songSections = songSections
                self.genres = genres
                self.composers = composers
                self.audiobooks = audiobooks
                self.podcasts = podcasts
                self.iTunesU = iTunesU
                self.videos = videos
                self.isLoaded = true
            }
        }
    }

    // MARK: Queries

    func albums(of artist: MPMediaItemCollection) -> [MPMediaItemCollection] {
        guard let id = artist.representativeItem?.artistPersistentID else { return [] }
        return albums(matching: id, property: MPMediaItemPropertyArtistPersistentID)
    }

    func albums(ofArtistOf item: MPMediaItem?) -> [MPMediaItemCollection] {
        guard let item else { return [] }
        return albums(matching: item.artistPersistentID, property: MPMediaItemPropertyArtistPersistentID)
    }

    func albums(ofGenre genre: MPMediaItemCollection) -> [MPMediaItemCollection] {
        guard let id = genre.representativeItem?.genrePersistentID else { return [] }
        return albums(matching: id, property: MPMediaItemPropertyGenrePersistentID)
    }

    private func albums(matching id: MPMediaEntityPersistentID, property: String) -> [MPMediaItemCollection] {
        let query = MPMediaQuery.albums()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: id), forProperty: property))
        return query.collections ?? []
    }

    /// The album of an item, in disc / track order.
    static func albumTracks(for item: MPMediaItem?) -> [MPMediaItem] {
        guard let item else { return [] }
        let predicate = MPMediaPropertyPredicate(
            value: NSNumber(value: item.albumPersistentID),
            forProperty: MPMediaItemPropertyAlbumPersistentID
        )
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(predicate)
        var tracks = albumQuery.collections?.first?.items ?? []
        if tracks.isEmpty {
            // Podcasts, audiobooks and iTunes U are not "albums" for MPMediaQuery.albums().
            tracks = MPMediaQuery(filterPredicates: [predicate]).items ?? []
        }
        if tracks.isEmpty {
            tracks = [item]
        }
        return sortedTracks(tracks)
    }

    /// Disc / track order, unique by persistentID.
    static func sortedTracks(_ items: [MPMediaItem]) -> [MPMediaItem] {
        var seen = Set<MPMediaEntityPersistentID>()
        let unique = items.filter { seen.insert($0.persistentID).inserted }
        return unique.sorted { lhs, rhs in
            let l = (lhs.discNumber == 0 ? 1 : lhs.discNumber, lhs.albumTrackNumber == 0 ? Int.max : lhs.albumTrackNumber)
            let r = (rhs.discNumber == 0 ? 1 : rhs.discNumber, rhs.albumTrackNumber == 0 ? Int.max : rhs.albumTrackNumber)
            return l < r
        }
    }
}
