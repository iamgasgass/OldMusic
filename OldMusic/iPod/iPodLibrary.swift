//
//  iPodLibrary.swift
//  OldMusic
//
//  Playback + library layer for the iPod app ported from OldOS (Zane Kleinberg).
//
//  Why this file exists (bugs of the original OldOS iPod that are fixed here):
//   1. Every tap on a song went through SKCloudServiceController and only played if the
//      user had an *Apple Music subscription* (musicCatalogPlayback). Songs synced from a
//      computer / purchased songs never played without a subscription. Local library
//      playback does not need any subscription, so the gate is gone.
//   2. beginGeneratingPlaybackNotifications() was never called, so the
//      NowPlayingItemDidChange / PlaybackStateDidChange notifications were never posted:
//      play/pause button, track list highlight, title, artwork never refreshed.
//   3. Tapping a song queued *only that song* (next/previous did nothing). Now the whole
//      list (songs, album, playlist, search results...) is queued, starting at the
//      tapped song, exactly like iOS 6.
//   4. The player was driven / SwiftUI state mutated from background threads.
//   5. The library was loaded only once (no refresh on library changes) on the main
//      thread, Songs excluded every iCloud item while Artists/Albums didn't.
//   6. Section indexes were computed with a plain prefix(1) (lowercase, accented or
//      "The ..." names ended up in "#" or in the wrong letter). Sections now come from
//      MPMediaQuery's own itemSections/collectionSections, i.e. the very same ones the
//      system Music app uses.
//

import SwiftUI
import MediaPlayer

//MARK: - Player

final class iPodPlayer: ObservableObject {
    static let shared = iPodPlayer()

    let player = MPMusicPlayerController.systemMusicPlayer
    @Published var nowPlayingItem: MPMediaItem?
    @Published var playbackState: MPMusicPlaybackState = .stopped

    private var observers: [NSObjectProtocol] = []

    private init() {
        player.beginGeneratingPlaybackNotifications()
        nowPlayingItem = player.nowPlayingItem
        playbackState = player.playbackState
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player, queue: .main) { [weak self] _ in
            self?.refresh()
        })
        observers.append(center.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: player, queue: .main) { [weak self] _ in
            self?.refresh()
        })
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        })
    }

    deinit {
        player.endGeneratingPlaybackNotifications()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func refresh() {
        nowPlayingItem = player.nowPlayingItem
        playbackState = player.playbackState
    }

    var isPlaying: Bool {
        return playbackState == .playing
    }

    func isNowPlaying(_ item: MPMediaItem) -> Bool {
        guard let current = nowPlayingItem else { return false }
        return current.persistentID == item.persistentID
    }

    /// Queues `items` (in order) and starts playing at `start` (or the first item / a random item when shuffling).
    func play(_ items: [MPMediaItem], startingAt start: MPMediaItem? = nil, shuffle: Bool = false) {
        guard !items.isEmpty else { return }
        let collection = MPMediaItemCollection(items: items)
        let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
        if shuffle {
            player.shuffleMode = .songs
            descriptor.startItem = start ?? items.randomElement()
        } else {
            descriptor.startItem = start ?? items.first
        }
        player.setQueue(with: descriptor)
        player.prepareToPlay { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("OldMusic prepareToPlay error: \(error.localizedDescription)")
                }
                self?.player.play()
                self?.refresh()
            }
        }
        // Optimistic UI update (the notification will confirm it).
        nowPlayingItem = descriptor.startItem ?? nowPlayingItem
    }

    func togglePlayPause() {
        if player.playbackState == .playing {
            player.pause()
        } else {
            player.play()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.refresh()
        }
    }
}

/// Plays a list from anywhere in the UI (dismisses the search keyboard first).
func ipod_play(_ items: [MPMediaItem], start: MPMediaItem? = nil, shuffle: Bool = false) {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    iPodPlayer.shared.play(items, startingAt: start, shuffle: shuffle)
}

//MARK: - Navigation actions shared through the environment

struct iPodActions {
    var openArtist: (MPMediaItemCollection) -> Void = { _ in }
    var openAlbum: (MPMediaItemCollection) -> Void = { _ in }
    var showNowPlaying: () -> Void = { }
}

private struct iPodActionsKey: EnvironmentKey {
    static let defaultValue = iPodActions()
}

extension EnvironmentValues {
    var ipodActions: iPodActions {
        get { self[iPodActionsKey.self] }
        set { self[iPodActionsKey.self] = newValue }
    }
}

//MARK: - Sections

struct ipod_section<Element> {
    let letter: String
    let items: [Element]
}

let ipod_index_letters: [String] = alphabet.filter { $0 != "Search" }

func ipod_normalized_letter(_ raw: String?) -> String {
    guard let raw = raw else { return "#" }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let first = trimmed.first else { return "#" }
    let folded = String(first).folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX")).uppercased()
    if folded != "#" && ipod_index_letters.contains(folded) {
        return folded
    }
    return "#"
}

func ipod_build_sections<T>(_ elements: [T], sections: [MPMediaQuerySection]?, title: (T) -> String?) -> [ipod_section<T>] {
    var buckets: [String: [T]] = [:]
    var used_query_sections = false
    if let sections = sections, !sections.isEmpty {
        let total = sections.reduce(0) { $0 + $1.range.length }
        if total == elements.count {
            used_query_sections = true
            for section in sections {
                let lower = section.range.location
                let upper = section.range.location + section.range.length
                guard lower >= 0, lower <= upper, upper <= elements.count else { continue }
                let letter = ipod_normalized_letter(section.title)
                buckets[letter, default: []].append(contentsOf: elements[lower..<upper])
            }
        }
    }
    if !used_query_sections {
        for element in elements {
            buckets[ipod_normalized_letter(title(element)), default: []].append(element)
        }
    }
    return ipod_index_letters.compactMap { letter in
        guard let items = buckets[letter], !items.isEmpty else { return nil }
        return ipod_section(letter: letter, items: items)
    }
}

//MARK: - Music Observer

class MusicObserver: ObservableObject {

    @Published var allowMusicLibraryAccess: Bool = false
    @Published var songs: [MPMediaItem]
    @Published var playists: [MPMediaItemCollection]
    @Published var artists: [MPMediaItemCollection]
    @Published var ab: [MPMediaItemCollection]
    @Published var song_sections: [ipod_section<MPMediaItem>] = []
    @Published var artist_sections: [ipod_section<MPMediaItemCollection>] = []
    @Published var genres: [MPMediaItemCollection] = []
    @Published var composers: [MPMediaItemCollection] = []
    @Published var audiobooks: [MPMediaItemCollection] = []
    @Published var podcasts: [MPMediaItemCollection] = []
    @Published var itunes_u: [MPMediaItemCollection] = []
    @Published var videos: [MPMediaItem] = []

    private var library_observer: NSObjectProtocol?
    private var reload_work: DispatchWorkItem?
    private let load_queue = DispatchQueue(label: "com.iamgasgass.oldmusic.library", qos: .userInitiated)

    init() {
        self.songs = [MPMediaItem]()
        self.playists = [MPMediaItemCollection]()
        self.artists = [MPMediaItemCollection]()
        self.ab = [MPMediaItemCollection]()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { //We do this to ensure the transition works, and music library is loaded soon after
            self.initAllowMusicLibraryAccess()
        }
    }

    deinit {
        if let library_observer = library_observer {
            NotificationCenter.default.removeObserver(library_observer)
        }
    }

    private func initAllowMusicLibraryAccess() -> Void {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self.allowMusicLibraryAccess = false
                    return
                }
                self.allowMusicLibraryAccess = true
                self.startObservingLibrary()
                self.reload()
            }
        }
    }

    private func startObservingLibrary() {
        guard library_observer == nil else { return }
        MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
        library_observer = NotificationCenter.default.addObserver(forName: .MPMediaLibraryDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.scheduleReload()
        }
    }

    private func scheduleReload() {
        reload_work?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        reload_work = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    func reload() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
        load_queue.async { [weak self] in
            // Loading Albums
            let ab = MPMediaQuery.albums().collections ?? []

            // Loading Playlists
            let playlists = MPMediaQuery.playlists().collections ?? []

            // Loading Artists
            let artist_query = MPMediaQuery.artists()
            let artists = artist_query.collections ?? []
            let artist_sections = ipod_build_sections(artists, sections: artist_query.collectionSections, title: { $0.representativeItem?.artist })

            // Loading Songs
            let song_query = MPMediaQuery.songs()
            let songs = song_query.items ?? []
            let song_sections = ipod_build_sections(songs, sections: song_query.itemSections, title: { $0.title })

            // More
            let genres = MPMediaQuery.genres().collections ?? []
            let composers = MPMediaQuery.composers().collections ?? []
            let audiobook_query = MPMediaQuery.audiobooks()
            audiobook_query.groupingType = .album
            let audiobooks = audiobook_query.collections ?? []
            let podcasts = MPMediaQuery.podcasts().collections ?? []
            let itunes_u_query = MPMediaQuery()
            itunes_u_query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.anyITunesU.rawValue, forProperty: MPMediaItemPropertyMediaType))
            itunes_u_query.groupingType = .album
            let itunes_u = itunes_u_query.collections ?? []
            let video_query = MPMediaQuery()
            video_query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.anyVideo.rawValue, forProperty: MPMediaItemPropertyMediaType))
            let videos = video_query.items ?? []

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.ab = ab
                self.playists = playlists
                self.artists = artists
                self.artist_sections = artist_sections
                self.songs = songs
                self.song_sections = song_sections
                self.genres = genres
                self.composers = composers
                self.audiobooks = audiobooks
                self.podcasts = podcasts
                self.itunes_u = itunes_u
                self.videos = videos
            }
        }
    }

    /// All albums of an artist (system order).
    func albums(for artist: MPMediaItemCollection) -> [MPMediaItemCollection] {
        let q = MPMediaQuery.albums()
        if let id = artist.representativeItem?.artistPersistentID {
            q.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: id), forProperty: MPMediaItemPropertyArtistPersistentID))
        }
        return q.collections ?? []
    }

    /// All albums of an album artist / artist referenced by an item.
    func albums(forArtistOf item: MPMediaItem?) -> [MPMediaItemCollection] {
        guard let item = item else { return [] }
        let q = MPMediaQuery.albums()
        q.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: item.artistPersistentID), forProperty: MPMediaItemPropertyArtistPersistentID))
        return q.collections ?? []
    }

    /// All albums of a genre.
    func albums(forGenre genre: MPMediaItemCollection) -> [MPMediaItemCollection] {
        let q = MPMediaQuery.albums()
        if let id = genre.representativeItem?.genrePersistentID {
            q.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: id), forProperty: MPMediaItemPropertyGenrePersistentID))
        }
        return q.collections ?? []
    }
}

/// Album tracks in disc/track order.
func ipod_sorted_album_tracks(_ items: [MPMediaItem]) -> [MPMediaItem] {
    return items.sorted { lhs, rhs in
        let l = (lhs.discNumber == 0 ? 1 : lhs.discNumber, lhs.albumTrackNumber == 0 ? Int.max : lhs.albumTrackNumber)
        let r = (rhs.discNumber == 0 ? 1 : rhs.discNumber, rhs.albumTrackNumber == 0 ? Int.max : rhs.albumTrackNumber)
        return l < r
    }
}

/// Tracks of the album an item belongs to (disc/track order).
func ipod_album_tracks(for item: MPMediaItem?) -> [MPMediaItem] {
    guard let item = item else { return [] }
    let q = MPMediaQuery.albums()
    q.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: item.albumPersistentID), forProperty: MPMediaItemPropertyAlbumPersistentID))
    var tracks = q.collections?.first?.items ?? []
    if tracks.isEmpty {
        // Podcasts, audiobooks, iTunes U... are not "albums" for MPMediaQuery.albums()
        let generic = MPMediaQuery()
        generic.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: item.albumPersistentID), forProperty: MPMediaItemPropertyAlbumPersistentID))
        tracks = generic.items ?? []
    }
    if tracks.isEmpty {
        tracks = [item]
    }
    return ipod_sorted_album_tracks(tracks)
}
