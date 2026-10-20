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
        }
        playbackState = system.playbackState
        let shuffle = system.shuffleMode
        shuffleOn = !(shuffle == .off || shuffle == .default)
        repeatMode = system.repeatMode == .default ? MPMusicRepeatMode.none : system.repeatMode
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
        oldMusicResignKeyboard()

        let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
        if shuffle {
            system.shuffleMode = .songs
            descriptor.startItem = start ?? items.randomElement()
        } else {
            descriptor.startItem = start ?? items.first
        }
        system.setQueue(with: descriptor)
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

    /// Off → Repeat All → Repeat One → Off.
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
