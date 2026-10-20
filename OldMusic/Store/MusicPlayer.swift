import SwiftUI
import MediaPlayer

/// Wraps the system music player (the same one the iPod app drove on iOS 6)
/// and publishes its state, so every screen updates reactively.
///
/// Compared with the OldOS iPod app:
///  - playback is never gated on an Apple Music subscription;
///  - playback notifications are actually turned on;
///  - a whole list is queued, starting at the tapped song;
///  - everything happens on the main thread.
final class MusicPlayer: ObservableObject {
    static let shared = MusicPlayer()

    let system = MPMusicPlayerController.systemMusicPlayer

    @Published private(set) var nowPlayingItem: MPMediaItem?
    @Published private(set) var playbackState: MPMusicPlaybackState = .stopped
    @Published private(set) var shuffleOn: Bool = false
    @Published private(set) var repeatMode: MPMusicRepeatMode = .none
    /// The queue OldMusic handed to the system player (the system player does
    /// not expose its queue to other apps), kept in sync with Play Next /
    /// Add to Up Next. Used by the Up Next and Previous panels.
    @Published private(set) var queue: [MPMediaItem] = []

    private var observers: [NSObjectProtocol] = []

    private init() {
        system.beginGeneratingPlaybackNotifications()
        refresh()

        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            .MPMusicPlayerControllerNowPlayingItemDidChange,
            .MPMusicPlayerControllerPlaybackStateDidChange
        ]
        for name in names {
            observers.append(center.addObserver(forName: name, object: system, queue: .main) { [weak self] _ in
                self?.refresh()
            })
        }
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        })
    }

    deinit {
        system.endGeneratingPlaybackNotifications()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func refresh() {
        let item = system.nowPlayingItem
        if item?.persistentID != nowPlayingItem?.persistentID || (item == nil) != (nowPlayingItem == nil) {
            nowPlayingItem = item
            MusicUserData.shared.recordPlay(item)
        }
        playbackState = system.playbackState
        let shuffle = system.shuffleMode
        shuffleOn = !(shuffle == .off || shuffle == .default)
        repeatMode = system.repeatMode == .default ? MPMusicRepeatMode.none : system.repeatMode
        if !supportsSpeed && playbackRate != 1 {
            playbackRate = 1
        }
    }

    var isPlaying: Bool { playbackState == .playing }

    func isNowPlaying(_ item: MPMediaItem) -> Bool {
        nowPlayingItem?.persistentID == item.persistentID
    }

    var currentTime: TimeInterval {
        let time = system.currentPlaybackTime
        return time.isFinite ? max(0, time) : 0
    }

    var currentDuration: TimeInterval {
        nowPlayingItem?.playbackDuration ?? 0
    }

    // MARK: Actions

    /// Queues `items` in order and starts at `start` (or a random song when shuffling).
    func play(_ items: [MPMediaItem], startingAt start: MPMediaItem? = nil, shuffle: Bool = false) {
        guard !items.isEmpty else { return }
        oldOSHideKeyboard()

        let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
        if shuffle {
            system.shuffleMode = .songs
            descriptor.startItem = start ?? items.randomElement()
        } else {
            descriptor.startItem = start ?? items.first
        }
        system.setQueue(with: descriptor)
        queue = items
        system.prepareToPlay { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    print("OldMusic prepareToPlay: \(error.localizedDescription)")
                }
                self?.system.play()
                self?.refresh()
            }
        }
        if let first = descriptor.startItem {
            nowPlayingItem = first
            MusicUserData.shared.recordPlay(first)
        }
    }

    func togglePlayPause() {
        if system.playbackState == .playing {
            system.pause()
            playbackState = .paused
        } else {
            system.play()
            playbackState = .playing
        }
    }

    /// iOS 6 behaviour: restart the song after the first few seconds.
    func previous() {
        if system.currentPlaybackTime < 5 {
            system.skipToPreviousItem()
        } else {
            system.skipToBeginning()
        }
    }

    func next() {
        system.skipToNextItem()
    }

    func seek(to time: TimeInterval) {
        system.currentPlaybackTime = max(0, time)
    }

    // MARK: Up Next

    /// Inserts `items` right after the current song (starts playing if idle).
    func playNext(_ items: [MPMediaItem]) {
        guard !items.isEmpty else { return }
        guard nowPlayingItem != nil else {
            play(items)
            return
        }
        system.prepend(MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items)))
        let insertAt = min((currentQueueIndex ?? -1) + 1, queue.count)
        queue.insert(contentsOf: items, at: insertAt)
    }

    /// Adds `items` at the end of the queue (starts playing if idle).
    func addToUpNext(_ items: [MPMediaItem]) {
        guard !items.isEmpty else { return }
        guard nowPlayingItem != nil else {
            play(items)
            return
        }
        system.append(MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items)))
        queue.append(contentsOf: items)
    }

    // MARK: Genius

    /// The atom button. Apple's Genius service is gone, so — like a Genius
    /// playlist — OldMusic builds a mix of up to 25 songs of the same genre
    /// (topped up with the same artist) around the current song, and keeps
    /// playing the current song from where it is.
    @discardableResult
    func playGenius(from library: [MPMediaItem]) -> Bool {
        guard let current = nowPlayingItem ?? system.nowPlayingItem else { return false }
        var pool = library.filter {
            $0.persistentID != current.persistentID
                && current.genrePersistentID != 0
                && $0.genrePersistentID == current.genrePersistentID
        }
        if pool.count < 10 {
            let sameArtist = library.filter {
                $0.persistentID != current.persistentID
                    && $0.artistPersistentID == current.artistPersistentID
                    && !pool.contains($0)
            }
            pool.append(contentsOf: sameArtist)
        }
        guard !pool.isEmpty else { return false }

        let mix = [current] + Array(pool.shuffled().prefix(24))
        let resumeAt = currentTime
        let wasPlaying = isPlaying

        system.shuffleMode = .off
        let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: mix))
        descriptor.startItem = current
        system.setQueue(with: descriptor)
        queue = mix
        system.prepareToPlay { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.system.currentPlaybackTime = resumeAt
                if wasPlaying { self.system.play() }
                self.refresh()
            }
        }
        return true
    }

    // MARK: Speed (podcasts, audiobooks, iTunes U)

    @Published private(set) var playbackRate: Float = 1

    /// iOS 6 showed a speed button instead of repeat for spoken content.
    var supportsSpeed: Bool {
        guard let item = nowPlayingItem else { return false }
        return !item.mediaType.intersection([.podcast, .audioBook, .audioITunesU]).isEmpty
    }

    /// 1× → 2× → ½× → 1×.
    func cycleSpeed() {
        let next: Float
        switch playbackRate {
        case 1: next = 2
        case 2: next = 0.5
        default: next = 1
        }
        playbackRate = next
        system.currentPlaybackRate = next
    }

    func applyRateIfNeeded() {
        if isPlaying, system.currentPlaybackRate > 0, abs(system.currentPlaybackRate - playbackRate) > 0.01 {
            system.currentPlaybackRate = playbackRate
        }
    }

    /// Off → Repeat All → Repeat One → Off.
    // MARK: Queue panels

    /// Position of the current song in `queue`.
    var currentQueueIndex: Int? {
        guard let current = nowPlayingItem else { return nil }
        return queue.firstIndex { $0.persistentID == current.persistentID }
    }

    /// Songs after the current one (in queue order; with Shuffle on the
    /// system picks its own order, which other apps cannot read).
    var upNext: [MPMediaItem] {
        guard let index = currentQueueIndex else { return [] }
        return Array(queue.dropFirst(index + 1))
    }

    /// Songs before the current one, nearest first.
    var previouslyQueued: [MPMediaItem] {
        guard let index = currentQueueIndex else { return [] }
        return Array(queue.prefix(index).reversed())
    }

    /// Jumps to a song of the current queue (or plays it on its own).
    func jump(to item: MPMediaItem) {
        if queue.contains(where: { $0.persistentID == item.persistentID }) {
            system.nowPlayingItem = item
            system.play()
            nowPlayingItem = item
            MusicUserData.shared.recordPlay(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.refresh() }
        } else {
            play([item])
        }
    }

    func cycleRepeat() {
        switch repeatMode {
        case .none, .default:
            system.repeatMode = .all
        case .all:
            system.repeatMode = .one
        case .one:
            system.repeatMode = .none
        @unknown default:
            system.repeatMode = .none
        }
        refresh()
    }

    func toggleShuffle() {
        system.shuffleMode = shuffleOn ? .off : .songs
        refresh()
    }
}
