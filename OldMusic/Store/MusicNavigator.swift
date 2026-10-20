import SwiftUI
import MediaPlayer

/// Owns every piece of navigation state of the iPod app: the current screen
/// (library, Now Playing, Cover Flow), the selected tab and one push stack
/// per tab. Views send actions here instead of juggling string flags.
final class MusicNavigator: ObservableObject {
    enum Screen: Equatable {
        case library
        case nowPlaying
        case coverFlow
    }

    @Published private(set) var screen: Screen = .library
    @Published private(set) var tab: MusicTab = .playlists
    @Published private(set) var stacks: [MusicTab: [MusicRoute]] = [:]
    /// Direction of the current slide transition (iOS 6 push / pop).
    @Published private(set) var movingForward = true
    @Published private(set) var coverFlowOrientation: UIDeviceOrientation = .landscapeLeft

    /// Song whose iOS 6 action sheet is open (long press on a song row).
    @Published var actionSong: MPMediaItem?
    /// Album whose action sheet is open (long press on an album row).
    @Published var actionAlbum: MPMediaItemCollection?
    /// The list the long-pressed song belongs to (used by "Play").
    private(set) var actionList: [MPMediaItem] = []
    /// Content handed to the system share sheet.
    @Published var shareContent: MusicShareContent?
    /// OldSafari-style drop-down panel currently shown (Up Next, Sort, ...).
    @Published private(set) var panel: MusicPanelRequest?
    /// Songs tab order chosen from the Sort drop-down.
    @Published var songSort: MusicSongSort = .title {
        didSet { UserDefaults.standard.set(songSort.rawValue, forKey: Self.songSortKey) }
    }

    private var screenBeforeCoverFlow: Screen = .library
    private var orientationObserver: NSObjectProtocol?
    private var suppressNextTap = false

    static let pushAnimation = Animation.linear(duration: 0.28)
    /// Now Playing bottom sheet open / close.
    static let sheetAnimation = Animation.spring(response: 0.42, dampingFraction: 0.9)
    private static let lastTabKey = "OldMusic.LastTab"
    private static let songSortKey = "OldMusic.SongSort"

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.lastTabKey), let savedTab = MusicTab(rawValue: saved) {
            tab = savedTab
        }
        if let saved = UserDefaults.standard.string(forKey: Self.songSortKey), let sort = MusicSongSort(rawValue: saved) {
            songSort = sort
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.deviceOrientationChanged()
        }
    }

    deinit {
        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
        }
    }

    // MARK: Stack

    var stack: [MusicRoute] { stacks[tab] ?? [] }
    var depth: Int { stack.count }
    var currentRoute: MusicRoute? { stack.last }

    var title: String {
        currentRoute?.title ?? tab.title
    }

    var backTitle: String? {
        guard depth > 0 else { return nil }
        return depth >= 2 ? stack[depth - 2].title : tab.title
    }

    /// Pushes a screen. `delayed` reproduces OldOS' short pause that lets the
    /// tapped row highlight before the slide.
    func push(_ route: MusicRoute, delayed: Bool = true) {
        // The direction is published first and the stack changes on the next
        // run loop, so the outgoing screen already knows which way to slide.
        movingForward = true
        let tab = self.tab
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayed ? 0.2 : 0.01)) { [weak self] in
            guard let self, self.tab == tab else { return }
            withAnimation(Self.pushAnimation) {
                self.stacks[tab, default: []].append(route)
            }
        }
    }

    func pop() {
        guard depth > 0 else { return }
        oldOSHideKeyboard()
        movingForward = false
        let tab = self.tab
        DispatchQueue.main.async { [weak self] in
            guard let self, self.stacks[tab]?.isEmpty == false else { return }
            withAnimation(Self.pushAnimation) {
                _ = self.stacks[tab]?.removeLast()
            }
        }
    }

    /// Tapping a tab always shows its root list (also when it is already selected).
    func select(_ newTab: MusicTab) {
        oldOSHideKeyboard()
        stacks = [:]
        tab = newTab
        UserDefaults.standard.set(newTab.rawValue, forKey: Self.lastTabKey)
    }

    // MARK: Song actions (long press)

    /// Opens the iOS 6 action sheet for `song`; the tap that ends the long
    /// press is swallowed so the song does not also start playing.
    func presentActions(for song: MPMediaItem, in list: [MPMediaItem]) {
        oldOSHideKeyboard()
        suppressNextTap = true
        actionList = list
        withAnimation(.linear(duration: 0.25)) {
            actionSong = song
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.suppressNextTap = false
        }
    }

    // MARK: Drop-down panels

    func presentPanel(_ request: MusicPanelRequest) {
        oldOSHideKeyboard()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            panel = request
        }
    }

    func dismissPanel() {
        withAnimation(.easeOut(duration: 0.18)) {
            panel = nil
        }
    }

    func presentActions(forAlbum album: MPMediaItemCollection) {
        oldOSHideKeyboard()
        suppressNextTap = true
        withAnimation(.linear(duration: 0.25)) {
            actionAlbum = album
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.suppressNextTap = false
        }
    }

    func dismissActions() {
        withAnimation(.linear(duration: 0.2)) {
            actionSong = nil
            actionAlbum = nil
        }
    }

    /// Runs a row tap unless it is the release of a long press.
    func tap(_ action: () -> Void) {
        if suppressNextTap {
            suppressNextTap = false
            return
        }
        action()
    }

    /// Jumps to another tab with a prepared stack (search results → artist / album).
    func open(tab newTab: MusicTab, stack newStack: [MusicRoute]) {
        oldOSHideKeyboard()
        movingForward = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(Self.pushAnimation) {
                self.stacks = [newTab: newStack]
                self.tab = newTab
                UserDefaults.standard.set(newTab.rawValue, forKey: Self.lastTabKey)
            }
        }
    }

    // MARK: Screens

    func showNowPlaying() {
        oldOSHideKeyboard()
        guard screen != .nowPlaying else { return }
        movingForward = true
        DispatchQueue.main.async { [weak self] in
            withAnimation(Self.sheetAnimation) {
                self?.screen = .nowPlaying
            }
        }
    }

    func showLibrary() {
        guard screen != .library else { return }
        movingForward = false
        DispatchQueue.main.async { [weak self] in
            withAnimation(Self.sheetAnimation) {
                self?.screen = .library
            }
        }
    }

    /// iOS 6: turning the device sideways shows Cover Flow, turning it back
    /// returns to the screen that was visible before.
    private func deviceOrientationChanged() {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            coverFlowOrientation = orientation
            guard screen != .coverFlow else { return }
            oldOSHideKeyboard()
            screenBeforeCoverFlow = screen
            withAnimation(.easeInOut(duration: 0.35)) {
                screen = .coverFlow
            }
        } else if orientation.isPortrait, screen == .coverFlow {
            withAnimation(.easeInOut(duration: 0.35)) {
                screen = screenBeforeCoverFlow
            }
        }
    }
}
