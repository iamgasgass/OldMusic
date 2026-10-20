import SwiftUI
import MediaPlayer

/// Data OldMusic keeps for itself, because third-party apps cannot write to
/// the system library: favourites ("Love"), star ratings and the list of
/// recently played songs. Everything is stored by persistentID in
/// UserDefaults and survives relaunches.
final class MusicUserData: ObservableObject {
    static let shared = MusicUserData()

    private enum Key {
        static let favorites = "OldMusic.Favorites"
        static let ratings = "OldMusic.Ratings"
        static let history = "OldMusic.History"
    }

    @Published private(set) var favorites: Set<MPMediaEntityPersistentID>
    @Published private(set) var ratings: [MPMediaEntityPersistentID: Int]
    /// Most recent first.
    @Published private(set) var history: [MPMediaEntityPersistentID]

    private let historyLimit = 100

    private init() {
        let defaults = UserDefaults.standard
        let storedFavorites = defaults.array(forKey: Key.favorites) as? [String] ?? []
        favorites = Set(storedFavorites.compactMap { UInt64($0) })

        let storedRatings = defaults.dictionary(forKey: Key.ratings) as? [String: Int] ?? [:]
        var ratings: [MPMediaEntityPersistentID: Int] = [:]
        for (key, value) in storedRatings {
            if let id = UInt64(key) { ratings[id] = value }
        }
        self.ratings = ratings

        let storedHistory = defaults.array(forKey: Key.history) as? [String] ?? []
        history = storedHistory.compactMap { UInt64($0) }
    }

    // MARK: Favourites

    func isFavorite(_ item: MPMediaItem) -> Bool {
        favorites.contains(item.persistentID)
    }

    func toggleFavorite(_ item: MPMediaItem) {
        if favorites.contains(item.persistentID) {
            favorites.remove(item.persistentID)
        } else {
            favorites.insert(item.persistentID)
        }
        UserDefaults.standard.set(favorites.map { String($0) }, forKey: Key.favorites)
    }

    // MARK: Ratings

    /// OldMusic's own rating, falling back to the library rating.
    func rating(for item: MPMediaItem?) -> Int {
        guard let item else { return 0 }
        return ratings[item.persistentID] ?? item.rating
    }

    func setRating(_ value: Int, for item: MPMediaItem) {
        ratings[item.persistentID] = min(max(value, 0), 5)
        var stored: [String: Int] = [:]
        for (key, rating) in ratings { stored[String(key)] = rating }
        UserDefaults.standard.set(stored, forKey: Key.ratings)
    }

    // MARK: History

    func recordPlay(_ item: MPMediaItem?) {
        guard let id = item?.persistentID, id != 0 else { return }
        if history.first == id { return }
        history.removeAll { $0 == id }
        history.insert(id, at: 0)
        if history.count > historyLimit {
            history.removeLast(history.count - historyLimit)
        }
        UserDefaults.standard.set(history.map { String($0) }, forKey: Key.history)
    }

    func clearHistory() {
        history = []
        UserDefaults.standard.set([String](), forKey: Key.history)
    }

    // MARK: Smart playlists built from this data

    func favoriteSongs(in songs: [MPMediaItem]) -> [MPMediaItem] {
        songs.filter { favorites.contains($0.persistentID) }
    }

    /// iOS 6 "My Top Rated": four stars and more, best first.
    func topRatedSongs(in songs: [MPMediaItem]) -> [MPMediaItem] {
        songs
            .filter { rating(for: $0) >= 4 }
            .sorted { rating(for: $0) > rating(for: $1) }
    }

    func historySongs(in songs: [MPMediaItem]) -> [MPMediaItem] {
        var byID: [MPMediaEntityPersistentID: MPMediaItem] = [:]
        for song in songs { byID[song.persistentID] = song }
        return history.compactMap { byID[$0] }
    }
}
